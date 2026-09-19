// DumpApiConsoleProbe.cs -- does `AutoHotkey64.exe /dump-api` print anything when
// run interactively in a real console (no redirection)?
//
// The hypothesis under test: AutoHotkey.exe is a Windows-GUI-subsystem binary, so
// run from a console without redirection it never inherits that console.
// GetStdHandle(STD_OUTPUT_HANDLE) then yields NULL, DumpBuiltinApi() returns
// early, and the dump is silently discarded while the process still exits 0 --
// which is why a pipe or a `> file` redirect works (those give the child a real
// handle) and typing the command does not.
//
// A pipe cannot test this: piping gives the child a real stdout handle, which
// makes the output visible and hides the bug.  So we own a console, launch under
// it without redirection, and read the screen buffer back.
//
// Cases:
//   0  harness self-check   -- sentinels prove the console read-back works
//   1  the subject          -- exe /dump-api, exactly as a user types it
//   2  control              -- exe /dump-api through cmd.exe
//   3  positive control     -- exe /AI <bad script>: the SAME exe under the SAME
//      console, but routed through the /AI path which calls AttachConsole.
//      If 3 prints and 1 does not, the console is usable and the only difference
//      is that /dump-api never attaches to it.
using System;
using System.Text;
using System.Runtime.InteropServices;

class DumpApiConsoleProbe
{
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CreateProcess(string app, string cmdline, IntPtr pa, IntPtr ta,
        bool inherit, uint flags, IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll", SetLastError = true)] static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr h, out uint code);
    [DllImport("kernel32.dll")] static extern bool FreeConsole();
    [DllImport("kernel32.dll")] static extern bool AllocConsole();
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool ReadConsoleOutputCharacterW(
        IntPtr h, [Out] char[] buf, uint len, COORD pos, out uint read);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool WriteConsoleOutputCharacterW(
        IntPtr h, string s, uint len, COORD pos, out uint written);
    [DllImport("kernel32.dll")] static extern bool GetConsoleScreenBufferInfo(IntPtr h, out CONSOLE_SCREEN_BUFFER_INFO i);
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr sec,
        uint disp, uint flags, IntPtr templ);
    [DllImport("kernel32.dll")] static extern bool SetConsoleOutputCP(uint cp);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetHandleInformation(
        IntPtr h, uint mask, uint flags);

    const uint GENERIC_READ = 0x80000000, GENERIC_WRITE = 0x40000000;
    const uint FILE_SHARE_READ = 1, FILE_SHARE_WRITE = 2;
    const uint OPEN_EXISTING = 3;
    const uint STARTF_USESTDHANDLES = 0x00000100;
    const uint HANDLE_FLAG_INHERIT_MASK = 1;

    [StructLayout(LayoutKind.Sequential)] struct COORD { public short X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct SMALL_RECT { public short L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] struct CONSOLE_SCREEN_BUFFER_INFO
    { public COORD size, cursor; public short attrs; public SMALL_RECT window; public COORD max; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO
    { public int cb; public string lpReserved, lpDesktop, lpTitle; public int dwX, dwY, dwXSize, dwYSize,
        dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags; public short wShowWindow, cbReserved2;
      public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError; }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess, hThread; public int pid, tid; }

    static IntPtr conOut;

    static string ReadConsole()
    {
        CONSOLE_SCREEN_BUFFER_INFO info;
        if (!GetConsoleScreenBufferInfo(conOut, out info)) return "<GetConsoleScreenBufferInfo failed>";
        int width = info.size.X;
        var sb = new StringBuilder();
        for (int y = 0; y < info.size.Y; y++)
        {
            var buf = new char[width];
            uint got;
            if (ReadConsoleOutputCharacterW(conOut, buf, (uint)width, new COORD { X = 0, Y = (short)y }, out got) && got > 0)
                sb.Append(new string(buf, 0, (int)got).TrimEnd()).Append('\n');
        }
        return sb.ToString();
    }

    // A blank screen buffer still reads back as lines of spaces, so measure by
    // non-whitespace content rather than line count.
    static int NonBlankChars(string s)
    {
        int n = 0;
        foreach (char c in s) if (!char.IsWhiteSpace(c)) n++;
        return n;
    }

    // The screen buffer is persistent and accumulates, so each case starts clean;
    // otherwise one case's output would be read back as another's.
    static void ClearScreen()
    {
        CONSOLE_SCREEN_BUFFER_INFO info;
        if (!GetConsoleScreenBufferInfo(conOut, out info)) return;
        for (int y = 0; y < info.size.Y; y++)
        {
            var blank = new string(' ', info.size.X);
            uint written;
            WriteConsoleOutputCharacterW(conOut, blank, (uint)info.size.X,
                new COORD { X = 0, Y = (short)y }, out written);
        }
    }

    // Write the read-back sentinel through the console DEVICE at an explicitly
    // chosen cell, avoiding three traps at once:
    //   - Console.WriteLine is bound to the inherited pipe when the caller
    //     captures our output (build.ps1 and CI both do), so it would never reach
    //     the console we allocated.
    //   - WriteConsoleW writes at the current cursor, which we do not control.
    //   - A child process also starts at cursor (0,0), so writing there would be
    //     overwritten by the very output we are trying to corroborate.
    // The last buffer row is empty and out of everyone else's way.
    static void WriteSentinel(string s)
    {
        CONSOLE_SCREEN_BUFFER_INFO info;
        short row = GetConsoleScreenBufferInfo(conOut, out info) ? (short)(info.size.Y - 1) : (short)0;
        uint written;
        WriteConsoleOutputCharacterW(conOut, s, (uint)s.Length, new COORD { X = 0, Y = row }, out written);
    }

    // Launch a console application with a console handle handed to it EXPLICITLY.
    //
    // The subject cases must NOT do this -- they need the natural "started from a
    // console with no redirection" condition, which is the whole point.  But the
    // self-check needs a child whose output is guaranteed to reach this console,
    // and inheriting our own standard handles cannot provide that: if the caller
    // captured our stdout, AllocConsole does not replace the already-valid
    // redirected handle, so an inheriting console app would print into that pipe
    // and the check would fail for a reason unrelated to the code under test.
    static int RunWithConsoleOutput(string exe, string args, out string console)
    {
        var si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        si.dwFlags = (int)STARTF_USESTDHANDLES;
        si.hStdInput = GetStdHandle(-10);
        si.hStdOutput = conOut;
        si.hStdError = conOut;
        PROCESS_INFORMATION pi;
        string cmd = "\"" + exe + "\" " + args;
        if (!CreateProcess(exe, cmd, IntPtr.Zero, IntPtr.Zero, true, 0,
                IntPtr.Zero, null, ref si, out pi))
        {
            console = "<CreateProcess failed: " + Marshal.GetLastWin32Error() + ">";
            return -1;
        }
        WaitForSingleObject(pi.hProcess, 20000);
        uint code; GetExitCodeProcess(pi.hProcess, out code);
        CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
        console = ReadConsole();
        return (int)code;
    }

    static int Run(string exe, string args, out string console)
    {
        var si = new STARTUPINFO(); si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        PROCESS_INFORMATION pi;
        string cmd = "\"" + exe + "\" " + args;
        if (!CreateProcess(exe, cmd, IntPtr.Zero, IntPtr.Zero, true, 0,
                IntPtr.Zero, null, ref si, out pi))
        {
            console = "<CreateProcess failed: " + Marshal.GetLastWin32Error() + ">";
            return -1;
        }
        WaitForSingleObject(pi.hProcess, 20000);
        uint code; GetExitCodeProcess(pi.hProcess, out code);
        CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
        console = ReadConsole();
        return (int)code;
    }

    static string FirstLine(string s)
    {
        foreach (var l in s.Split('\n'))
            if (l.Trim().Length > 0) return l.Trim();
        return "<nothing>";
    }

    static bool SeesTable(string s) { return s.Contains("built-in functions") || s.Contains("StrLen"); }

    static void Case(StringBuilder report, string title, string exe, string args,
                     out string console, out int rc)
    {
        ClearScreen();
        rc = Run(exe, args, out console);
        report.AppendLine(title);
        report.AppendLine("        exit=" + rc + "  non-blank console chars=" + NonBlankChars(console));
        report.AppendLine("        first non-blank line: " + FirstLine(console));
        report.AppendLine("        sees the dump table : " + SeesTable(console));
        report.AppendLine();
    }

    static int Main(string[] args)
    {
        string exe = args[0];
        string badScript = args.Length > 2 ? args[2] : null;

        // Open the console device directly and never rely on GetStdHandle: if the
        // caller redirected our stdout, AllocConsole points STD_OUTPUT at the new
        // buffer and the sentinel would appear there for the wrong reason.
        FreeConsole();
        AllocConsole();
        SetConsoleOutputCP(65001);
        conOut = CreateFileW("CONOUT$", GENERIC_READ | GENERIC_WRITE,
            FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
        if (conOut == new IntPtr(-1)) conOut = GetStdHandle(-11);
        // The self-check hands this handle to a child, so it must be inheritable.
        SetHandleInformation(conOut, HANDLE_FLAG_INHERIT_MASK, 1);

        var report = new StringBuilder();
        string cmdExe = Environment.GetEnvironmentVariable("COMSPEC") ?? @"C:\Windows\System32\cmd.exe";
        string c;

        // ---- case 0: validate the read-back machinery itself -----------------
        // Two INDEPENDENT legs, because one alone can pass for the wrong reason:
        //   A) our own write is read back -- validates the write/read API pair.
        //   B) a separate process's output lands in the same buffer and is read
        //      back -- validates that we are really looking at the shared console.
        // Leg B needs an explicit handle (see RunWithConsoleOutput).
        ClearScreen();
        WriteSentinel("SENTINEL-ALPHA");
        int rc0 = RunWithConsoleOutput(cmdExe, "/c echo SENTINEL-BETA", out c);
        bool readbackOk = c.Contains("SENTINEL-ALPHA") && c.Contains("SENTINEL-BETA");
        report.AppendLine("CASE 0  harness self-check (our sentinel + a child's output)");
        report.AppendLine("        exit=" + rc0);
        report.AppendLine("        sees SENTINEL-ALPHA (ours, written + read back) : " + c.Contains("SENTINEL-ALPHA"));
        report.AppendLine("        sees SENTINEL-BETA  (child process, explicit handle) : " + c.Contains("SENTINEL-BETA"));
        report.AppendLine("        read-back reliable         : " + readbackOk);
        report.AppendLine();

        // ---- case 1: the subject -------------------------------------------
        string c1; int rc1;
        Case(report, "CASE 1  subject:  AutoHotkey64.exe /dump-api", exe, "/dump-api", out c1, out rc1);

        // ---- case 2: through cmd.exe ---------------------------------------
        string c2; int rc2;
        Case(report, "CASE 2  control:  cmd /c \"AutoHotkey64.exe\" /dump-api", cmdExe,
             "/c \"\"" + exe + "\" /dump-api\"", out c2, out rc2);

        // ---- case 3: positive control, /AI on a bad script -------------------
        string c3 = ""; int rc3 = -1;
        if (badScript != null)
            Case(report, "CASE 3  positive control:  AutoHotkey64.exe /AI <bad script>", exe,
                 "/AI \"" + badScript + "\"", out c3, out rc3);

        bool sees1 = SeesTable(c1), sees2 = SeesTable(c2);
        bool aiVisible = c3.Contains("assigned a value") || c3.Contains("Missing");

        report.AppendLine("VERDICT");
        report.AppendLine("  read-back reliable        : " + readbackOk);
        report.AppendLine("  case 1 prints the table   : " + sees1);
        report.AppendLine("  case 2 prints the table   : " + sees2);
        if (badScript != null)
            report.AppendLine("  case 3 /AI reaches console: " + aiVisible);

        int verdict;
        if (!readbackOk)
        {
            report.AppendLine("  => VOID: the console reader itself is unreliable; ignore cases 1-3.");
            verdict = 2;
        }
        else if (!sees1 && !sees2 && badScript != null && aiVisible)
        {
            report.AppendLine("  => CONFIRMED: /dump-api output is lost on an interactive console,");
            report.AppendLine("     while /AI output from the SAME exe on the SAME console is visible.");
            report.AppendLine("     The console and the exe's ability to print to it are fine -- the");
            report.AppendLine("     difference is that /AI calls AttachConsole and /dump-api does not,");
            report.AppendLine("     so GetStdHandle(STD_OUTPUT_HANDLE) is NULL and the dump is dropped.");
            verdict = 1;
        }
        else if (sees1)
        {
            report.AppendLine("  => NOT reproduced: the direct run printed the table.");
            verdict = 0;
        }
        else
        {
            report.AppendLine("  => INCONCLUSIVE: see the per-case numbers above.");
            verdict = 2;
        }

        // Cap the raw console text: a blank buffer reads back as ~thousands of
        // spaces, which would drown the report.
        report.AppendLine();
        report.AppendLine("RAW (case 1, first 400 chars): " + Truncate(c1, 400));

        if (args.Length > 1)
            System.IO.File.WriteAllText(args[1], report.ToString(), new UTF8Encoding(false));

        return verdict;
    }

    static string Truncate(string s, int n)
    {
        s = s.Replace("\r", "");
        var lines = new System.Collections.Generic.List<string>();
        foreach (var l in s.Split('\n'))
            if (l.Trim().Length > 0) lines.Add(l.TrimEnd());
        string joined = string.Join(" | ", lines.ToArray());
        return joined.Length <= n ? joined : joined.Substring(0, n) + "...";
    }
}
