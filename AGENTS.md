# Agent Pane 右键复制与 Ctrl+V 粘贴回归开发与交接

> 本文件用于调查并修复 agent pane 中“历史文本右键不再复制”与“Ctrl+V 不再粘贴”的两个
> 输入回归，并记录 test-driven development、发布验证与交接。产品行为、已提交测试和
> 可复现证据始终是最终事实来源。这两个问题共用当前 dev/publish branches，但必须分别取得
> RED/GREEN、用户行为断言和 evidence，不能以其中一个修复推断另一个也已恢复。

## 使用前必读

继续本 feature 前，先完成以下操作：

1. 当前只允许调查、文档和环境验证；在 baseline RED 被真实用户入口复现前，不修改 product/test code。
2. 持续更新 `Current Stage`、验证结果、first-bad 证据、review triage 和 evidence inventory。
3. 所有 Git 操作只使用已配置的命令行 `git` 与 `Dinah` / `origin` remote；禁止启动 GitKraken、
  `gh auth`、credential manager 登录或任何可能改变 GitHub 身份的认证流程。
4. UI 交互回归必须保留 exact baseline RED、exact publish GREEN，以及右键和 Ctrl+V 动作前后截图；
  截图必须来自实际部署的 Dev package，并记录 source/deployed binary SHA-256。
5. 本回归不依赖模型输出。focused/live regression 使用 deterministic ACP fixture；真实 agent
  不是完成该 product-owned mouse/clipboard contract 的前置条件。

### Record Status

- Publishable/publish commits、package identity、binary hashes、tests、screenshots和 review triage均已记录。
- 本 feature未创建 issue或 PR；review ID不适用。first-bad与最终 implementation均有可复现证据。

## Feature Metadata

- Feature: 恢复 agent pane 历史文本右键复制与 Ctrl+V 文本粘贴
- Summary: WTA 重新启用 mouse capture 后，拖拽选区由 WTA 自己管理；物理右键被 TerminalControl
  作为 VT mouse 发送给 WTA，但 WTA event allowlist 丢弃右键，导致 clipboard 不变。另一个
  regression 使 agent input 中的 Ctrl+V 绕过 `Terminal.PasteFromClipboard` action 并落到 WTA
  字符输入，结果插入 literal `v`；Ctrl+Shift+V 仍可正常粘贴。
- User-visible goal: 用户在 agent pane 历史记录拖拽、双击或三击选中文字后，单次右键即可把
  精确选中文本复制到 OS clipboard，并清除选区、显示与 `Ctrl+C` 相同的复制确认；agent input
  聚焦时，Ctrl+V 与 Ctrl+Shift+V 都必须把 OS clipboard 文本插入当前 draft，不输入字母 `v`、
  不提交 prompt，也不改变其他 pane 的快捷键语义。
- Base: `origin/main@e870a3630a785a44cbd22190b5c8808c7084b31f`（包含 ItE2E window-before-COM fix #629）
- Dev branch: `user/DinahK-2SO/resume-right-click-copy` -> `Dinah`
- Publish branch: `user/DinahK-2SO/resume-right-click-copy-publish` -> `origin`（本地 worktree
  `C:\ado\right-click-copy-publish`，exact publish validation、push与 remote verification已完成）
- Issue / pull request: 未创建（N/A）
- Evidence root: `test/e2e/artifacts/right-click-copy/`
- Current dev branch: 包含 publishable feature commit `e717a37d889d4eaf535a142af3d8f360755ba8cd`
  与后续 dev-only handoff records；以 `Dinah/user/DinahK-2SO/resume-right-click-copy`为 authoritative head。
- Current publishable commit: `e717a37d889d4eaf535a142af3d8f360755ba8cd`
- Current publish head: `c4b84ff28012a6a1fc9e86f08d60e08edadb1b3a`
- Out of scope: 不改变普通 terminal pane 的右键 copy/paste/context-menu 语义；不移除 WTA mouse
  capture；不重做 text selection、completed-turn click、滚轮或 clipboard 基础设施；不改变
  Alt+V image paste；不依赖模型回答；不把 agent pane 无选区右键 paste 纳入本次 contract。

## Current Stage

`2026-08-20`: Implementation and exact-publish validation complete。publishable changes 已提交为
`e717a37d889d4eaf535a142af3d8f360755ba8cd`，并 clean cherry-pick 到 publish HEAD
`c4b84ff28012a6a1fc9e86f08d60e08edadb1b3a`。exact publish HEAD 的 explicit-target WTA build、
Debug x64 full build/deploy、source/deployed hash comparison 均完成。最终 packaged E2E 在同一 deployed
package 上通过：`Feature.Paste` `5/5`，`RightClickCopy` `1/1`；release reports 均为零失败。
截图已逐图检查且全部为 1734x955、非黑非空、无 overlap/clipping。首次 publish paste run 在
`BeforeAll` setup race 中未进入 case，clean retry `5/5`；首次 right-click run 的 Ctrl+C geometry
control 只选到部分 marker，未发送右键，clean retry 在 exact-selection control 后 `1/1`。两次均未
把 setup failure 当作 product RED。dev/publish branches均已 push，并用 `git ls-remote`确认 remote heads。

`2026-08-19`: Investigation。源码历史与用户手动 binary A/B 均已确认 first-bad 为
`d4b436a809b87f4e1e247d6f385785dabee1842b`（`Implement WTA chat mouse interactions and
text selection (#506)`）：其 first parent `12c66272848e98d1f47cc1a833bb0eb487284f31`
保持 mouse capture 关闭，而该 commit 重新发送 `EnableMouseCapture`，同时 `event.rs` 仅转发
ScrollUp/ScrollDown 与 Left Down/Drag/Up，右键事件因此被丢弃。`08957118a` 只扩展 completed-turn
左键交互，不是回归起点。`d4b436a809` 是 parent 的直接子 commit，且已确认属于
`v0.2@513808751cf7d8db0fe53ff52b5d234dd0185780`；从该 commit 到 v0.2 没有右键转发或复制修复。
手动验证结果为 parent 版本右键复制正常、`d4b436a809` 版本右键复制失效。该阶段随后在 exact
baseline上把行为固化为自动化 RED，并记录 clipboard sentinel、截图和 binary identity。

同日已完成当前 dev HEAD `c612a48353aacbf93ab5009d3cc4b90a9b637180` 的本地 baseline
验收：merge 后重新生成并部署 Dev package，Cargo/intermediate/AppX/deployed `wta.exe` 均为
32,687,616 bytes，SHA-256 `116927FFDB785F1FFBE81FB28533B9D75E4580B022B6F4118EFECE09486B7A85`。
真实 `Copilot · Windows v1.0.81-2` 完成唯一 marker 对话；物理拖拽选区后右键使 clipboard
sentinel 保持不变且选区仍可见，键盘 `Ctrl+C` 能复制同一选区，点击输入框后
`Ctrl+Shift+V` 能把唯一 clipboard marker 精确粘贴到 draft。步骤 2–8 的截图和 pane captures
保存在 `test/e2e/artifacts/right-click-copy/baseline-real-copilot/`。测试结束后 Dev 进程已停止，
settings/state 备份已恢复。该阶段随后把右键与 Ctrl+V 的真实 RED分别固化为现有 suite自动化 case。

同一 baseline 还确认了 Ctrl+V paste regression：物理 Ctrl+V 在 agent input 中只插入 literal `v`，
没有读取 OS clipboard；物理 Ctrl+Shift+V 则能把唯一 marker 精确粘贴到 draft。用户已通过
regression analysis 确认该问题 first-bad 为
`08957118a8227e976e7cd1b9dda16571e7914cdc`（first parent
`5af10de78af6e43b4a507a35e98b27176a7b66c9`）。该 commit 没有直接修改 paste action 或 keybinding，
因此 first-bad 是 confirmed fact，但具体 keyboard/focus routing 原因仍须由 focused trace/test 证实，
不能把 action-link/hover 变化直接写成最终 root cause。

## Regression Analysis

回归由 mouse selection ownership 迁移不完整造成：在 `d4b436a809` 之前，WTA 不启用 mouse
capture，拖拽选区由 TerminalControl/TerminalCore 管理，因此右键可直接走 host 已有的 copy
selection 路径。该 commit 为支持 WTA chat 滚轮和自有文本选择重新启用 `EnableMouseCapture`，
此后物理右键优先被 TerminalControl 编码成 VT mouse input 发给 WTA，而 host 不再处理 copy。

WTA 同一 commit 新增的 `event.rs::map_crossterm_event` allowlist 只接受滚轮与 Left
Down/Drag/Up，没有接受 Right Down/Up；所以右键在进入 WTA 后被静默丢弃。与此同时，可见选区
已经属于 WTA `TextSelection`，TerminalCore 没有对应 selection 可供 host 复制。结果是拖拽选择和
`Ctrl+C` 正常，但右键既不会触发 host copy，也不会触发 WTA copy，OS clipboard 保持不变。

### Ctrl+V Paste Regression

正常路径应为：window action map 将 Ctrl+V 或 Ctrl+Shift+V 解析为
`Terminal.PasteFromClipboard`，`TerminalPage::_HandlePasteText` 调用 focused `TermControl` 的
paste request，`TerminalPage::_PasteFromClipboardHandler` 识别 source pane 为 agent pane 后发送
结构化 `agent_paste_text` protocol event，WTA 再异步读取 OS clipboard 并插入 owner tab draft。

当前坏路径中，Ctrl+V 没有命中上述 host action，而是进入 ConPTY/crossterm。WTA 收到带 Control
modifier 的 `KeyCode::Char('v')` 后，`app_keys.rs` 最终落入通用 `KeyCode::Char(c)` 分支并插入
literal `v`。Ctrl+Shift+V 仍命中 host paste action，证明 clipboard、structured paste protocol、
WTA clipboard read 和 draft insertion 基础设施都正常，缺口位于 Ctrl+V 的 keyboard/action routing。

`08957118a` 只改动 TerminalControl action-link/pointer handling 与 WTA completed-turn/input mouse
interaction，没有直接删除 Ctrl+V binding，也没有修改 `TerminalPage` paste handler。因此当前最小
可证伪 hypothesis 是：该 iteration 改变了 agent pane 的 interaction/focus/action routing，使
Ctrl+V 不再由 host action map 消费；具体 owner 必须用 key/action trace 或 focused regression 定位。

## Scope And Contract

### User-Visible Contract

- 在 agent pane 当前可见历史记录中，拖拽、双击或三击形成的有效 WTA text selection 都可由
  单次鼠标右键复制；复制文本必须与 `Ctrl+C` 对同一选区的结果完全一致。
- 复制成功后清除 selection，并显示既有 `system.selection_copied` transient hint；第二次右键
  不得重放 stale selection，也不得重复写入 clipboard。
- 右键 Down 只触发一次复制；Right Up 不重复复制。clipboard 写入失败时保留 selection、记录
  warning，且不得谎报成功。
- 没有有效 WTA selection 时，右键保持当前 no-op；不得粘贴、提交 prompt、切换 completed turn、
  打开 URI 或改变 input draft/focus。
- 左键 drag/double/triple selection、`Ctrl+C`、wheel scroll、completed-turn click、输入框点击、
  keyboard navigation 和 pane focus 语义保持不变。
- 普通 terminal pane 与 `RightClickContextMenu` / `CopyOnSelect` 设置继续由 TerminalControl 拥有；
  修复不得在 TerminalControl 中根据 agent 文本、进程名或 profile 猜测 pane 类型。
- agent input 拥有键盘焦点时，物理 Ctrl+V 与 Ctrl+Shift+V 必须调用同一个
  `Terminal.PasteFromClipboard` product action，并把 clipboard 文本插入当前 owner tab 的 draft。
- 单行 Ctrl+V 必须精确插入一次 marker；多行 Ctrl+V 必须保留所有行并留在同一个 draft 中，
  不得因换行提前提交 prompt、拆分 turn 或丢失行。
- Ctrl+V 不得输入 literal `v` / `V`；不得把 marker 写入历史、其他 tab、hidden/stashed pane，
  也不得在 input 不可接收导航焦点时静默填充不可见 draft。
- 从 completed-turn/history interaction 点击回 input dialog 后，Ctrl+V 必须恢复正常 paste；这条
  focus transition 必须单独覆盖，因为 first-bad iteration 同时改变了 history/input mouse lifecycle。
- Ctrl+Shift+V、Alt+V image paste、普通字符输入、Ctrl+C、其他 window accelerators 及普通
  terminal pane 的 paste 语义保持不变。

每条 contract 都必须能映射到至少一个自动化断言或人工可观察证据。不要只描述内部状态。

### Preserved Invariants

- WTA mouse capture 必须保留；它承载 chat wheel、WTA-owned text selection 和 completed-turn click。
- WTA 的 `TextSelection` 是 agent pane 可见选区的唯一 owner；TerminalCore 在该路径上没有可复制选区。
- Ctrl+V 与 Ctrl+Shift+V 必须继续复用现有 structured `agent_paste_text` path；WTA 不直接读取
  每个键盘事件的 clipboard，也不新增第二套 paste normalization/routing。
- WTA `paste_pending` / generation、owner window/tab validation、single/multiline normalization 和
  input-live gating 必须保留；Alt+V image attachment path 不受影响。
- 未涉及的输入方式、已有 workflow、设置迁移和兼容行为保持不变。
- 不扩大 feature 的 ownership boundary，不顺手修复无关问题。

### Guardrails

- 不以关闭 `EnableMouseCapture` 恢复 native selection；这会回归 #506 的 wheel、selection 和 click。
- 不在 TerminalControl 增加 agent-pane special case；host 抢回右键时看不到 WTA-owned selection。
- 复用现有 `Ctrl+C` 的 clipboard/clear/hint/error 路径，避免形成第二套复制语义。
- E2E 必须发送真实窗口右键输入，不能只向 ConPTY 注入 SGR sequence；后者会绕过
  `TermControl -> ControlInteractivity -> ConPTY` 的回归边界。
- Ctrl+V E2E 必须通过 `Send-WtWindowKey` 发送 OS-level Ctrl+V / Ctrl+Shift+V，不能使用
  `Send-AgentWin32Key`、`wtcli send-keys` 或 raw ConPTY sequence；这些路径会绕过 action map，
  无法证明 `Terminal.PasteFromClipboard` 恢复。
- 在确认 host shortcut routing owner 前，不以 WTA 特判 Ctrl+V 作为表面修复；否则 host action
  恢复后可能产生双重 paste，并绕过普通 Terminal 的 configurable keybinding semantics。
- 不通过测试专用 product path、硬编码 fixture 输出或不可达状态满足验收。
- 不以内部字段变化代替真实输出或用户流程验证。
- 只格式化 touched files，避免 repository-wide mechanical churn。

## Ownership Hypothesis

```text
用户在 agent pane 的 WTA text selection 上按鼠标右键
  -> TermControl / ControlInteractivity 识别 VT mouse mode
  -> ConPTY 发送 SGR Right Down/Up
  -> crossterm EventStream / event.rs 过滤
  -> app_events.rs 复用 WTA selection copy helper
  -> win32 clipboard + selection clear + transient hint

用户在已聚焦的 agent input 按 Ctrl+V
  -> Terminal window action map 解析 Terminal.PasteFromClipboard
  -> TerminalPage::_HandlePasteText / _PasteText
  -> focused TermControl::PasteTextFromClipboard
  -> TerminalPage::_PasteFromClipboardHandler 识别 AgentPaneContent
  -> protocol event agent_paste_text(window_id, tab_id)
  -> WTA handle_agent_paste_text / OS clipboard read
  -> AgentPasteTextReady -> owner tab current draft
```

- Owning code path: `tools/wta/src/helper/runtime.rs` -> `src/cascadia/TerminalControl/ControlInteractivity.cpp`
  -> `tools/wta/src/event.rs` -> `tools/wta/src/app_events.rs` -> `tools/wta/src/win32.rs`
- Owning abstraction: WTA `AppEvent::Mouse` dispatch 与现有 mouse-owned `TextSelection` copy lifecycle。
- Falsifiable hypothesis: 若 `event.rs` 转发 Right Down，且 `app_events.rs` 在存在 selection 时复用
  `Ctrl+C` 的 copy/clear/hint helper，则右键会恢复；若真实物理右键根本没有到达 WTA，或 WTA 在
  Down 前已失去 selection，则该方案会在 protocol/event RED check 上被证伪。
- Cheapest discriminating check: exact baseline 创建唯一 marker 选区，把 clipboard 设为唯一 sentinel，
  对选区发送真实 Right Down/Up；同时检查 WTA input trace。预期当前 WTA 收到/被 host 发送右键但
  `map_crossterm_event` 返回 `None`，clipboard 仍为 sentinel，selection 仍可由 `Ctrl+C` 成功复制。
- Nearest existing test / fixture / helper: `tools/wta/src/event.rs::mouse_events_are_forwarded`、
  `tools/wta/src/text_selection.rs::mouse_release_does_not_return_text_for_automatic_copy`、
  `test/e2e/tests/Feature.AgentMouse.Tests.ps1`、`test/e2e/tests/Feature.Paste.Tests.ps1`、
  `Send-WtWindowKey`、`test/e2e/fixtures/Mock-AcpChatAgent.ps1`。
- Ctrl+V falsifiable hypothesis: first-bad iteration 使 focused agent pane 的 Ctrl+V 未被 action map 消费，
  因而按键落入 ConPTY/WTA；若 action trace 显示 Ctrl+V 已触发 `Terminal.PasteFromClipboard`，则该
  hypothesis 被证伪，应沿 `_PasteFromClipboardHandler` 的 source-pane/target routing 向下调查。
- Ctrl+V cheapest discriminating check: 在 input focus 已确认时设置唯一 clipboard marker，先监听
  `agent_paste_text` event/log，再发送物理 Ctrl+V。baseline 预期无 structured event，draft 只新增
  literal `v`；同场景 Ctrl+Shift+V 应产生 event 并插入 marker，证明 downstream paste path 正常。

在首次 product edit 前必须能够写出上述 hypothesis 和 check。若 check 不能区分候选原因，
只补一次邻近读取或测试，然后选择最小可逆 edit；不要无限扩展调查范围。

## Commit And Worktree Discipline

- Publishable changes先在 dev branch 形成一个自包含 commit：product code、自然归属的
  unit/integration tests、确定性 fixture、已有 E2E framework 内的 regression case，
  以及应随产品发布的 checklist 或 test metadata。
- Dev-only changes单独提交：本交接、进度记录、ignored screenshots/reports/logs、
  本地 orchestration、provider 配置、实验，以及不应进入 publish 的最终验收 harness。
- Publish worktree 只直接 cherry-pick publishable commit。不要 cherry-pick mixed commit
  后再 restore 文件，也不要把 dev-only acceptance commit 带入 publish。
- 不修改或回退无关的用户改动。若无关改动不阻塞当前工作，保持原状。
- 不 force-add ignored evidence。需要提交 review evidence 时，复制最终选定文件到
  `doc/review-evidence/right-click-copy/`（仅在 PR 确实要求提交截图时创建）。
- 未经明确要求，不创建额外 branch、不重写历史、不使用 destructive git command。

## Test Reuse And Framework Boundaries

- 首先扩展上述 Rust tests、`test/e2e/fixtures/Mock-AcpChatAgent.ps1`、
  `Feature.AgentMouse.Tests.ps1` 和
  `Feature.Paste.Tests.ps1`；保留现有 paste test 名称，以免破坏 release-checklist exact-title mapping。
- 新增测试应落在 ownership 最近的现有 suite 中，并只引入使 regression 稳定所需的
  最小 helper 或 deterministic fixture。
- 当现有 framework 无法执行真实用户操作时，可在 dev-only 范围建立模块化 local
  orchestration 以取得 RED/GREEN evidence，并将通用 framework 提取作为独立 PR。
- 不在 feature commit 中夹带大型 test framework、通用 harness rewrite 或无关基础设施。
- Mock/deterministic fixture 可用于 focused RED/GREEN、几何、路由和故障隔离；若 contract
  依赖真实外部系统，它不能替代最终真实集成验收。

### Ctrl+V E2E Required Matrix

| Case | 真实 trigger | 必须断言的 product-owned oracle | Negative / positive control |
|---|---|---|---|
| Single-line Ctrl+V | 聚焦 agent input，OS clipboard 放唯一 marker，`Send-WtWindowKey -Ctrl` | owner-scoped `agent_paste_text` trigger；marker 在当前 draft 恰好一次；clipboard 不变 | 不得出现 literal `v`，不得提交 |
| Multiline Ctrl+V | clipboard 放三行唯一 marker 后发送物理 Ctrl+V | 三行都在同一个 draft，顺序和换行保留；无 completed turn | 不得只插首行、拆 turn 或自动 Enter |
| Ctrl+Shift+V control | 与 single-line 使用相同 setup，发送 `-Ctrl -Shift` | 同一 structured event 和同一 draft insertion path 成功 | 用于证明 clipboard/downstream 正常，不能替代 Ctrl+V GREEN |
| Input refocus | 先执行 history/completed-turn mouse interaction，再物理点击 input dialog，发送 Ctrl+V | selection/focus 已回到 input；marker 进入当前 draft | 不得 toggle history 或写入 hidden draft |
| Owner isolation | 至少两个 tab/pane，marker 只针对 focused owner input | event 的 window/tab identity 与 receiving helper 一致 | sibling/stashed/非 live input 不得变化 |

实施细则：

- 保留 `Feature.Paste` 现有 single-line/multiline test full names 和 checklist mapping；可把 provider setup
  改为 deterministic fixture，但不得降低真实 Dev package、OS clipboard、window accelerator、COM/
  protocol、WTA helper 和 rendered draft 边界。
- Observer 必须在按键前启动。GREEN 至少同时证明 host structured trigger 和最终 draft；只看到按键、
  clipboard 或内部 `paste_pending` 不算成功。
- RED 必须确认按键确实送达 foreground Dev HWND，再断言无 structured trigger、marker 缺失且 literal
  `v` 出现；否则 foreground/setup failure 不能冒充产品 regression。
- 每个 case 使用新 GUID marker，并把 marker 搜索限制到 input rows；历史中相同文本、自动换行和重复
  retry 不得造成 false positive。retry 前必须清空 draft，每次最终成功只允许 marker 出现一次。
- Ctrl+Shift+V 只发一次作为 positive control；不能用四次 retry 后的重复 marker 截图作为最终证据。
- 测试完成后恢复 clipboard、settings/state，停止仅由 test 启动的 Dev/WTA processes，不影响 Store、
  普通 Windows Terminal 或用户的 elevated window。

## Reproduction And RED Oracle

### Baseline Identity

- Source commit: current baseline `c612a48353aacbf93ab5009d3cc4b90a9b637180`；right-click first-bad
  `d4b436a809b87f4e1e247d6f385785dabee1842b`；Ctrl+V first-bad
  `08957118a8227e976e7cd1b9dda16571e7914cdc`
- Build command: `cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml`，
  随后 `cmd.exe /c "tools\razzle.cmd && bcz no_clean"`
- Package / deployment: Dev loose package / `build/scripts/Invoke-IntelligentTerminalDebugDeployment.ps1`
- Relevant binaries: `tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe`、package build/deployed
  `wta.exe`、`Microsoft.Terminal.Control.dll`、`WindowsTerminal.exe`
- Source/deployed hashes: current baseline Cargo/intermediate/AppX/deployed `wta.exe` 均为
  `116927FFDB785F1FFBE81FB28533B9D75E4580B022B6F4118EFECE09486B7A85`

### Reproduction

1. 从 exact baseline build 并部署，记录 commit、package path、binary size 和 SHA-256。
2. 使用 deterministic ACP fixture 建立含唯一 marker 的历史文本，并验证 marker 只出现一次。
3. 通过真实窗口拖拽 marker 形成可见 selection，把 OS clipboard 设为唯一 sentinel，再执行
  真实鼠标 Right Down/Up；保留动作前、动作后与 Ctrl+C positive-control 截图。
4. 捕获实际输出、日志、测试报告；UI 变更同时保存 RED screenshot。
5. 证明 selection 可见且 Ctrl+C positive control 能复制同一 marker，失败只发生在右键 oracle，
  而不是 setup、连接、fixture、clipboard、坐标或错误 binary。
6. 清空 draft 并确认 input caret/focus；设置另一个唯一 clipboard marker，启动 host protocol/log
  observer，再发送物理 Ctrl+V。保存按键前、literal `v` RED 和 Ctrl+Shift+V positive-control 截图。
7. 重复 Ctrl+V 对多行 clipboard 的测试，证明 baseline 没有 paste event，且没有把 clipboard
  内容插入或提交；然后用 Ctrl+Shift+V 证明同一 clipboard/downstream path 可用。

- RED oracle: 右键后 clipboard 仍等于 sentinel，而不是所选 marker；选区仍存在，随后 `Ctrl+C`
  能复制 marker，证明 clipboard 与 selection setup 正常。
- Expected failure location/message: live E2E 只失败于“right-click must copy the exact WTA selection”；
  Rust focused RED 只失败于 Right Down 被 `map_crossterm_event` 丢弃/未触发 shared copy path。
- Setup evidence: `baseline-real-copilot/01-build-deploy.txt`、pane captures和步骤截图记录 package、
  process path、marker、selection与 clipboard controls。
- RED artifact paths: manual packaged baseline 位于
  `test/e2e/artifacts/right-click-copy/baseline-real-copilot/`；自动化 RED 使用独立 `red/` iteration。
- Ctrl+V RED oracle: Ctrl+V 后 input 只新增 literal `v`，唯一 clipboard marker 未出现在 draft，且
  没有 owner-scoped `agent_paste_text` trigger；Ctrl+Shift+V 后 marker 精确出现一次。
- Ctrl+V expected failure: 现有 `Feature.Paste` single-line 与 multiline cases 必须在行为断言 RED，
  不能 skip、误匹配历史 marker 或把“按键已发送”当成 paste 成功。
- Ctrl+V baseline evidence: `baseline-real-copilot/08-keyboard-copy-paste.png` / pane capture 记录
  literal `v`；`08-ctrl-shift-v-paste.png` 记录 positive control。正式自动化 RED 使用独立 iteration
  目录，不能复用试验中包含重复 marker 的中间截图。

如果 baseline 不能在预期 oracle 上失败，停止 product edit，先报告现有行为和证据。

## Strict TDD Workflow

1. 找到最近的 existing test、fixture、helper 和 E2E suite。
2. build/deploy exact baseline，并记录 binary identity。
3. 只运行新 right-click case，确认它只失败于 clipboard 仍为 sentinel；单独运行现有
  `Feature.Paste` Ctrl+V single/multiline cases，确认只失败于 marker 未进入 draft/literal `v`。
4. 添加 ownership 最近的最小 unit/state/render regression，并分别确认 RED。Ctrl+V focused test
  应锁定 action routing/focus transition，而不是重复 WTA 已有 clipboard insertion tests。
5. 在 WTA `AppEvent::Mouse` / shared selection-copy abstraction 修右键；在 focused key/action owner
  修 Ctrl+V routing。两个 fix 可同 commit 发布，但不得耦合为一个条件分支。
6. 首次 substantive edit 后立即运行
  `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml right_click`；
  不要先扩大改动范围。
7. 若失败支持 hypothesis，修复同一 slice 并重复 focused check；若 falsify hypothesis，
   只向真正 owner 邻近移动一步。
8. focused GREEN 后运行 neighboring mouse/selection tests、完整
  `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml` 和 required build。
9. 使用 `ITE2E_PACKAGE=Dev` 运行 `Feature.AgentMouse.Tests.ps1` 的 right-click case，从真实窗口
  验证 exact selection 写入 clipboard、selection 清除、hint 显示和第二次右键不重放；运行
  `Feature.Paste.Tests.ps1` 验证 Ctrl+V single/multiline、Ctrl+Shift+V positive control、literal `v`
  suppression、input refocus 和 owner-tab routing。
10. 提交 publishable commit；将 dev-only evidence/orchestration 另作 commit。
11. clean publish worktree 直接 cherry-pick publishable commit。
12. 从 exact publish HEAD build/deploy，校验 source/deployed binary SHA-256，并重跑 E2E。
13. 本回归不依赖真实 agent；最后验收使用 deterministic ACP fixture 和真实部署 package/UI/clipboard。
14. 对 UI/渲染/交互变更捕获该轮 exact publish HEAD 的 fresh success screenshots 并逐图检查。
15. 更新本文件的 stage、validation、review triage、artifact inventory 和 open items。
16. 先 push dev 并确认同步，再 push 已验证的 publish HEAD；记录两个 remote head。

## Implementation Record

- Behavioral change: WTA event mapping 只转发 Right Down；`AppEvent::Mouse` 与 Ctrl+C 共用
  `copy_text_selection()`。成功时精确写 clipboard、清除 selection并显示既有 copied hint；失败时
  保留 selection、清除 stale hint并记录 warning。AgentPaneContent 根据 effective Ctrl+V action
  启用 TermControl native-key fallback；fallback 只消费 bare Ctrl+V keydown/up并请求既有 clipboard
  paste event，因此不再向 WTA输入 literal `v`。
- State / API changes: TermControl 新增 transient `EnableAgentPasteShortcutFallback(Boolean)` 开关；
  无持久状态或新跨进程 protocol。AgentPaneContent wrapper 创建后立即应用当前 settings。显式 unbind
  或 custom Ctrl+V action 会关闭 fallback；普通 terminal pane从不启用该开关。
- Preserved invariants: WTA mouse capture、左键 selection、Ctrl+C、wheel、completed-turn、Ctrl+Shift+V、
  Alt+V image paste 与普通 terminal keybindings 行为不变。
- Performance implications: 每次 Right Down 只增加一次现有 selection 检查；无持续 polling/redraw。
- Security / privacy implications: 仅把用户显式选择的本地文本写入 OS clipboard，与既有 Ctrl+C相同。
- Rejected alternatives and rationale: 已拒绝关闭 mouse capture 与 TerminalControl agent special case；
  前者回归 #506，后者无法读取 WTA-owned selection。已拒绝 global defaults Ctrl+V binding，因为会
  改变普通 terminal语义；已拒绝 wrapper-level routed handler，因为 prototype触发 startup access
  violation；未在 WTA generic Char分支读取 clipboard，避免绕过 configurable action map和双重 paste。

记录最终实现的事实，不保留已经失效的设计猜测。若 ownership hypothesis 被证伪，更新
Ownership Hypothesis 并说明哪个 check 改变了判断。

## Validation Matrix

| Layer | Command / Method | Expected | Result | Evidence |
|---|---|---|---|---|
| Focused RED | 新 Rust right-click mapping/copy tests | 右键被丢弃或不复制 | `2/2` expected failures confirmed before product edit | local cargo output |
| Ctrl+V focused RED | physical Ctrl+V single/multiline + Ctrl+Shift+V control | Ctrl+V无 structured event并落入 literal `v` | single/multiline RED；Ctrl+Shift+V GREEN | `baseline-real-copilot/` + RED run output |
| Focused GREEN | `cargo test ... right_click` + paste focused filters | local ownership tests pass | right-click `2/2`；PasteCore `3/3` | local cargo/Pester output |
| Neighboring tests | event/text-selection baseline filters | No regression | `7/7` + `13/13` passed | local cargo output |
| Full relevant suite | `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml` | All pass | `1545/1545` passed；0 failed | local cargo output |
| Explicit build | explicit-target WTA + Debug x64 package build | 0 errors | WTA build passed；full publish build `0 errors` / 218 existing warnings | exact publish build output |
| Packaged / deployed baseline | real Dev UI + OS clipboard workflow | right-click 与 Ctrl+V 各自在独立 oracle RED | 两个 RED confirmed；Ctrl+C/Ctrl+Shift+V controls GREEN | `baseline-real-copilot/` |
| Automated right-click E2E | `Feature.AgentMouse.Tests.ps1` against explicit Dev | copy/clear/hint/no-replay | exact publish `1/1` passed | `right-click-copy/publish/right-click-c4b84ff2-retry/` + `green/*.png` |
| Automated Ctrl+V E2E | `Feature.Paste.Tests.ps1` single/multiline/refocus/isolation | structured trigger + exact draft；无 literal `v` | exact publish `5/5` passed | `right-click-copy/publish/paste-full-c4b84ff2-retry/` + `green/*.png` |
| Static analysis | compiler/VS diagnostics, diff check, review, release report | 无新增相关告警 | VS diagnostics clean；diff check clean；release reports 0 failed automation | local output/reports |
| Real integration `[可选]` | 真实 Copilot CLI 对话仅验证 UI 操作能力 | genuine completed turn | passed with Copilot v1.0.81-2 | `baseline-real-copilot/04-real-copilot-reply.png` |

### Exact Publish Identity

- Publish commit: `c4b84ff28012a6a1fc9e86f08d60e08edadb1b3a`
- Package identity/path: `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr` / `C:\ado\right-click-copy-publish\src\cascadia\CascadiaPackage\bin\x64\Debug\AppX`
- Source/deployed `wta.exe`: 32,688,128 bytes / `42E5C1B57D6CD2CC1E97C6041093402D8755663500C2F22C90EAD467B3B2A3AC`
- Source/deployed `Microsoft.Terminal.Control.dll`: 14,501,888 bytes / `87DF2C9CD958E54A01DBEC1E2A4C33ED0DF791C6B45B2281868B609F561F04E2`
- Source/deployed `TerminalApp.dll`: 30,354,432 bytes / `E2C95FFF54C0EDB2B34A6AFB4FB171A57F63301416EEDD65E244E636A4F7E4AB`
- Source/deployed `WindowsTerminal.exe`: 6,080,512 bytes / `9A2BDDC18B668419B83B81A7D328A06A25E14912F0008701CDF7F9A166F9C621`
- Identity conclusion: Cargo/intermediate/AppX/deployed relevant binaries一致；E2E结束后无 Dev/WTA process或 e2ebak残留。

测试 source 可以来自 dev-only harness，但被测 app/package 必须来自 exact publish HEAD。
显式设置 package selector，避免 harness 自动选择 Store、Release 或其他已安装版本。

## Real Integration Acceptance `[可选]`

本回归不依赖 agent/model 语义或外部服务，使用 deterministic ACP fixture 是最终验收的正确边界。
必须保留真实 Dev package、真实 window pointer input、ConPTY/crossterm、OS clipboard 和渲染截图；
不得用直接调用 `App::handle_event` 或直接注入 ConPTY SGR 的测试替代 packaged E2E。

## Visual Evidence `[UI/渲染/交互变更必填]`

- Screenshot matrix: baseline selected-before-right-click、baseline after-right-click failure、baseline Ctrl+V
  literal `v`、baseline Ctrl+Shift+V success、publish selected-before-right-click、publish copied/cleared/hint、
  second-right-click no-replay、publish Ctrl+V single-line、multiline 和 input-refocus success。
- Required states: failing baseline、before action、after action、recovery/edge states。
- Required provenance: exact publish commit、package path、source/deployed hashes、capture command。
- Required inspection: product UI 非空且可辨识；目标状态可见；layout 稳定；无 overlap、clipping、
  透明/全黑帧、错误窗口、启动占位画面或 mock 内容冒充真实验收。
- Automated checks: 在可行时加入 target HWND、nonblack pixel、dimensions 和 distinct-frame checks；
  自动检查不能替代逐图人工检查。
- Latest evidence directories: `test/e2e/artifacts/right-click-copy/green/`、
  `test/e2e/artifacts/right-click-copy/publish/paste-full-c4b84ff2-retry/`、
  `test/e2e/artifacts/right-click-copy/publish/right-click-c4b84ff2-retry/`

每轮触及同一 user-visible path 的修复都要重新截图。不得用旧截图加新测试报告代替本轮证据。

## Review Triage

Current review status: 尚未创建 PR；已完成 local senior review和复核，最终无 blocking findings。

Open review items: 无 feature blocker。Residual low risk为 explicit custom/unbound Ctrl+V gating只有
code-path review而无独立 settings E2E；effective action comparison已避免 stable command ID被用户覆盖。

Local review record：

- Date / review ID / head SHA: `2026-08-20` / local senior review（无 external ID）/ pre-commit diff。
- Finding path and summary: stable command ID可被 custom action覆盖；right-click hint可能沿用 Ctrl+C
  transient；paste draft断言未严格排除 leaked `v`或 multiline乱序。
- Decision / rationale: accepted。effective `ShortcutAction::PasteText`才是可执行语义；用户可覆盖 ID。
- Fix: 比较 resolved action；等待 Ctrl+C hint消失；对 single/multiline rendered draft执行 exact、有序断言。
- GREEN validation: TerminalApp focused build `0 errors`；exact publish Paste `5/5`、RightClickCopy `1/1`。
- Publish commit: `c4b84ff28012a6a1fc9e86f08d60e08edadb1b3a`。

Public PR 可在未认证时通过 REST endpoints 读取 pull、issue comments、reviews、review
comments、files 和 HEAD check-runs。Review body 中的 suppressed comments 也必须逐条 triage。
匿名访问不能回复或 resolve thread；报告限制，不索取凭据，也不使用需要登录的工具做只读 review。

## Local-Only Evidence Inventory

Evidence root: `test/e2e/artifacts/right-click-copy/`

| Artifact | Path | Proves | Commit/package identity |
|---|---|---|---|
| RED screenshot/log | `baseline-real-copilot/05-history-text-selected.png`、`06-right-click-no-op.png` | selection 正常但右键不改 clipboard | dev `c612a483` / WTA `116927FF...B7A85` |
| Ctrl+V RED | `baseline-real-copilot/08-keyboard-copy-paste.png` 及 pane capture | Ctrl+V 输入 literal `v`，clipboard marker 未粘贴 | dev `c612a483` / Dev package `0.8.0.2` |
| Ctrl+Shift+V control | `baseline-real-copilot/08-ctrl-shift-v-paste.png` 及 pane capture | downstream clipboard/protocol/draft path 正常 | marker `CSV_FINAL_...` exactly once |
| Focused test output | local cargo/Pester output（未单独持久化 report） | event mapping、shared copy lifecycle与 PasteCore | publishable `e717a37d8` |
| E2E baseline controls | `baseline-real-copilot/06b-keyboard-copy-positive-control.png`、`07-chat-input-focused.png`、`08-ctrl-shift-v-paste.png` | keyboard copy、focus 与 paste 正常 | Dev package `0.8.0.2` |
| GREEN right-click screenshots | `green/selected-before-right-click.png`、`after-right-click-copy.png`、`after-second-right-click.png` | exact selection、copy/clear/hint/no-replay | publish `c4b84ff2` / hashes见 Exact Publish Identity |
| GREEN paste screenshots | `green/ctrl-v-single.png`、`ctrl-v-multiline.png`、`ctrl-shift-v-control.png`、`ctrl-v-refocus.png` | single/multiline/control/refocus exact draft | publish `c4b84ff2` / exact Dev package |
| Publish reports | `publish/paste-full-c4b84ff2-retry/`、`publish/right-click-c4b84ff2-retry/` | packaged `5/5` + `1/1` and release report zero failures | publish `c4b84ff2` |
| Real integration evidence `[可选]` | `baseline-real-copilot/03-agent-pane-open-connected.png`、`04-real-copilot-reply.png` | installed/authenticated Copilot connected and replied | Copilot Windows v1.0.81-2 |
| Fixture/provider/wire log `[可选]` | 未保留独立 wire log（N/A） | 最终 contract由 protocol-event oracle、clipboard和rendered UI共同证明 | exact publish package |

- 列出 ignored screenshots、pane captures、fixture logs、test reports、local harness、scripts、
  wire captures 和 provider configurations，并说明每个 artifact 证明哪条 contract。
- 不因文件 ignored 就删除它们；保留用于复现、review follow-up 和后续 framework extraction。
- 若 evidence 不需提交，保留 ignored 状态，并在此记录 path、command、identity、result 和结论。

## Completion Checklist

- [x] 所有必填 placeholder 已替换；不适用项已明确标记 N/A。
- [x] Exact baseline 已 build/deploy，并在预期 behavioral oracle 上 RED。
- [x] Right-click 与 Ctrl+V focused regressions 分别先 RED 后 GREEN。
- [x] Neighboring tests、full relevant suite、explicit build 和 static analysis 已完成。
- [x] Publishable 与 dev-only commits 边界清晰。
- [x] Exact publish HEAD 已 build/deploy，source/deployed hashes 一致。
- [x] Packaged/deployed E2E 对 exact publish binary GREEN：right-click contract 与 Ctrl+V required matrix
  均完成，Ctrl+Shift+V control 不能替代 Ctrl+V。
- [x] 真实外部依赖不属于最终 contract；baseline real Copilot optional acceptance已完成。
- [x] UI/渲染/交互的 fresh screenshots 已逐图检查并记录 provenance。
- [x] Review findings 已逐条 triage，accepted fixes 有 RED/GREEN evidence。
- [x] Evidence inventory 能映射全部 user-visible assertions。
- [x] Dev 与 publish remote heads 已 push 并确认。

## Optional Follow-Ups

- 若通用 ItE2E UI primitive 不能发送真实右键，模块化增加 right-click input primitive，并单独评估
  是否提取为 test-framework PR；feature commit 只带自然归属的最小 helper。
- 另行评估 agent pane 无选区右键是否应恢复 native paste；本 bug 只恢复已有 WTA selection 的 copy。

只记录不属于当前 contract 的后续工作，并为其使用独立 issue、branch 或 PR。

以下是本repository的legacy版本的结构介绍，仅供参考，请始终以实际代码为准。

====================


# Intelligent Terminal

Intelligent Terminal is a Windows Terminal fork that adds first-class AI agent
workflows. The inherited Windows Terminal build, architecture, and C++ conventions
are documented in `.github/copilot-instructions.md`; this file contains only the
fork-specific context.

## Architecture

```
WindowsTerminal.exe
  |-- TerminalProtocolComServer (COM, discovered through WT_COM_CLSID)
  |-- SharedWta --> wta-master --> agent CLI pool (ACP over stdio)
  +-- one wta-helper pane per tab
                       |
                       +-- helper/master ACP over a named pipe
                       +-- session-scoped MCP tools

Agent or human CLI --> wta/wtcli --> COM IProtocolServer --> Windows Terminal
```

- **WTA** (`tools/wta/`) is the Rust orchestrator.
- **ACP** means Agent Client Protocol. `wta-master` lazily owns a pool of agent
  CLI processes keyed by agent identity, execution source, and command; helpers
  using the same key share one process and multiplex sessions through it.
- **WT Protocol** is the terminal-control boundary. `wtcli.exe` activates
  `IProtocolServer` through the package COM registration.
- **Session MCP** exposes `request_terminal_actions` and `request_user_input`.
  It routes requests to the owning helper and never executes terminal actions
  itself.
- Agent panes are ordinary `ConptyConnection` panes hosting `wta-helper`; C++
  does not speak ACP.

See `doc/specs/Multi-window-agent-pane.md` for the detailed lifecycle and
`tools/wta/AGENTS.md` for WTA-specific implementation rules.

## Supported agents and settings

Built-in ACP and delegation providers are Copilot, Claude, Codex, Gemini, and
OpenCode. Custom providers use a `custom:<name>` ID plus the matching custom
command setting.

```jsonc
{
    "acpAgent": "copilot",
    "acpModel": "",
    "acpCustomCommand": "",
    "delegateAgent": "copilot",
    "delegateModel": "",
    "delegateCustomCommand": "",
    "agentPanePosition": "bottom",
    "autoErrorDetectionEnabled": true,
    "autoFixEnabled": false,
    "aiIntegration.coordinator.enabled": false,
    "aiIntegration.coordinator.commandline": "wta",
    "aiIntegration.coordinator.profile": "{fd19208a-412b-4857-8a2d-9ca592b4b16e}",
    "aiIntegration.confirmation.readOperations": "auto",
    "aiIntegration.confirmation.createOperations": "auto",
    "aiIntegration.confirmation.inputOperations": "auto"
}
```

The settings model is authoritative; check
`src/cascadia/TerminalSettingsModel/MTSMSettings.h` and
`src/cascadia/inc/AgentRegistry.h` before documenting defaults or providers.

## User-facing behavior

| Trigger | Behavior |
| --- | --- |
| `>Toggle AI assistant` | Stash or restore the current tab's agent pane |
| `?<prompt>` | Delegate a prompt through WTA |
| `?` | No-op |
| `&<prompt>` | Reserved background-task entry point; currently a no-op |

Important invariants:

- Each eligible tab pre-warms one stashed helper. Skip pre-warm when WTA is
  unavailable, policy blocks all agents, the tab has no active terminal, or a
  dragged-in agent pane already exists.
- Toggling an agent pane stashes/restores it; it does not destroy the helper,
  ACP session, or chat history.
- Per-tab events carry tab and window identity. Route responses to the owning
  tab instead of broadcasting across panes or windows.
- Autofix requires a connected helper session. Failures received before the
  session connects are not replayed later.
- Terminal mutation requested by an agent goes through the confirmation-gated
  session MCP action path. Agent-owned shell tools are a separate execution
  path.

## Key files

| Area | Path |
| --- | --- |
| Terminal integration | `src/cascadia/TerminalApp/TerminalPage.cpp` |
| Protocol bridge | `src/cascadia/TerminalApp/TerminalPage.Protocol.cpp` |
| Tab lifecycle and pre-warm | `src/cascadia/TerminalApp/TabManagement.cpp` |
| Agent pane chrome | `src/cascadia/TerminalApp/AgentPaneContent.cpp` |
| Stash/restore | `src/cascadia/TerminalApp/Tab.cpp` |
| Shared WTA process | `src/cascadia/TerminalApp/SharedWta.cpp` |
| COM server | `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp` |
| Protocol IDL | `src/cascadia/TerminalProtocol/TerminalProtocol.idl` |
| Agent registry | `src/cascadia/inc/AgentRegistry.h` |
| Settings | `src/cascadia/TerminalSettingsModel/MTSMSettings.h` |
| WTA master/helper | `tools/wta/src/master/mod.rs`, `tools/wta/src/helper/mod.rs` |
| Runtime agent prompt | `tools/wta/prompts/terminal-agent.md` |

## Build and validation

WTA and Terminal use separate build systems. Build WTA before packaging changes
that need a refreshed `wta.exe`.

### WTA

Always use the explicit Windows target. `CascadiaPackage.wapproj` prefers this
output over the host-target fallback, so mixing target layouts can silently
deploy a stale binary.

```powershell
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
```

Output: `tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe`.

A live WTA process may lock the output. Stop only processes whose executable
path exactly matches the binary being rebuilt; never terminate every `wta.exe`
or `WindowsTerminal.exe` by name.

### Terminal

```cmd
cmd.exe /c "tools\razzle.cmd && bcz no_clean"
```

For Release use `bcz rel no_clean`. For a project-local incremental build, enter
the project directory in the same razzle CMD session and use `bx`.

After C++, XAML, IDL, packaging, resource, or mixed Debug changes, deploy with:

```powershell
.\build\scripts\Invoke-IntelligentTerminalDebugDeployment.ps1 `
    -AppxRecipePath src\cascadia\CascadiaPackage\bin\x64\Debug\CascadiaPackage.build.appxrecipe
```

Do not perform a full package deployment for a `wta.exe`-only change. Static
assets such as `wt-agent-hooks` do require packaging.

## Runtime data and diagnostics

Packaged state and cache data are package-private:

- State: `Packages\<PFN>\LocalState\IntelligentTerminal`
- Cache/logs: `Packages\<PFN>\LocalCache\Local\IntelligentTerminal`
- Logs: `logs\<package-version>\`

Unpackaged development falls back to
`%LOCALAPPDATA%\IntelligentTerminal`. Resolve paths through the shared runtime
path helpers; do not hard-code `%TEMP%` or a bare LocalAppData path.

Primary logs are:

- `wta-main_master.log`
- `wta-main_helper-{pid}.log`
- `wta-cli.log`
- `wta-delegate.log`
- `wta-probe.log`
- `wta-install-hooks.log`
- `wta-ensure-host.log`
- `wta-acp-debug.log`
- `terminal-agent-pane.log`
- `hook-trace.log`

Use `WTA_LOG=debug` or `WTA_LOG=trace` for additional Rust tracing. See
`tools/wta/README.md` for current diagnostics and CLI usage.

## Focused design references

- Multi-window helper/master lifecycle:
  `doc/specs/Multi-window-agent-pane.md`
- Session tracking: `doc/specs/hybrid-agent-session-tracking.md`
- Security boundaries: `doc/security-model.md`
- Installer: `doc/building-installer.md`
- WTA customization: `tools/wta/CUSTOMIZATION.md`
