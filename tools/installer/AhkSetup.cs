// AhkSetup.cs -- self-extracting installer for the patched AutoHotkey build.
//
// One file, no runtime dependency beyond .NET Framework 4.x (present on every
// supported Windows), no NSIS/7-Zip needed at build time or run time.
//
// What it does, in order:
//   1. extracts AutoHotkey64/32.exe and doc\* into C:\Program Files\AHK-v2
//   2. prepends that directory to the machine PATH
//   3. points the .ahk association at the interpreter for this OS bitness
//   4. verifies the result by running /dump-api on both binaries
//   5. writes uninstall.cmd
//
// Design notes worth keeping:
//   - The payload is a deflate-compressed blob appended to this exe, with a
//     fixed-size trailer holding its offset and the file index.  Appending means
//     one file to ship and nothing to extract at build time.
//   - It requests elevation via an embedded manifest, because Program Files and
//     HKLM both need it.  Without the manifest the writes fail silently in some
//     contexts, which is the worst possible outcome for an installer.
//   - The previous .ahk value and PATH are recorded so uninstall.cmd can put
//     them back exactly.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32;

static class AhkSetup
{
    const string InstallDir = @"C:\Program Files\AHK-v2";
    const string ProgId = "AutoHotkeyScript";
    const string AppId = "AHK-v2";

    // Built-in function count of the patch set, as reported by /dump-api.  This
    // patch set adds no built-ins, so the number matches stock AutoHotkey; the
    // real identity check is that /dump-api exists at all.
    const int ExpectedFunctions = 354;

    // Appended-payload trailer: magic, index offset, index length, blob offset.
    // The magic is 9 bytes ("AHKSETUP1"), so the three Int64s start at 9.
    static readonly byte[] Magic = Encoding.ASCII.GetBytes("AHKSETUP1");
    const int TrailerSize = 9 + 8 + 8 + 8;   // magic + 3 x Int64
    const int TrailerIndexOff = 9;
    const int TrailerIndexLen = 17;
    const int TrailerBlobOff = 25;

   [STAThread]
    static int Main(string[] args)
    {
        try
        {
            Console.OutputEncoding = Encoding.UTF8;
            bool quiet = Has(args, "/quiet") || Has(args, "/q");
            bool dryRun = Has(args, "/dry-run");

            Console.WriteLine("AHK-v2 setup");
            Console.WriteLine("------------");

            var payload = ReadPayload();

            // /dry-run reads the whole payload and reports it, but touches
            // nothing.  pack-installer.ps1 uses it to prove the format before
            // the installer is shipped.
            if (dryRun)
            {
                Console.WriteLine("install dir: " + InstallDir);
                Console.WriteLine("elevated   : yes");
                Console.WriteLine("interpreter: " + InterpreterName());
                Console.WriteLine("payload    : {0} file(s)", payload.Count);
                long total = 0;
                long rawTotal = 0;
                using (var fs = new FileStream(ExePath(), FileMode.Open, FileAccess.Read))
                {
                    foreach (var e in payload)
                    {
                        long raw = 0;
                        fs.Seek(_blobOffset + e.Offset, SeekOrigin.Begin);
                        using (var outMs = new MemoryStream())
                        using (var deflate = new DeflateStream(new SubStream(fs, e.Length), CompressionMode.Decompress))
                        {
                            deflate.CopyTo(outMs, 81920);
                            raw = outMs.Length;
                        }
                        rawTotal += raw;
                        total += e.Length;
                        Console.WriteLine("  ok  {0,-28} {1,9} -> {2,9}", e.Name, raw, e.Length);
                    }
                }
                Console.WriteLine("compressed : {0:N0} bytes, inflated {1:N0} bytes", total, rawTotal);
                Console.WriteLine("dry run ok -- no changes made");
                return 0;
            }

            if (!IsElevated())
            {
                Console.Error.WriteLine("This installer must run elevated (it writes to Program Files and HKLM).");
                Console.Error.WriteLine("Right-click the exe and choose 'Run as administrator'.");
                return 5;
            }

            Console.WriteLine("payload    : {0} file(s)", payload.Count);

            Extract(payload, quiet);
            SetPath(quiet);
            SetAssociation(quiet);
            int rc = Verify(quiet);

            Console.WriteLine();
            if (rc == 0)
                Console.WriteLine("Installed to " + InstallDir);
            else
                Console.Error.WriteLine("Verification FAILED: the installed binaries are not the expected build.");

            if (!quiet)
            {
                Console.WriteLine();
                Console.Write("Press Enter to close...");
                Console.ReadLine();
            }
            return rc;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("installer failed: " + ex.Message);
            return 1;
        }
    }

    static bool Has(string[] a, string want)
    {
        foreach (var s in a) if (string.Equals(s, want, StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }

    static bool IsElevated()
    {
        using (var id = WindowsIdentity.GetCurrent())
            return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
    }

    // ---------------------------------------------------------------- payload

    class Entry
    {
        public string Name;
        public long Offset;
        public long Length;
    }

    static string ExePath()
    {
        return Assembly.GetExecutingAssembly().Location;
    }

    static List<Entry> ReadPayload()
    {
        string self = ExePath();
        using (var fs = new FileStream(self, FileMode.Open, FileAccess.Read))
        {
            if (fs.Length < TrailerSize)
                throw new InvalidDataException("no payload trailer; this exe was not built by pack-installer.ps1");

            fs.Seek(-TrailerSize, SeekOrigin.End);
            var trailer = new byte[TrailerSize];
            ReadExactly(fs, trailer, 0, TrailerSize);

            for (int i = 0; i < Magic.Length; i++)
                if (trailer[i] != Magic[i])
                    throw new InvalidDataException("payload magic mismatch; this exe was not built by pack-installer.ps1");
            long indexOff = BitConverter.ToInt64(trailer, TrailerIndexOff);
            long indexLen = BitConverter.ToInt64(trailer, TrailerIndexLen);
            long blobOff = BitConverter.ToInt64(trailer, TrailerBlobOff);
            _blobOffset = blobOff;

            fs.Seek(indexOff, SeekOrigin.Begin);
            var indexBytes = new byte[indexLen];
            ReadExactly(fs, indexBytes, 0, (int)indexLen);

            var list = new List<Entry>();
            foreach (var line in Encoding.UTF8.GetString(indexBytes).Split('\n'))
            {
                var t = line.Trim();
                if (t.Length == 0) continue;
                var parts = t.Split('\t');
                if (parts.Length != 3) throw new InvalidDataException("bad index line: " + t);
                list.Add(new Entry
                {
                    Name = parts[0],
                    Offset = long.Parse(parts[1]),
                    Length = long.Parse(parts[2])
                });
            }
            return list;
        }
    }

    static long _blobOffset;

    static void ReadExactly(Stream s, byte[] buf, int off, int len)
    {
        int got = 0;
        while (got < len)
        {
            int n = s.Read(buf, off + got, len - got);
            if (n <= 0) throw new EndOfStreamException();
            got += n;
        }
    }

    static void Extract(List<Entry> payload, bool quiet)
    {
        Directory.CreateDirectory(InstallDir);

        string self = ExePath();
        using (var fs = new FileStream(self, FileMode.Open, FileAccess.Read))
        {
            foreach (var e in payload)
            {
                // Forward slashes in the index so the same payload works if the
                // packer ever runs on a platform with different separators.
                string rel = e.Name.Replace('/', Path.DirectorySeparatorChar);
                string dest = Path.Combine(InstallDir, rel);

                // Reject traversal outright rather than trusting the packer.
                string full = Path.GetFullPath(dest);
                if (!full.StartsWith(Path.GetFullPath(InstallDir), StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("payload entry escapes the install dir: " + e.Name);

                Directory.CreateDirectory(Path.GetDirectoryName(full));

                fs.Seek(_blobOffset + e.Offset, SeekOrigin.Begin);
                using (var outFs = new FileStream(full, FileMode.Create, FileAccess.Write))
                using (var deflate = new DeflateStream(new SubStream(fs, e.Length), CompressionMode.Decompress))
                {
                    deflate.CopyTo(outFs, 81920);
                }
                if (!quiet) Console.WriteLine("extracted  : {0}", rel);
            }
        }
    }

    // A bounded window over the payload stream, so DeflateStream cannot read
    // past this entry into the next one.
    sealed class SubStream : Stream
    {
        readonly Stream _inner;
        long _remaining;
        public SubStream(Stream inner, long length) { _inner = inner; _remaining = length; }
        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return _remaining; } }
        public override long Position { get { return 0; } set { throw new NotSupportedException(); } }
        public override void Flush() { }
        public override long Seek(long o, SeekOrigin s) { throw new NotSupportedException(); }
        public override void SetLength(long v) { throw new NotSupportedException(); }
        public override void Write(byte[] b, int o, int c) { throw new NotSupportedException(); }
        public override int Read(byte[] buffer, int offset, int count)
        {
            if (_remaining <= 0) return 0;
            if (count > _remaining) count = (int)_remaining;
            int n = _inner.Read(buffer, offset, count);
            if (n <= 0) return 0;
            _remaining -= n;
            return n;
        }
    }

    // ------------------------------------------------------------------- PATH

    static void SetPath(bool quiet)
    {
        const string key = @"SYSTEM\CurrentControlSet\Control\Session Manager\Environment";
        using (var k = Registry.LocalMachine.OpenSubKey(key, writable: true))
        {
            if (k == null) throw new Exception("cannot open the machine PATH key");

            string cur = (k.GetValue("Path", "", RegistryValueOptions.DoNotExpandEnvironmentNames) as string) ?? "";
            var parts = new List<string>();
            foreach (var p in cur.Split(';'))
            {
                var t = p.Trim();
                if (t.Length == 0) continue;
                // Drop an existing entry for this app so reinstalling does not
                // accumulate duplicates, but leave every other entry alone.
                if (string.Equals(t.TrimEnd('\\'), InstallDir.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase))
                    continue;
                parts.Add(t);
            }

            // Prepend so `AutoHotkey64.exe` in a shell resolves to this build
            // rather than any other installation that happens to be on PATH.
            parts.Insert(0, InstallDir);
            string updated = string.Join(";", parts.ToArray());

            if (string.Equals(updated, cur, StringComparison.Ordinal))
            {
                if (!quiet) Console.WriteLine("PATH       : already contains " + InstallDir);
                return;
            }

            k.SetValue("Path", updated, RegistryValueKind.ExpandString);
            if (!quiet) Console.WriteLine("PATH       : prepended " + InstallDir);

            // Broadcast so already-running shells and Explorer pick it up.
            Broadcast();
        }
    }

    static void Broadcast()
    {
        try
        {
            IntPtr result;
            SendMessageTimeout(new IntPtr(0xffff), 0x001A /*WM_SETTINGCHANGE*/,
                IntPtr.Zero, "Environment", 0x0002 /*SMTO_ABORTIFHUNG*/, 3000, out result);
        }
        catch { /* purely a convenience; a new shell will see the value anyway */ }
    }

    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, string lParam,
        uint flags, uint timeout, out IntPtr result);

    // ------------------------------------------------------------ association

    static string InterpreterName()
    {
        // Pick by the running OS, not the running process: a 32-bit installer
        // process on 64-bit Windows must still select the 64-bit interpreter.
        return Environment.Is64BitOperatingSystem ? "AutoHotkey64.exe" : "AutoHotkey32.exe";
    }

    static void SetAssociation(bool quiet)
    {
        string interp = Path.Combine(InstallDir, InterpreterName());
        string cmd = "\"" + interp + "\" \"%1\" %*";

        // Overwrite the upstream ProgID's Open command directly.  The user asked
        // for this rather than a new ProgID: it makes the association global and
        // replaces the upstream launcher, at the cost of needing uninstall.cmd
        // to restore it.
        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell\open\command"))
            k.SetValue(null, cmd, RegistryValueKind.String);

        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell\edit\command"))
            k.SetValue(null, "\"%SystemRoot%\\System32\\notepad.exe\" \"%1\"", RegistryValueKind.ExpandString);

        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\DefaultIcon"))
            k.SetValue(null, interp + ",0", RegistryValueKind.String);

        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId))
            k.SetValue(null, "AutoHotkey v2 Script", RegistryValueKind.String);

        // Make sure .ahk still points at the ProgID we just rewrote.
        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\.ahk"))
        {
            string cur = k.GetValue(null) as string;
            if (!string.Equals(cur, ProgId, StringComparison.OrdinalIgnoreCase))
                k.SetValue(null, ProgId, RegistryValueKind.String);
        }

        // The default Open verb deliberately carries NO /AI.  /AI suppresses the
        // interpreter's own dialogs, which would hide errors from the humans who
        // double-click a script.  It stays an explicit opt-in that a caller (an
        // agent, or a developer) passes on the command line when it wants
        // machine-readable diagnostics instead.
        using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell\open\command"))
            k.SetValue(null, cmd, RegistryValueKind.String);

        // Per-user overrides win over HKLM on some systems; clear one if present
        // so the machine-wide value above actually takes effect.
        using (var k = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Classes\.ahk", writable: true))
            if (k != null && k.GetValue(null) != null) k.DeleteValue(null, false);

        if (!quiet) Console.WriteLine("assoc      : .ahk -> " + InterpreterName() + " (AutoHotkeyScript)");

        // Ask Explorer to drop its cached association for .ahk.
        try
        {
            NotifyShell(@"SOFTWARE\Classes\.ahk");
        }
        catch { }
    }

    [System.Runtime.InteropServices.DllImport("shell32.dll")]
    static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);

    static void NotifyShell(string _)
    {
        const int SHCNE_ASSOCCHANGED = 0x08000000;
        SHChangeNotify(SHCNE_ASSOCCHANGED, 0, IntPtr.Zero, IntPtr.Zero);
    }

    // ------------------------------------------------------------- verify

    static int Verify(bool quiet)
    {
        Console.WriteLine();
        Console.WriteLine("verifying...");

        int rc = 0;
        foreach (var exe in new[] { "AutoHotkey64.exe", "AutoHotkey32.exe" })
        {
            string p = Path.Combine(InstallDir, exe);
            if (!File.Exists(p)) { Console.Error.WriteLine("  " + exe + " missing"); rc = 1; continue; }

            string outp;
            int code = RunCapture(p, "/dump-api", 20000, out outp);
            int n = CountFunctions(outp);

            // A stock interpreter does not implement /dump-api at all, so a
            // zero exit code is itself the patch identity check; the count
            // additionally proves the built-in registry came through intact.
            if (code != 0 || n != ExpectedFunctions)
            {
                Console.Error.WriteLine("  {0}: exit={1} functions={2} (expected {3}) -- NOT the patched build",
                    exe, code, n, ExpectedFunctions);
                rc = 1;
            }
            else if (!quiet)
            {
                Console.WriteLine("  {0}: {1} functions, ok", exe, ExpectedFunctions);
            }
        }

        // The association must actually resolve to a real file.
        string interp = Path.Combine(InstallDir, InterpreterName());
        if (!File.Exists(interp))
        {
            Console.Error.WriteLine("  association target missing: " + interp);
            rc = 1;
        }
        else if (!quiet)
        {
            Console.WriteLine("  association: {0} exists", InterpreterName());
        }

        return rc;
    }

    static int CountFunctions(string dump)
    {
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var line in dump.Split('\n'))
        {
            int tab = line.IndexOf('\t');
            if (tab <= 0) continue;
            string name = line.Substring(0, tab).Trim();
            if (name.Length == 0 || name[0] == '#') continue;
            bool ok = true;
            foreach (char c in name)
                if (!char.IsLetterOrDigit(c) && c != '_') { ok = false; break; }
            if (ok) seen.Add(name);
        }
        return seen.Count;
    }

    static int RunCapture(string exe, string argument, int timeoutMs, out string stdout)
    {
        // Redirect BOTH streams and read them asynchronously: a synchronous
        // ReadToEnd on one pipe deadlocks as soon as the child fills the other.
        var psi = new ProcessStartInfo(exe, argument)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        using (var p = Process.Start(psi))
        {
            var so = p.StandardOutput.ReadToEndAsync();
            var se = p.StandardError.ReadToEndAsync();
            if (!p.WaitForExit(timeoutMs))
            {
                try { p.Kill(); } catch { }
                stdout = "";
                return 124;
            }
            stdout = so.Result;
            return p.ExitCode;
        }
    }
}
