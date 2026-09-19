// ConsoleProbe.cs -- run AutoHotkey.exe /AI under a REAL console and capture the
// console contents.  Needed because every shell-based approach either has no
// console (PowerShell pipes) or re-parses the argument list (conhost/cmd), and
// the whole question is whether a GUI-subsystem process's stderr reaches a
// console that lacks redirection.
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
        string exe = args[0], script = args[1];

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
        string cmd = "\"" + exe + "\" /AI \"" + script + "\"";
        if (!CreateProcess(exe, cmd, IntPtr.Zero, IntPtr.Zero, true, 0,
                IntPtr.Zero, null, ref si, out pi))
        {
            Console.Error.WriteLine("CreateProcess failed: " + Marshal.GetLastWin32Error());
            return 99;
        }
        WaitForSingleObject(pi.hProcess, 15000);
        uint code; GetExitCodeProcess(pi.hProcess, out code);
        // 259 == STILL_ACTIVE: /AI did not suppress the error dialog, so the
        // process is blocked on a modal window.  Kill it rather than leaving a
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
        // Save to the path given as arg 3 so the caller does not depend on stdout.
        if (args.Length > 2) System.IO.File.WriteAllText(args[2], sb.ToString(), new UTF8Encoding(false));
        return (int)code;
    }
}
