# ahk-patch

给 AutoHotkey v2 打补丁的仓库（**不上游 fork，只维护补丁序列**）。当前补丁集只做两件事，
**不新增任何内建函数**，尽可能贴近原版：

1. **`/AI`（`/NonInteractive`）** —— 把加载期/运行期的报错从 GUI 弹窗改为写 stderr，
   让无人值守的调用者不会卡在对话框上。
2. **`/dump-api`** —— 打印内建函数表后退出，供文档生成器读取。

## 一次看懂

- `upstream/`（AutoHotkey 子模块，pin `d8f819c` = v2.1-alpha.32，见 `UPSTREAM_PIN`）
- `patches/` 5 个补丁（编号有跳跃，是从旧的 8 补丁序列里摘出来的）：
  `0002-AutoHotkey.cpp` / `0003-MdFunc.cpp` / `0004-error.cpp` / `0007-script.cpp` / `0008-script.h`
- `tools/apply-patches.ps1` 应用补丁（`-CheckOnly` 在临时 pristine 副本上验证）
- `dist/AutoHotkey64.exe` 是成品；`dist/AHK-v2-Setup.exe` 是自解压安装包

## 常用命令

```powershell
pwsh -NoProfile -File tools/apply-patches.ps1
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform x64   -OutDir dist
pwsh -NoProfile -File tools/build.ps1 -Configuration Release -Platform Win32 -OutDir dist
pwsh -NoProfile -File tools/test-noninteractive.ps1   -Exe dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-console-visibility.ps1 -Exe dist/AutoHotkey64.exe
pwsh -NoProfile -File tools/test-dump-api-console.ps1   -Exe dist/AutoHotkey64.exe
# behaviour-parity vs stock: build a pristine binary from the same pin first
#   git -C upstream archive --format=zip -o pristine.zip HEAD
#   Expand-Archive pristine.zip pristine-test
#   tools/build.ps1 -UpstreamDir pristine-test -OutDir pristine-dist
pwsh -NoProfile -File tools/test-parity.ps1 -Patched dist/AutoHotkey64.exe `
     -Pristine pristine-dist/AutoHotkey64.exe -PristineSource pristine-test
pwsh -NoProfile -File tools/pack-installer.ps1        # 必须在两个架构都构建完之后
pwsh -NoProfile -File tools/test-installer.ps1        # 需管理员；装→验→卸→回滚
```

## 关键约定

- 补丁与脚本一律 **LF**（`.gitattributes` 强制；CRLF 会让 `git apply` 在上下文行上失败）。
- 子模块保持 **dirty（已打补丁）是预期状态**，不是待提交的改动。
- 上游 bump 后先跑 `-CheckOnly`；CI 的 `patch-check` 作业会挡住失效的补丁。
- **构建顺序**：`x64` → `Win32` → `pack-installer.ps1`。安装包内嵌两个 exe 并**逐个跑
  `/dump-api` 自检**，早于 win32 构建就会打进过期 payload 并自检失败。
- **内建函数数是 354**（与原版一致），出现在 4 处需同步：`tools/test-installer.ps1`
  (`$ExpectedFunctions`)、`tools/installer/AhkSetup.cs` (`ExpectedFunctions`)、
  CI `verify` 作业、README。
- **两个开关都必须 `AttachConsole`**：`AutoHotkey.exe` 是 GUI 子系统程序，交互式运行时
  不继承控制台。`/AI` 走 stderr、`/dump-api` 走 stdout（`DumpBuiltinApi`，在加载脚本前
  执行，不经诊断通路），**各自**需要 `AttachConsole(ATTACH_PARENT_PROCESS)`。
  管道/重定向会掩盖此问题，所以两个开关各有独立的「真实控制台」测试。
- **凡未被 `mNonInteractive` 包住的补丁改动都是行为回归嫌疑**，必须逐个审；
  「与原版一致」由 `tools/test-parity.ps1`（pristine A/B）守卫。
  两个硬约束：**① 任何一边 timeout 都要判 FAIL（不得当相等）；② 不得让 stock 跑
  带错脚本而不给开关，也不得拿 stock 跑新开关——都会弹模态框**。

## 细节记忆

- `.pi/memory/facts.md` —— 补丁落点、`/dump-api` 输出格式、工具分工
- `.pi/memory/lessons.md` —— 踩坑
- `.pi/memory/decisions.md` —— 决策
