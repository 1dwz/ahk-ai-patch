// ahk-patch test probe: watch an interpreter run for MODAL DIALOGS without ever
// putting one on the user's screen.
//
// Usage: DesktopProbe.exe <capture-file> <exe> <argv...>
//        DesktopProbe.exe <capture-file> <exe> <argv...> --then <exe> <argv...>
//
// The child is started on a private desktop of the current window station
// (STARTUPINFO.lpDesktop), so any error box AutoHotkey raises is rendered where
// nobody can see it.  This program then enumerates that desktop's windows,
// records the class/title/controls of every window belonging to the child, and
// kills the child.  Enumerating a desktop the calling thread is not attached to
// returns nothing, so SetThreadDesktop is called first; the work runs on a
// thread that creates no windows of its own, which is what makes that call legal.
//
// --then starts a SECOND child on the same desktop, once the first one owns a
// window.  Some dialogs need two processes: #SingleInstance only prompts when
// FindWindow() finds a prior instance, and window enumeration -- like
// FindWindow -- is scoped to one desktop, so both instances have to be launched
// by the same watcher.  In that mode the watched child is the second one (the
// dialog watch is scoped to its pid), and its stdout/stderr are captured to
// <capture-file>.stderr so a caller can also assert what it printed.  Both
// children share one stream file: which stream a message used is asserted by
// tools/test-outputdebug.ps1 and test-noninteractive.ps1, not here.
//
// The child is also claimed by a job object with KILL_ON_JOB_CLOSE, so it cannot
// outlive this probe even when the probe is killed outright and none of the
// cleanup below runs.  That is not hypothetical: an interrupted run used to leave
// AutoHotkey.exe parked in an invisible modal dialog, holding its exe locked.
//
// Exit code: 3 when a dialog was seen (the child was killed), otherwise the
// child's own exit code.  The observation goes to <capture-file> as UTF-8, and
// either "NO DIALOG SEEN" or "DIALOGS:" -- a caller must check for the sentinel
// case before believing a negative, which tools/test-no-dialog.ps1 does by
// asserting that an unswitched run DOES produce a dialog.
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

class DesktopProbe
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO
    {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX; public int dwY; public int dwXSize; public int dwYSize;
        public int dwXCountChars; public int dwYCountChars; public int dwFillAttribute; public int dwFlags;
        public short wShowWindow; public short cbReserved2;
        public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }

    delegate bool EnumProc(IntPtr h, IntPtr l);

    // All three desktop functions live in user32.dll; kernel32 exports none of
    // them, and a wrong DllImport fails at the call, not at compile time.
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateDesktopW(string name, IntPtr original, IntPtr inherit, int flags, int access, IntPtr sa);
    [DllImport("user32.dll", SetLastError = true)] static extern bool CloseDesktop(IntPtr h);
    [DllImport("user32.dll", SetLastError = true)] static extern bool SetThreadDesktop(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowTextW(IntPtr h, StringBuilder s, int max);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassNameW(IntPtr h, StringBuilder s, int max);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool CreateProcessW(string app, string cmd, IntPtr pa, IntPtr ta, bool inherit,
        int creation, IntPtr env, string dir, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll", SetLastError = true)] static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetExitCodeProcess(IntPtr h, out uint code);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateProcess(IntPtr h, uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);

    [StructLayout(LayoutKind.Sequential)]
    struct SECURITY_ATTRIBUTES
    {
        public int nLength; public IntPtr lpSecurityDescriptor; public bool bInheritHandle;
    }

    // Only the second child of --then needs its streams captured, and a handle the
    // child may inherit has to be created inheritable on purpose.
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateFileW(string name, int access, int share, ref SECURITY_ATTRIBUTES sa,
        int disposition, int flags, IntPtr template);

    // A job object with KILL_ON_JOB_CLOSE, so the watched child cannot outlive this
    // process.  TerminateProcess below only runs when the probe exits in an orderly
    // way; when an automated run hits its timeout and kills the probe outright, no
    // cleanup code executes at all, and the child -- parked in a modal dialog on a
    // desktop nobody can see -- then survives forever and keeps the interpreter exe
    // it was launched from locked.  The kernel reaps the job's processes when the
    // last handle closes, including on an abnormal exit.
    [StructLayout(LayoutKind.Sequential)]
    struct IO_COUNTERS
    {
        public ulong ReadBytes; public ulong WriteBytes; public ulong OtherBytes;
        public ulong ReadOperations; public ulong WriteOperations; public ulong OtherOperations;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct JOBOBJECT_BASIC_LIMIT_INFORMATION
    {
        public long PerProcessUserTimeLimit; public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize; public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit; public UIntPtr Affinity;
        public uint PriorityClass; public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
    {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit; public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed; public UIntPtr PeakJobMemoryUsed;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr CreateJobObjectW(IntPtr sa, string name);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetInformationJobObject(IntPtr job, int infoClass, ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION info, int size);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

    const int DESKTOP_ALL_ACCESS = 0x1FF;
    const uint STILL_ACTIVE = 259;   // an exit code, never a WaitForSingleObject result
    const uint WAIT_TIMEOUT = 258;   // what the wait actually returns while the child runs
    const int POLL_INTERVAL_MS = 25;
    const int MAX_POLLS = 320;       // ~8 s of watching before giving up
    const int READY_POLLS = 160;     // ~4 s for the first --then child to own a window
    const int JobObjectExtendedLimitInformation = 9;
    const uint JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000;
    const int STARTF_USESTDHANDLES = 0x0100;
    const int GENERIC_WRITE = 0x40000000;
    const int FILE_SHARE_READ_WRITE = 3;
    const int CREATE_ALWAYS = 2;

    // Present on every desktop a process first touches, unrelated to the script.
    static bool IsNoise(string className)
    {
        return className == "UAC_InputIndicatorOverlayWnd" || className == "UAC Input Indicator";
    }

    static uint targetPid;
    static List<string> found = new List<string>();
    static int windowCount;

    // Readiness check for the --then mode: AHK's main window is created hidden, so
    // "the prior instance is up" cannot be judged by visibility -- the dialog watch
    // below does filter on it, this one must not.
    static bool CountTop(IntPtr h, IntPtr l)
    {
        uint pid; GetWindowThreadProcessId(h, out pid);
        if (pid == targetPid && !IsNoise(Class(h))) windowCount++;
        return true;
    }

    static string Text(IntPtr h)
    {
        var sb = new StringBuilder(4096);
        GetWindowTextW(h, sb, sb.Capacity);
        return sb.ToString();
    }

    static string Class(IntPtr h)
    {
        var sb = new StringBuilder(256);
        GetClassNameW(h, sb, sb.Capacity);
        return sb.ToString();
    }

    static bool CollectChild(IntPtr h, IntPtr l)
    {
        string t = Text(h);
        if (t.Length > 0) found.Add("    control[" + Class(h) + "] " + t);
        return true;
    }

    static bool CollectTop(IntPtr h, IntPtr l)
    {
        uint pid; GetWindowThreadProcessId(h, out pid);
        if (pid != targetPid) return true;
        string cls = Class(h);
        if (IsNoise(cls)) return true;
        if (!IsWindowVisible(h)) return true;
        found.Add("  window class=" + cls + " title='" + Text(h) + "'");
        EnumChildWindows(h, CollectChild, IntPtr.Zero);
        return true;
    }

    static void Write(string capture, string body, int code)
    {
        try { File.WriteAllText(capture, body, new UTF8Encoding(false)); } catch { }
        Environment.Exit(code);
    }

    static string cap;   // so a helper can fail through the same capture path

    static void Bail(string body, int code) { Write(cap, body, code); }

    static PROCESS_INFORMATION StartChild(string[] a, int from, int to, IntPtr job, IntPtr stream, out bool claimed)
    {
        var si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        si.lpDesktop = "winsta0\\ahk-probe-desktop";
        if (stream != IntPtr.Zero)
        {
            si.dwFlags = STARTF_USESTDHANDLES;
            si.hStdInput = stream;   // never read; a valid handle keeps the trio consistent
            si.hStdOutput = stream;
            si.hStdError = stream;
        }

        var cl = new StringBuilder();
        cl.Append('"').Append(a[from]).Append('"');
        for (int i = from + 1; i < to; i++) cl.Append(" \"").Append(a[i]).Append('"'); // paths may contain spaces

        PROCESS_INFORMATION pi;
        if (!CreateProcessW(null, cl.ToString(), IntPtr.Zero, IntPtr.Zero, stream != IntPtr.Zero,
                0, IntPtr.Zero, null, ref si, out pi))
            Bail("CreateProcess failed, win32 error " + Marshal.GetLastWin32Error() + "\ncmdline: " + cl + "\n", 96);

        claimed = job != IntPtr.Zero && AssignProcessToJobObject(job, pi.hProcess);
        return pi;
    }

    static bool Alive(IntPtr h)
    {
        uint c;
        return GetExitCodeProcess(h, out c) && c == STILL_ACTIVE;
    }

    static void Run()
    {
        string[] a = Environment.GetCommandLineArgs();
        if (a.Length < 3)
            Write(a.Length > 1 ? a[1] : "", "usage: DesktopProbe.exe <capture-file> <exe> <argv...> [--then <exe> <argv...>]\n", 98);
        cap = a[1];

        int split = -1;
        for (int i = 3; i < a.Length; i++) if (a[i] == "--then") { split = i; break; }
        if (split == 3 || split >= a.Length - 1)
            Bail("usage error: --then needs '<exe> <argv...>' on both sides\n", 98);
        bool hasPrior = split > 0;

        IntPtr desk = CreateDesktopW("ahk-probe-desktop", IntPtr.Zero, IntPtr.Zero, 0, DESKTOP_ALL_ACCESS, IntPtr.Zero);
        if (desk == IntPtr.Zero)
            Bail("CreateDesktop failed, win32 error " + Marshal.GetLastWin32Error() + "\n", 97);

        // One job for every child, created up front, so no child can exist outside it.
        IntPtr job = CreateJobObjectW(IntPtr.Zero, null);
        bool jobLimits = false;
        if (job != IntPtr.Zero)
        {
            JOBOBJECT_EXTENDED_LIMIT_INFORMATION lim = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
            lim.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
            jobLimits = SetInformationJobObject(job, JobObjectExtendedLimitInformation, ref lim, Marshal.SizeOf(lim));
        }

        bool priorClaimed = true, watchClaimed;
        PROCESS_INFORMATION prior = new PROCESS_INFORMATION();
        bool priorReady = false;
        if (hasPrior)
        {
            prior = StartChild(a, 2, split, job, IntPtr.Zero, out priorClaimed);
            // Wait until the prior instance owns a window.  #SingleInstance only
            // prompts when FindWindow() can see a prior main window, and that window
            // is created hidden -- so this counts windows without the visibility
            // filter the dialog watch below uses.  Skipping the wait would let a test
            // watch a second instance that never had any reason to prompt, which
            // passes for the wrong reason.
            SetThreadDesktop(desk);
            targetPid = (uint)prior.dwProcessId;
            for (int rp = 0; ; ++rp)
            {
                windowCount = 0;
                EnumWindows(CountTop, IntPtr.Zero);
                if (windowCount > 0 || rp >= READY_POLLS || !Alive(prior.hProcess)) break;
                WaitForSingleObject(prior.hProcess, POLL_INTERVAL_MS);
            }
            priorReady = windowCount > 0;
        }

        // In the two-child mode the watched child's streams go to a file, so a caller
        // can assert what /AI printed as well as what it did not print in a window.
        string stderrPath = cap + ".stderr";
        bool captured = false;
        IntPtr stream = IntPtr.Zero;
        if (hasPrior)
        {
            SECURITY_ATTRIBUTES sa = new SECURITY_ATTRIBUTES();
            sa.nLength = Marshal.SizeOf(sa);
            sa.bInheritHandle = true;
            IntPtr h = CreateFileW(stderrPath, GENERIC_WRITE, FILE_SHARE_READ_WRITE, ref sa, CREATE_ALWAYS, 0, IntPtr.Zero);
            if (h != new IntPtr(-1)) { stream = h; captured = true; }
        }

        PROCESS_INFORMATION pi = hasPrior
            ? StartChild(a, split + 1, a.Length, job, stream, out watchClaimed)
            : StartChild(a, 2, a.Length, job, IntPtr.Zero, out watchClaimed);
        bool jobGuarded = jobLimits && priorClaimed && watchClaimed;
        targetPid = (uint)pi.dwProcessId;

        // WaitForSingleObject answers WAIT_TIMEOUT while the child runs; STILL_ACTIVE
        // (259) is an EXIT CODE, not a wait result, and comparing the two makes the
        // loop body dead code -- which is how every negative case here once passed
        // without ever looking at a desktop.
        uint state = WaitForSingleObject(pi.hProcess, POLL_INTERVAL_MS);
        int polls = 0;
        while (state == WAIT_TIMEOUT && polls < MAX_POLLS)
        {
            SetThreadDesktop(desk);
            found.Clear();
            EnumWindows(CollectTop, IntPtr.Zero);
            if (found.Count > 0) break;
            state = WaitForSingleObject(pi.hProcess, POLL_INTERVAL_MS);
            polls++;
        }

        bool dialogSeen = found.Count > 0;
        bool stillRunning = state == WAIT_TIMEOUT;
        uint code = 0;
        GetExitCodeProcess(pi.hProcess, out code);
        if (dialogSeen || stillRunning)
        {
            // A dialog is a nested message loop: the child will never return, so
            // the observation is final the moment one appears.
            TerminateProcess(pi.hProcess, 1);
            code = stillRunning && !dialogSeen ? 0 : code;
        }
        if (hasPrior && Alive(prior.hProcess)) TerminateProcess(prior.hProcess, 0);
        if (stream != IntPtr.Zero) CloseHandle(stream);  // before a caller reads the file
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        if (hasPrior) { CloseHandle(prior.hThread); CloseHandle(prior.hProcess); }
        CloseHandle(job);   // reaps anything left, including on an abnormal exit above
        CloseDesktop(desk);

        var o = new StringBuilder();
        o.Append("pid=").Append(targetPid).Append(" polls=").Append(polls)
         .Append(" exit=").Append(code).Append(" killed=").Append(dialogSeen || stillRunning)
         .Append(" job=").Append(jobGuarded);
        if (hasPrior)
            o.Append(" prior=").Append(prior.dwProcessId).Append(" prior_ready=").Append(priorReady)
             .Append(" captured=").Append(captured);
        o.Append('\n');
        if (dialogSeen)
        {
            o.Append("DIALOGS:\n");
            foreach (string s in found) o.Append(s).Append('\n');
        }
        else o.Append("NO DIALOG SEEN\n");

        // The exit code is a convenience only: a script may legitimately ExitApp with
        // any number, so the capture text above is what a caller must read.
        Write(cap, o.ToString(), dialogSeen ? 3 : (int)code);
    }

    static int Main(string[] args)
    {
        // A dedicated thread because SetThreadDesktop refuses to run on a thread
        // that already owns windows, and the CLR main thread may.
        var t = new Thread(new ThreadStart(Run));
        t.Start();
        t.Join();
        return 0;
    }
}
