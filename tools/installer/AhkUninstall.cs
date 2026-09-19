// AhkUninstall.cs -- removes everything the AHK-v2 installer added.
//
// Why a compiled exe rather than a .cmd:  the installer restores an HKLM value
// and rewrites the machine PATH, and a .cmd doing that via `reg`/`powershell`
// is fragile (quoting, locale-dependent output, and it cannot report a
// half-finished rollback).  This does the same work with the registry API and
// returns a meaningful exit code.
//
// The .ahk association is restored to the upstream launcher rather than
// deleted: removing it outright would leave .ahk files with no "open" verb at
// all, which is worse than the state before installation.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32;

static class AhkUninstall
{
    const string InstallDir = @"C:\Program Files\AHK-v2";
    const string ProgId = "AutoHotkeyScript";

    // Where the stock installer puts its launcher.  Only used to rebuild the
    // Open command; if it is absent we fall back to a plain interpreter path.
    const string UpstreamUx = @"C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe";
    const string UpstreamLauncher = @"C:\Program Files\AutoHotkey\UX\launcher.ahk";
    const string UpstreamV2 = @"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe";

    [STAThread]
    static int Main(string[] args)
    {
        bool quiet = false;
        foreach (var a in args)
            if (string.Equals(a, "/quiet", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(a, "/q", StringComparison.OrdinalIgnoreCase)) quiet = true;

        try
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.WriteLine("AHK-v2 uninstall");
            Console.WriteLine("----------------");

            if (!IsElevated())
            {
                Console.Error.WriteLine("This uninstaller must run elevated (it edits HKLM and cleans Program Files).");
                Console.Error.WriteLine("Right-click the exe and choose 'Run as administrator'.");
                return 5;
            }

            int rc = 0;
            rc |= RemoveFromPath(quiet);
            rc |= RestoreAssociation(quiet);
            rc |= RemoveFiles(quiet);

            // Do not delete InstallDir here: RemoveFiles left a detached
            // process to remove uninstall.exe and then the directory itself.
            // Report what will remain so the user is not surprised.
            try
            {
                var leftovers = Directory.GetFileSystemEntries(InstallDir);
                var unexpected = new List<string>();
                foreach (var l in leftovers)
                {
                    var n = Path.GetFileName(l);
                    if (string.Equals(n, "uninstall.exe", StringComparison.OrdinalIgnoreCase)) continue;
                    unexpected.Add(n);
                }
                if (unexpected.Count > 0)
                {
                    Console.WriteLine("kept       : {0} holds {1} item(s) we did not create:", InstallDir, unexpected.Count);
                    foreach (var l in unexpected) Console.WriteLine("             " + l);
                }
            }
            catch (DirectoryNotFoundException) { }
            catch (Exception ex) { Console.Error.WriteLine("  directory check: " + ex.Message); rc = 1; }

            Console.WriteLine();
            Console.WriteLine(rc == 0 ? "Uninstalled." : "Uninstall finished with problems.");
            Console.WriteLine("Open a new terminal for the PATH change to take effect.");

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
            Console.Error.WriteLine("uninstaller failed: " + ex.Message);
            return 1;
        }
    }

    static bool IsElevated()
    {
        using (var id = WindowsIdentity.GetCurrent())
            return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
    }

    static int RemoveFromPath(bool quiet)
    {
        const string key = @"SYSTEM\CurrentControlSet\Control\Session Manager\Environment";
        try
        {
            using (var k = Registry.LocalMachine.OpenSubKey(key, writable: true))
            {
                if (k == null) { Console.Error.WriteLine("  cannot open the machine PATH key"); return 1; }

                string cur = (k.GetValue("Path", "", RegistryValueOptions.DoNotExpandEnvironmentNames) as string) ?? "";
                var parts = new List<string>();
                foreach (var p in cur.Split(';'))
                {
                    var t = p.Trim();
                    if (t.Length == 0) continue;
                    if (string.Equals(t.TrimEnd('\\'), InstallDir.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase))
                        continue;
                    parts.Add(t);
                }
                string updated = string.Join(";", parts.ToArray());
                if (string.Equals(updated, cur, StringComparison.Ordinal))
                {
                    if (!quiet) Console.WriteLine("PATH       : already clean");
                    return 0;
                }
                k.SetValue("Path", updated, RegistryValueKind.ExpandString);
                if (!quiet) Console.WriteLine("PATH       : removed " + InstallDir);
                Broadcast();
                return 0;
            }
        }
        catch (Exception ex) { Console.Error.WriteLine("  PATH cleanup: " + ex.Message); return 1; }
    }

    static void Broadcast()
    {
        try
        {
            IntPtr result;
            SendMessageTimeout(new IntPtr(0xffff), 0x001A, IntPtr.Zero, "Environment", 0x0002, 3000, out result);
        }
        catch { }
    }

    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, string lParam,
        uint flags, uint timeout, out IntPtr result);

    static int RestoreAssociation(bool quiet)
    {
        // Rebuild the command the stock installer would have written.  Prefer
        // the UX launcher when it is still on disk, because that is what the
        // user had before; otherwise point straight at any remaining v2
        // interpreter so double-clicking an .ahk still does something sensible.
        string cmd;
        string icon;
        if (File.Exists(UpstreamUx))
        {
            cmd = "\"" + UpstreamUx + "\" \"" + UpstreamLauncher + "\" \"%1\" %*";
            icon = UpstreamUx + ",0";
        }
        else if (File.Exists(UpstreamV2))
        {
            cmd = "\"" + UpstreamV2 + "\" \"%1\" %*";
            icon = UpstreamV2 + ",0";
        }
        else
        {
            // Nothing to restore, so the association must not be left pointing
            // at a program we just deleted.  Remove what we set rather than
            // leaving a dangling command: .ahk files then fall back to asking
            // the user, which is honest, instead of failing with a confusing
            // "cannot find the file" error.
            try
            {
                using (var k = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell", writable: true))
                {
                    if (k != null)
                    {
                        try { k.DeleteSubKeyTree("open", false); } catch { }
                        try { k.DeleteSubKeyTree("edit", false); } catch { }
                    }
                }
                using (var k = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Classes\" + ProgId, writable: true))
                {
                    if (k != null) { try { k.DeleteValue("", false); } catch { } }
                }
                ShellChangeNotify();
                if (!quiet) Console.WriteLine("assoc      : removed (no upstream launcher to restore)");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("  could not clear the association: " + ex.Message);
                return 1;
            }
        }

        try
        {
            using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell\open\command"))
                k.SetValue(null, cmd, RegistryValueKind.String);

            using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell\edit\command"))
                k.SetValue(null, "\"%SystemRoot%\\System32\\notepad.exe\" \"%1\"", RegistryValueKind.ExpandString);

            using (var k = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Classes\" + ProgId + @"\DefaultIcon"))
                k.SetValue(null, icon, RegistryValueKind.String);

            // Remove the runasai verb if an earlier build of this installer
            // created it, so upgrades from that build are also left clean.
            try
            {
                using (var k = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Classes\" + ProgId + @"\shell", writable: true))
                    if (k != null) k.DeleteSubKeyTree("runasai", false);
            }
            catch { /* not fatal: the association below is what matters */ }

            ShellChangeNotify();
            if (!quiet) Console.WriteLine("assoc      : restored .ahk to " + Path.GetFileName(cmd.Split('"')[1]));
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine("  association restore: " + ex.Message); return 1; }
    }

    [System.Runtime.InteropServices.DllImport("shell32.dll")]
    static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);

    static void ShellChangeNotify() { SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); }

    static int RemoveFiles(bool quiet)
    {
        int rc = 0;

        // uninstall.exe cannot delete its own image (the OS holds it open), so
        // it is removed via a detached command that runs after this process
        // exits.  Doing it any other way always leaves the file behind.
        string self = System.Reflection.Assembly.GetExecutingAssembly().Location;

        var targets = new List<string>();
        targets.Add(Path.Combine(InstallDir, "AutoHotkey64.exe"));
        targets.Add(Path.Combine(InstallDir, "AutoHotkey32.exe"));

        foreach (var f in targets)
        {
            if (!File.Exists(f)) continue;
            try
            {
                File.Delete(f);
                if (!quiet) Console.WriteLine("deleted    : " + Path.GetFileName(f));
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("  cannot delete " + Path.GetFileName(f) + ": " + ex.Message);
                Console.Error.WriteLine("  (is a script still running under it?)");
                rc = 1;
            }
        }

        string doc = Path.Combine(InstallDir, "doc");
        if (Directory.Exists(doc))
        {
            try
            {
                Directory.Delete(doc, true);
                if (!quiet) Console.WriteLine("deleted    : doc\\");
            }
            catch (Exception ex) { Console.Error.WriteLine("  doc cleanup: " + ex.Message); rc = 1; }
        }

        // Hand the self-delete and the (possibly now empty) directory removal to
        // a short-lived detached process.  `ping` is used as a delay because it
        // does not need a console and is present on every Windows install.
        try
        {
            string script = string.Format(
                "/c ping 127.0.0.1 -n 3 >nul & del /f /q \"{0}\" & rd \"{1}\" 2>nul",
                self, InstallDir);
            var psi = new ProcessStartInfo("cmd.exe", script)
            {
                UseShellExecute = false,
                CreateNoWindow = true
            };
            Process.Start(psi);
            if (!quiet) Console.WriteLine("scheduled  : self-removal");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("  could not schedule self-removal: " + ex.Message);
            Console.Error.WriteLine("  delete " + self + " manually");
            rc = 1;
        }

        return rc;
    }
}
