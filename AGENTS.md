# ahk-patch

给 AutoHotkey v2 打补丁的仓库（**不上游 fork，只维护补丁序列**）。产物**只有两个文件**：
`AutoHotkey64.exe` + `AutoHotkey32.exe`。不装任何东西、不写注册表、不生成内建函数文档。
补丁集只做两件事，**不新增任何内建函数**，其余尽可能贴近原版：

1. **`/AI`（`/NonInteractive`）** —— 把加载期/运行期的报错从 GUI 弹窗改为写 stderr，
   让无人值守的调用者不会卡在对话框上。
2. **`OutputDebug()` 同时输出到调试器 + 命令行**（镜像到 stderr）。
   **这是唯一不受开关控制的行为改动**，所以它必须作为「已审差异」写进 parity 测试里。

## 一次看懂

- `upstream/`（AutoHotkey 子模块，pin `d8f819c` = v2.1-alpha.32，见 `UPSTREAM_PIN`）
- `patches/` 8 个补丁（编号有跳跃，是从旧的 8 补丁序列里摘出、又按落点扩回来的）：
  `0002-AutoHotkey.cpp` / `0004-error.cpp` / `0007-script.cpp` / `0008-script.h` /
  `0009-script2.cpp` / `0010-Debugger.cpp` / `0011-hook.cpp` / `0012-hotkey.cpp`
- `tools/apply-patches.ps1` 应用补丁（`-CheckOnly` 在临时 pristine 副本上验证）
- `docs/ARTIFACT_CONTENTS.txt` 是**唯一的 payload 清单**，`build.ps1` 与 CI 都拿它比对，
  多余文件即失败
- `dist/AutoHotkey64.exe`、`dist/AutoHotkey32.exe` 是成品

## 常用命令

```powershell
pwsh -NoProfile -File tools/apply-patches.ps1
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform x64   -OutDir dist
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform Win32 -OutDir dist
# 五个测试都接受 -Exe a,b（一次跑两个架构）
pwsh -NoProfile -File tools/test-noninteractive.ps1     -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-no-dialog.ps1          -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-outputdebug.ps1        -Exe dist/AutoHotkey64.exe,dist/AutoHotkey32.exe
pwsh -NoProfile -File tools/test-dialog-guards.ps1 -PristineSource pristine-test   # 静态源码断言
# behaviour-parity vs stock + OutputDebug 的负对照：先从同一个 pin 造一个 pristine 二进制
#   注意 -o 是相对子模块解析的，所以写 ../：
#   git -C upstream archive --format=zip -o ../pristine.zip HEAD
#   Expand-Archive pristine.zip pristine-test
#   tools/build.ps1 -UpstreamDir pristine-test -OutDir pristine-dist
pwsh -NoProfile -File tools/test-parity.ps1 -Patched dist/AutoHotkey64.exe `
     -Pristine pristine-dist/AutoHotkey64.exe -PristineSource pristine-test
pwsh -NoProfile -File tools/test-outputdebug.ps1 -Pristine pristine-dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/pack-release.ps1          # 两个架构都构建完之后
```

## 关键约定

- 补丁与脚本一律 **LF**（`.gitattributes` 强制；CRLF 会让 `git apply` 在上下文行上失败）。
- **`tools/*.ps1` 必须能在 Windows PowerShell 5.1 下跑**（脚本头部就写着 `#requires -Version 5.1`，
  而一台装好 Agent 的机器常常只有 `powershell` 没有 `pwsh`）。两个 5.1 陷阱：
  **① `[CmdletBinding()]` 脚本的 `param()` 默认值里取不到脚本目录**——`$PSScriptRoot` 此时为空、
  `$MyInvocation.MyCommand.Path` 为 null，`Split-Path` 当场报错，脚本一行都没执行（body 里两者都正常）。
  所以 repo-root 一律声明成 `= ''`，在 `)` 之后 `if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }`。
  **② 三元 `? :` 是 7.0+ 语法**，5.1 里连解析都过不了（`exit ($ok ? 0 : 1)` → `exit $(if ($ok) { 0 } else { 1 })`）。
- 子模块保持 **dirty（已打补丁）是预期状态**，不是待提交的改动。
- 上游 bump 后先跑 `-CheckOnly`；CI 的 `patch-check` 作业会挡住失效的补丁。
- **`export-patches.ps1` 必须用 `git diff --output=`**（不能重定向 stdout）：PowerShell 会
  按控制台代码页解码 git 输出，UTF-8 BOM 会被写成 GBK 乱码，补丁看着正常但字节已坏。
  脚本里有 U+FFFD 探测，导出空文件也算失败。
- **产物只有两个 exe**：新增/删除发布文件要同步 `docs/ARTIFACT_CONTENTS.txt`，
  CI 的 payload 断言与 `pack-release.ps1` 的逐架构断言都依赖它。
- **绝不能用「执行二进制」来判定它是哪个构建**：stock 不认识新开关 → 把开关当脚本路径
  → 找不到文件 → **弹模态框**（`MsgBox` 是窗口，重定向压不住），无人值守会卡死。
  身份校验一律**静态扫描** `/NonInteractive` 宽字符字面量（`AhkAi.psm1` 的
  `Test-AhkPatchedBuild`）。注意它返回对象，取布尔要写 `.Patched`。
- **GUI 子系统 ⇒ 不能靠查句柄决定要不要 `AttachConsole`**：实测 GUI 子进程拿到的
  stderr 句柄非空、非 `INVALID_HANDLE_VALUE`、`GetFileType` 也有答案，但写进去的东西
  全丢；它和「正确重定向到文件」的句柄**完全无法区分**（都报 `FILE_TYPE_DISK`、
  `GetConsoleMode` 都失败）。所以 `/AI` 与 OutputDebug 镜像都是**无条件试一次
  `AttachConsole(ATTACH_PARENT_PROCESS)`**：重定向时它成功但不改句柄，只有那个不可用的
  继承句柄才会被换成控制台句柄。
- **管道/重定向会掩盖上述问题**，所以有独立的「真实控制台」测试：`ConsoleProbe.cs`
  自持一个控制台、按调用方给的 argv 启动子进程、再把屏幕缓冲读回来。argv 不由探针硬编码，
  因此「不带 `/AI`」这条路径也能被测（OutputDebug 的镜像就靠这条测出来）。
- **`/AI` 压的是「解释器自己的诊断」，不是脚本要的窗口**：`MsgBox()` / `InputBox()` /
  `Gui` 这类脚本主动创建的窗口**照旧弹**（改了它们就不是补丁而是另一门语言）。
  边界内的每一处都要受控：加载期/运行期错误、脚本找不到、OOM、`#SingleInstance`、
  热键节流问「要不要继续」、hook 激活失败、键盘布局缺键、`Edit()` 打不开编辑器、
  DBGp 连接失败。除错误外的这类「note/warning」统一走 `Script::PrintNote`（裸 stderr 一行，
  没有文件/行号可附）。选择哪条分支的原则：**没有人在场时一律走「让脚本继续跑」那一支**，
  并把文本打到 stderr；直接 `ExitApp` 会把一条可恢复的警告变成无人解释的死亡，
  而调用者本来就能自己杀进程。
- **上面那批站点大多无法在本机复现**（要缺键的布局、占着 hook 的游戏、拒绝连接的调试器），
  所以它们由 `tools/test-dialog-guards.ps1` 做**静态**断言：扫源码里每一处
  `MsgBox(` / `MessageBox(` / `DialogBoxParam(`，要求 `mNonInteractive` 出现在其上方
  （语句级守卫或所在函数开头的提前返回），例外必须写进那张带理由的清单（清单里
  失配的条目会被点名，防止腐烂）。同一份扫描跑在 `pristine-test/` 上**必须**报出
  未受控站点——27 处里 27 处未受控，这就是它不是假测试的证据。上游 bump 后新增的
  弹框点会在这里变红，而不是等到某台机器刚好复现出来。
- **测试探针必须用 job object（`KILL_ON_JOB_CLOSE`）认领子进程**：`DesktopProbe` 自己
  `TerminateProcess` 只覆盖「正常退出」那条路；自动化跑到超时被从外面杀掉时一行清理代码
  都不会执行，子进程就永远停在私有桌面的模态对话框里，**把 `dist\*.exe` 锁住**（实测踩过：
  三个孤儿挂了 20 分钟，`build.ps1` 拷不进新 exe）。`test-no-dialog.ps1` 里那条
  `no-orphan` 用例就是在探针运行中把它杀掉，再断言子进程不在了。
- **`/AI` 契约有两半，两半都要有测试**：「诊断进 stderr」由 `test-noninteractive.ps1` 管，
  「不再弹任何窗口」由 `test-no-dialog.ps1` 管。只断言字节**看不见窗口**，而"既打印又弹框"的
  回归在字节测试下全绿、对无人值守却是致命的。看窗口的办法是 `DesktopProbe.cs`：用
  `STARTUPINFO.lpDesktop` 把子进程放到**当前 window station 的私有桌面**，对话框渲染在那里
  （用户看不见、也点不到），探针进程 `SetThreadDesktop` 后枚举窗口并报告 class/title/控件文本。
- **需要「第二个实例」的站点必须让探针会跑双子进程**：`#SingleInstance Prompt` 的判据是
  `FindWindow(WINDOW_CLASS_MAIN, ...)`，单个进程永远碰不上，而 `/AI` 自己**不建主窗口**，
  所以先起的那个实例**不能**带开关（否则第二个实例根本没有可提示的冲突，用例会靠空桌面假通过）。
  `DesktopProbe.exe <capture> <exe> <argv> --then <exe> <argv>` 就是这个模式：先等第一个实例
  **真的拥有窗口**（就绪计数不能带可见性过滤，AHK 的主窗口是隐藏的），再只看被观察 pid 的窗口，
  并把它的 stderr 单独落到 `<capture>.stderr`。用例同时断言 `prior_ready`/`captured`，
  于是“没 setup 成功”不可能被读成“没弹框”。
- **`WaitForSingleObject` 返回 `WAIT_TIMEOUT`(258)，不是 `STILL_ACTIVE`(259)**（后者是退出码）。
  两者混用会让轮询循环变成死代码——桌面探针移植时踩过一次，结果是 6 个 `/AI` 用例
  **全部空断言假通过**；抓出它的是「无开关的同一脚本必须看到对话框」这条正向对照。
  所以判据以 capture 文件里的 `DIALOGS:` / `NO DIALOG SEEN` 为准（退出码会与 `ExitApp 3` 撞车）。
- **从 Git Bash / MSYS 传 `/AI` 会被路径转换吃掉**（`/AI` → `C:\Program Files\Git\AI`），
  于是开关**静默丢失**、退回弹框行为（实测特征：`exit 2` + stderr 空 + 标题为 `AI` 的错误框，
  内容 "Script file not found."）。跑 `/AI` 一律用 PowerShell/`cmd`，或在 bash 侧加
  `MSYS_NO_PATHCONV=1`。同类坑：`csc` 的 `/nologo` 也会被吞（改 `-nologo`）。
- **数组参数两种 shell 语义不同**：`-File x.ps1 -Exe a,b` 收到的是**一个**字符串（拆数组是
  `-Command` 的行为），而 `-Exe a -Exe b` 对 `[string[]]` 直接报错。故**五个测试全部**自己按
  `[,;]` 归一化，文档一律写 `-Exe a,b`；只接受单个 exe 的两个（`test-noninteractive` /
  `test-console-visibility`）在收到多个时用 `& $PSCommandPath` 逐架构重跑自己并汇总退出码。
  漏了这一步的症状不是报错而是「找不到 `dist\AutoHotkey64.exe,dist\AutoHotkey32.exe` 这个路径」。
- **命令行规则（上游语义，勿猜）**：开关必须写在脚本路径**之前**；遇到第一个非开关参数
  即停止解析，它=脚本路径，其后全部进 `A_Args`。`AutoHotkey.exe script.ahk /AI` 不会启用
  `/AI`。`Invoke-AhkAi` / `Invoke-AhkInConsole` 会拒绝既无 `/AI` 也无 `/ErrorStdOut` 的
  调用，因为那种调用一旦出错就会弹窗；确实要冒这个险就显式传 `-AllowDialogRisk`
  （只用于自身必然 `ExitApp 0` 的脚本）。
- **凡未被 `mNonInteractive` 包住的补丁改动都是行为回归嫌疑**，必须逐个审；
  「与原版一致」由 `tools/test-parity.ps1`（pristine A/B）守卫。
  两个硬约束：**① 任何一边 timeout 都要判 FAIL（不得当相等）；② 不得让 stock 跑
  带错脚本而不给开关，也不得拿 stock 跑新开关——都会弹模态框**。
  ②的例外只有一个、且必须显式声明：`test-no-dialog.ps1 -Pristine` 拿 stock 跑 `/AI`
  就是为了**要求它弹框**（证明探针看得见窗口），这唯一安全的实现方式是私有桌面
  （`DesktopProbe.cs`），因为它既不动用户的屏幕，也不会把对话框留在无人值守的路径上。
  在用户可见的桌面上，这条禁令无例外。
- **新测试必须能对旧行为 FAIL**：每个断言都要配一个 pristine 负对照（或先把实现改回
  旧写法确认测试会红）。`test-outputdebug.ps1` 缺 `-Pristine` 时会 `Write-Warning`，
  而不是静默通过。

## 细节记忆

- `.pi/memory/facts.md` —— 补丁落点、镜像机制、工具分工
- `.pi/memory/lessons.md` —— 踩坑
- `.pi/memory/decisions.md` —— 决策
