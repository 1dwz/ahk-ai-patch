// ConsoleProbe.cs -- run AutoHotkey.exe under a REAL console and capture the
// console contents.  Needed because every shell-based approach either has no
// console (PowerShell pipes) or re-parses the argument list (conhost/cmd), and
// the whole question is whether a GUI-subsystem process's stderr reaches a
// console that lacks redirection.
//
// Usage: ConsoleProbe.exe <interpreter> <capture-file> <interpreter-argv...>
// The argv after the capture file is handed to the interpreter verbatim, so the
// caller decides which switches are under test (or none).  Exit code is the
// child's, or 259 when it had to be killed for still running at the timeout --
// which for /AI means a modal dialog appeared.
using System;
using System.Text;
using System.Runtime.InteropServices;

class ConsoleProbe
{
    const int STD_OUTPUT_HANDLE = -11;
    const int STD_ERROR_HANDLE  = -12;

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CreateProcess(string app, string cmdline, IntPtr pa, IntPtr ta,
        bool inherit, uint flags, IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll", SetLastError = true)] static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr h, out uint code);
    [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr h, uint code);
    [DllImport("kernel32.dll")] static extern bool FreeConsole();
    [DllImport("kernel32.dll")] static extern bool AllocConsole();
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool ReadConsoleOutputCharacterW(
        IntPtr h, [Out] char[] buf, uint len, COORD pos, out uint read);
    [DllImport("kernel32.dll")] static extern bool GetConsoleScreenBufferInfo(IntPtr h, out CONSOLE_SCREEN_BUFFER_INFO i);
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateFileW(string name, uint access, uint share, IntPtr sec,
        uint disp, uint flags, IntPtr templ);
    [DllImport("kernel32.dll")] static extern bool SetConsoleOutputCP(uint cp);

    const uint GENERIC_READ = 0x80000000, GENERIC_WRITE = 0x40000000;
    const uint FILE_SHARE_READ = 1, FILE_SHARE_WRITE = 2;
    const uint OPEN_EXISTING = 3;

    [StructLayout(LayoutKind.Sequential)] struct COORD { public short X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct SMALL_RECT { public short L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] struct CONSOLE_SCREEN_BUFFER_INFO
    { public COORD size, cursor; public short attrs; public SMALL_RECT window; public COORD max; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO
    { public int cb; public string lpReserved, lpDesktop, lpTitle; public int dwX, dwY, dwXSize, dwYSize,
      dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags; public short wShowWindow, cbReserved2; public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError; }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess, hThread; public int pid, tid; }

    static int Main(string[] args)
    {
        if (args.Length < 3)
        {
            Console.Error.WriteLine("usage: ConsoleProbe.exe <interpreter> <capture-file> <interpreter-argv...>");
            return 98;
        }
        string exe = args[0], capture = args[1];

        // We are the console owner; give it to the child instead of redirecting.
        FreeConsole();
        AllocConsole();
        SetConsoleOutputCP(65001);

        // If OUR stdout/stderr were redirected (e.g. the caller did
        // `$out = & probe ...`), GetStdHandle still returns the inherited pipe
        // even after AllocConsole, so reading the console back would yield
        // nothing and the test would fail for the wrong reason.  Open the
        // console device explicitly so the read always targets the real screen
        // buffer regardless of how the caller launched us.
        IntPtr conOut = CreateFileW("CONOUT$", GENERIC_READ | GENERIC_WRITE,
            FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
        if (conOut == new IntPtr(-1))
        {
            conOut = GetStdHandle(STD_OUTPUT_HANDLE);
        }

        var si = new STARTUPINFO(); si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
        PROCESS_INFORMATION pi;
        var cl = new StringBuilder();
        cl.Append('"').Append(exe).Append('"');
        for (int i = 2; i < args.Length; i++)
            cl.Append(" \"").Append(args[i]).Append('"');   // a script path may contain spaces
        if (!CreateProcess(exe, cl.ToString(), IntPtr.Zero, IntPtr.Zero, true, 0,
                IntPtr.Zero, null, ref si, out pi))
        {
            Console.Error.WriteLine("CreateProcess failed: " + Marshal.GetLastWin32Error());
            return 99;
        }
        WaitForSingleObject(pi.hProcess, 15000);
        uint code; GetExitCodeProcess(pi.hProcess, out code);
        // 259 == STILL_ACTIVE: the interpreter is blocked on a modal window
        // (either /AI failed to suppress the error dialog, or no switch was
        // passed and the script raised one).  Kill it rather than leaving a
        // stray window behind, and report a distinct code so the caller can say
        // which failure mode happened.
        if (code == 259)
        {
            TerminateProcess(pi.hProcess, 259);
            WaitForSingleObject(pi.hProcess, 2000);
        }
        CloseHandle(pi.hProcess); CloseHandle(pi.hThread);

        // Read back the console buffer, which is where an unredirected stderr went.
        IntPtr h = conOut;
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo(h, out info);
        int width = info.size.X;
        int lines = info.cursor.Y;
        var sb = new StringBuilder();
        for (int y = 0; y <= lines && y < info.size.Y; y++)
        {
            var buf = new char[width];
            uint got;
            if (ReadConsoleOutputCharacterW(h, buf, (uint)width, new COORD { X = 0, Y = (short)y }, out got) && got > 0)
                sb.Append(new string(buf, 0, (int)got).TrimEnd()).Append('\n');
        }
        // Save to the capture path so the caller does not depend on stdout.
        System.IO.File.WriteAllText(capture, sb.ToString(), new UTF8Encoding(false));
        return (int)code;
    }
}
