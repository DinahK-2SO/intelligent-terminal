# Feature TDD 开发与交接模板

> 本文件用于新 feature、行为变更和回归修复的 test-driven development、发布验证与交接。
> 产品行为、已提交测试和可复现证据始终是最终事实来源。

## 本实例使用规则

1. 本文件已实例化为 issue #790 的 dev-only TDD 交接；持续更新实际阶段、命令、结果和证据路径。
2. 当前阶段只建立 exact-baseline RED、行为矩阵和截图，不修改产品实现。
3. UI、渲染和交互证据必须来自明确选择的 Dev package，并记录 source、package 和 live binary identity。
4. agent pane 使用本地 deterministic ACP fixture；不提交真实模型请求，不依赖 provider quota。
5. baseline 若不能在预期 oracle 上失败，停止产品修改并记录实际行为。

## GitHub 双账号门禁

每个新的 Copilot session 在开始任何开发、代码调查、build/test 或线上 GitHub 读取/写入前，
必须先完成以下身份检查。门禁通过前只允许执行身份检查；任一检查失败或无法确认时，告诉 user
需要重新登录哪个账号，然后暂停其他工作。

1. 从当前 Copilot session、VS Code Accounts 界面或 Copilot 账号选择器确认界面明确显示
  `当前用户标记 │ @xiaomgao_microsoft`。这是本模板唯一允许通过的 Copilot 身份；不得仅凭
  `_microsoft` 后缀，也不得用 `gh`、Git remote、commit author 或系统用户名推断。若该标记
  不可见、无法确认或不是 `@xiaomgao_microsoft`，告诉 user 重新登录 Copilot/VS Code 的
  Microsoft 内部账号，并暂停其他工作。
2. 运行 `gh auth status --hostname github.com`，再运行 `gh api user --jq .login`，确认当前 active
  `gh` 账号。它必须是 user 通过 `gh auth login` 登录的开源社区开发账号，且不得以
  `_microsoft` 结尾（例如 `DinahK-2SO`）。若 `gh` 未登录、账号无法确认或账号以
  `_microsoft` 结尾，告诉 user 使用社区开发账号重新运行 `gh auth login`，并暂停其他工作。
3. 只有当前用户标记精确为 `@xiaomgao_microsoft` 且 `gh` 账号不以 `_microsoft` 结尾时门禁才通过。
  记录两个账号名和检查时间，但不得记录 token、cookie、credential、account ID 或其他 secret。
  Copilot 与 `gh` 是独立认证面；不得因为其中一侧正确而假定另一侧正确。
4. 门禁通过后，线上 GitHub PR、issue、review、comment、check 和 GraphQL/REST 交互统一使用
  已验证的 `gh` 社区账号；Git repository 操作使用 command-line `git` 及已配置 remote。
  不得调用 GitKraken，不得由 agent 自动登录、切换账号、刷新 token 或修改 credential 配置。
5. Copilot session 重启、VS Code 账号变化、`gh` 认证错误或 user 表示重新登录后，必须重新执行
  完整门禁。任一检查后来失效时，立即停止线上和本地后续步骤，报告实际账号或 `UNKNOWN`，
  等待 user 完成重新登录。

### 当前身份记录

- 检查时间：2026-09-04 13:52 +08:00
- Copilot 当前用户标记：`@xiaomgao_microsoft`
- GitHub CLI active account：`DinahK-2SO`
- 结论：双账号门禁通过；未记录 token、cookie 或 credential。

## Feature Metadata

- Feature: Agent pane Ctrl+mouse-wheel zoom parity
- Summary: Establish deterministic RED coverage for Ctrl+wheel text zoom in terminal and agent panes, including ordinary-wheel negative controls.
- User-visible goal: Ctrl+wheel changes text size consistently in both pane types while ordinary wheel retains scrolling behavior.
- Base: `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`
- Dev branch: `user/DinahK-2SO/agent-pane-zooming` -> `Dinah`
- Publish branch: `user/DinahK-2SO/agent-pane-zooming-publish` -> `origin`
- Issue / pull request: `microsoft/intelligent-terminal#790`
- Evidence root: `local-tdd-kit\artifacts\issue-790-agent-pane-zoom`
- Current publishable commit: none; baseline and test design only
- Current publish head: `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`
- Out of scope: Product fix, unrelated selection/paste behavior, global UI scaling, provider-generated responses, and PR creation.

## Current Stage

`2026-09-04`: Exact-baseline RED established. The publish worktree
`C:\bugfix\intelligent-terminal-worktrees\agent-pane-zooming-publish` is clean and pinned to
`fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`, matching `origin/main`. Its loose Dev package is
built, deployed, hash-recorded, and selected with `ITE2E_PACKAGE=Dev`. Physical HWND wheel input
produces the expected matrix: terminal Ctrl+wheel PASS (`27 -> 26` rows), agent plain wheel PASS
(viewport changes, draft preserved, `12 -> 12` rows), and agent Ctrl+wheel RED (`12 -> 12` rows
while the viewport changes). Product implementation remains intentionally not started.

记录当前处于 RED、实现、focused GREEN、full validation、exact publish validation、
真实集成验收或 review follow-up 中的哪一步。包含阻塞项和下一条可执行命令。

## Long-Running Automation And Autopilot

“Autopilot”要求agent在同一个turn内等待有界任务完成并继续后续步骤，而不是把命令留在
后台后承诺未来继续。build、full test、package/deploy、freshness和E2E通常超过短执行器的
等待窗口，必须按以下规则编排：

1. **在terminal tool支持时，有界的一次性任务使用直接同步execution，且不设置tool timeout。**
  包括build、test、install、package、deploy、format、lint和脚本。不要把可能超过90秒的命令
  交给有固定等待上限的execution subagent，也不要为这类任务使用async/background模式。
2. **同步返回后立刻在同一turn继续。** 读取exit code、receipt和report，然后执行下一阶段；
  不要输出“完成后会继续”并结束turn。仅在全部目标完成、遇到不可恢复错误或确实需要用户
  决策时结束。
3. **返回terminal ID表示工作尚未完成。** 不得把handoff、timeout或“may still be running”
  当作成功，也不得在仍依赖该结果时给final answer。若平台要求等待下一turn才能取得后台
  结果，agent无法自行唤醒；这是平台限制，不能用“autopilot”消除。应从一开始改用同步执行，
  或让一个durable wrapper在后台自行完成所有剩余机器步骤并写最终journal。wrapper只有在其
  process未被execution host或VS Code取消时才能继续；journal会把process消失标为interrupted。
  意外发生handoff时，必须保留terminal ID；不要轮询、sleep或重复启动同一命令。等待平台的
  自动完成通知后，立即用该ID读取最终输出，确认真实exit code，再按成功或失败路径继续。
  该ID对应的持久terminal在完成前是独占的；不得向默认同步shell再发命令，因为runner可能
  通过Ctrl+C抢占仍在运行的batch并触发`Terminate batch job`。等待期间只使用不复用该terminal
  的只读工具，或使用明确保证隔离的新terminal；若误触终止提示，回答`N`并保留原任务。
4. **长workflow使用持久化phase journal。** 在每个phase前写`running`，结束时写
  `passed`/`failed`、exit code、HEAD、时间和artifact path。旧receipt不能代替本轮journal；
  中断后必须能区分`running`、`interrupted`、`failed`和`passed`。
5. **build/deploy默认不启动UI。** `-Launch`会通过Explorer激活Dev Terminal，可能抢前台或
  造成VS Code可见闪动，也会干扰foreground-sensitive input测试。只在freshness通过且下一步
  确实需要窗口时启动；由E2E自己的`Start-Terminal`优先负责启动和identity绑定。
6. **不要把多个昂贵阶段塞进短等待执行器。** 若不用durable wrapper，full tests、build/deploy
  和E2E分别用同步调用，以便每阶段失败立即停止；若使用wrapper，则由wrapper顺序执行全部
  阶段并在`finally`中持久化最终状态。
7. **行动承诺必须伴随实际行动。** 在autopilot下，一旦回复“现在调查、运行或继续”，同一
  response必须发起相应tool call；不得只输出计划性文字后yield，迫使用户再发消息启动工作。
8. **等待期间继续不依赖结果的安全工作。** 可以整理证据、读取相邻代码或准备文档，但不得
  deploy旧产物、启动依赖该build的测试、修改第二个实现slice，或把后台状态写成GREEN。只要
  当前任务仍有可执行步骤，就不能因为一个validation terminal仍在运行而结束整个任务。
9. **插入式对话不能丢失active task。** 用户在实现过程中提出status、解释或不冲突的产品问题时，
  简短回答后必须在同一个response恢复最近一个未完成action，并实际调用tool继续；不要把插问
  当作新的完整任务调用`task_complete`或发送final。只有用户明确要求pause/stop、最新请求与旧
  目标冲突，或active checklist已全部完成时，才可结束原任务。每次恢复前快速核对最新用户请求、
  dirty paths、仍在运行的terminal/journal和下一条命令，避免继续一个已经失效的旧目标。
10. **缺失输出是UNKNOWN，不是PASS。** execution helper声称命令成功但未返回exit code、test totals
  或关键diagnostic，或只给出“output unavailable/truncated”，不能作为验证证据。先判断命令是否仍
  在运行：有terminal ID时保留独占并等待自动完成通知；有journal/receipt/report时读取其终态与
  identity；进程已结束且check廉价、幂等时，改用同步无timeout、强过滤输出的命令重跑。昂贵命令
  不得仅因摘要丢失就重复启动；先用artifact、process identity和持久journal恢复结果。无论采用哪条
  路径，只要active task还有独立可执行工作，就继续推进并保持用户可见进度更新。

推荐的本地完整pipeline由`local-tdd-kit/Invoke-LocalTddPipeline.ps1`执行。调用它的agent仍须
使用同步、无timeout的terminal execution；journal是抗中断证据，不是唤醒已结束agent turn的机制。

## Scope And Contract

### User-Visible Contract

- With `experimental.scrollToZoom=true`, Ctrl+wheel up over an ordinary terminal pane increases rendered terminal glyph height and Ctrl+wheel down restores or decreases it.
- With the same setting, Ctrl+wheel over the agent pane changes the wrapped TermControl font size rather than delivering a chat-scroll wheel event to WTA.
- Plain wheel over the agent pane still scrolls overflowing chat content without changing the draft or rendered font size.
- Ctrl+wheel must be injected through the real window/pointer path at coordinates inside the target pane; command actions or direct TermControl calls are not substitutes.
- Repeated opposite-direction zoom steps must remain bounded and reversible within one live tab; opening, hiding, or restoring the agent pane must not be required to observe the change.

每条 contract 都必须能映射到至少一个自动化断言或人工可观察证据。不要只描述内部状态。

### Preserved Invariants

- Existing plain-wheel agent chat scrolling, draft preservation, mouse selection, right-click paste, terminal scrollback, and Ctrl+Shift+wheel opacity behavior remain unchanged.
- 未涉及的输入方式、已有 workflow、设置迁移和兼容行为保持不变。
- 不扩大 feature 的 ownership boundary，不顺手修复无关问题。

### Guardrails

- Pin `ITE2E_PACKAGE=Dev`; validate HWND/PID ownership before physical input; restore cursor, settings, state, and only test-owned processes in `finally`.
- Use a deterministic local ACP fixture and unique visible markers; do not rely on model text or network authentication.
- A RED result requires successful input injection plus unchanged visible row count in the
  fixed-height agent control; setup or foreground failures are BLOCKED, not product RED.
- 不通过测试专用 product path、硬编码 fixture 输出或不可达状态满足验收。
- 不以内部字段变化代替真实输出或用户流程验证。
- 只格式化 touched files，避免 repository-wide mechanical churn。

## Ownership Hypothesis

```text
physical Ctrl+mouse-wheel at a pane coordinate
  -> XAML/TermControl pointer-wheel routing
  -> Pane and TerminalPage active-control dispatch
  -> TermControl ControlInteractivity font adjustment or WTA VT mouse delivery
  -> fixed-height pane row count and screenshots show zoom or unintended viewport scrolling
```

- Owning code path: `src\cascadia\TerminalApp\Pane.cpp`, `src\cascadia\TerminalApp\AppActionHandlers.cpp`, and `src\cascadia\TerminalControl\ControlInteractivity.cpp`
- Owning abstraction: Pane-level routing between an `AgentPaneContent` wrapper and its underlying `TermControl`
- Falsifiable hypothesis: Ordinary terminal Ctrl+wheel reaches `ControlInteractivity::_mouseZoomHandler`, while the agent pane's mouse-tracking TermControl sends the wheel to WTA before the zoom branch; the missing pane-level bypass prevents parity.
- Cheapest discriminating check: Compare product-reported visible row count before and after real
  Ctrl+wheel input at UIA-selected TermControl coordinates, while recording whether the captured
  agent viewport changed.
- Nearest existing test / fixture / helper: `test\e2e\tests\Feature.AgentMouse.Tests.ps1`, `test\e2e\ItE2E\Public\AgentInput.ps1`, `local-tdd-kit\ItE2E\Public\Ui.ps1`, and `local-tdd-kit\fixtures\Mock-AcpChatAgent.ps1`

在首次 product edit 前必须能够写出上述 hypothesis 和 check。若 check 不能区分候选原因，
只补一次邻近读取或测试，然后选择最小可逆 edit；不要无限扩展调查范围。

## Commit And Worktree Discipline

- Publishable changes先在 dev branch 形成一个自包含 commit：product code、自然归属的
  unit/integration tests、确定性 fixture、已有 E2E framework 内的 regression case，
  以及应随产品发布的 checklist 或 test metadata。
- Dev-only changes单独提交：本交接、进度记录、ignored screenshots/reports/logs、
  本地 orchestration、provider 配置、实验，以及不应进入 publish 的最终验收 harness。
- 任何会提交真实模型请求、消耗token/provider quota或依赖本机付费凭据的测试，连同其源码、
  orchestration和报告，都必须是dev-only/local-only；不得进入publish branch、正式`test/e2e`
  suite或CI pipeline。CI没有真实provider额度，只能运行deterministic mock、fixture或明确的
  zero-token initialize/session/capability检查。
- Publish worktree 只直接 cherry-pick publishable commit。不要 cherry-pick mixed commit
  后再 restore 文件，也不要把 dev-only acceptance commit 带入 publish。
- 不修改或回退无关的用户改动。若无关改动不阻塞当前工作，保持原状。
- 不 force-add ignored evidence。需要提交 review evidence 时，复制最终选定文件到
  `.github\review-evidence\issue-790\`。
- 未经明确要求，不创建额外 branch、不重写历史、不使用 destructive git command。

## Test Reuse And Framework Boundaries

- 首先复用或扩展 `Feature.AgentMouse.Tests.ps1`、`Mock-AcpChatAgent.ps1` 和 dev-only
  `Issue790.AgentPaneZoom.Tests.ps1`。
- 新增测试应落在 ownership 最近的现有 suite 中，并只引入使 regression 稳定所需的
  最小 helper 或 deterministic fixture。
- 当现有 framework 无法执行真实用户操作时，可在 dev-only 范围建立模块化 local
  orchestration 以取得 RED/GREEN evidence，并将通用 framework 提取作为独立 PR。
- 不在 feature commit 中夹带大型 test framework、通用 harness rewrite 或无关基础设施。
- Mock/deterministic fixture 可用于 focused RED/GREEN、几何、路由和故障隔离；若 contract
  依赖真实外部系统，它不能替代最终真实集成验收。
- 真实provider/model/tool验收若消耗token，测试文件必须放在dev-only harness/evidence root；
  publishable E2E只保留不会产生推理费用的product workflow和protocol检查。

## Reproduction And RED Oracle

### Baseline Identity

- Source commit: `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`
- Build command: `cmd.exe /d /c "cd /d C:\bugfix\intelligent-terminal-worktrees\agent-pane-zooming-publish && call tools\razzle.cmd && bcz no_clean"`
- Package / deployment: `IntelligentTerminal_rd9vj3e6a2mbr` / `C:\bugfix\intelligent-terminal-worktrees\agent-pane-zooming-publish\build\scripts\Invoke-IntelligentTerminalDebugDeployment.ps1`
- Relevant binaries: publish worktree `bin\x64\Debug\WindowsTerminal.exe`, `bin\x64\Debug\wtcli\wtcli.exe`, and packaged `src\cascadia\CascadiaPackage\bin\x64\Debug\AppX\WindowsTerminal.exe`
- Source/deployed hashes: `WindowsTerminal.exe`
  `0F9080992844B5D032849474F2F44AB2C5C1AD7B095AAE88CFD72D456228969A`, `wta.exe`
  `6D063033EE05C22CC159139E78983612E66B453C9604F649671FCFFB685CF4A4`, and `wtcli.exe`
  `0B9936EE6CF2564951BD3B26AD371EDEE5E4484493C6FCA9A8485711C0B3D074`

### Reproduction

1. 从 exact baseline build 并部署，记录 commit、package path、binary size 和 SHA-256。
2. 使用本地 deterministic ACP fixture、一个普通 shell marker 和一个 overflowing agent transcript 建立最小场景，并验证 setup preconditions。
3. 通过真实 HWND 上的 physical Ctrl+wheel 和 plain wheel 执行用户操作。
4. 捕获实际输出、日志、测试报告；UI 变更同时保存 RED screenshot。
5. 证明失败只发生在 agent-pane zoom oracle，而不是 setup、连接、fixture、terminal control case 或错误 binary。

- RED oracle: At fixed control height, terminal-pane rows decrease after Ctrl+wheel, but agent-pane
  rows remain unchanged while both plain wheel and Ctrl+wheel move the agent transcript viewport.
- Expected failure location/message: `Issue790.AgentPaneZoom.Tests.ps1:212` reports
  `Expected the actual value to be less than 12 ... viewportChanged=True, but got 12.`
- Setup evidence: `identity\package.json`, `identity\deployment-result.json`,
  `identity\terminal-before.json`, `identity\terminal-after.json`, `identity\agent-before.json`,
  `identity\agent-after.json`, and the passing plain-wheel control in `focused-red\results.xml`.
- RED artifact paths: `local-tdd-kit\artifacts\issue-790-agent-pane-zoom\baseline-fbe0b12ec\focused-red\`
  and `local-tdd-kit\artifacts\issue-790-agent-pane-zoom\baseline-fbe0b12ec\screenshots\`.

如果 baseline 不能在预期 oracle 上失败，停止 product edit，先报告现有行为和证据。

## Strict TDD Workflow

1. 找到最近的 existing test、fixture、helper 和 E2E suite。
2. build/deploy exact baseline，并记录 binary identity。
3. 只运行新 case，确认 agent-pane visible-row assertion按预期 RED。
4. 添加 ownership 最近的最小 unit/state/render regression，并确认 RED。
5. 在 Pane-level agent-wrapper mouse routing boundary 做最小实现。
6. 首次 substantive edit 后立即运行
   `$env:ITE2E_PACKAGE='Dev'; Invoke-Pester local-tdd-kit\examples\Issue790.AgentPaneZoom.Tests.ps1 -Tag Issue790`；不要先扩大改动范围。
7. 若失败支持 hypothesis，修复同一 slice 并重复 focused check；若 falsify hypothesis，
   只向真正 owner 邻近移动一步。
8. focused GREEN 后运行 neighboring `Feature.AgentMouse.Tests.ps1`、TerminalApp LocalTests 和 required package build。
9. 运行 `$env:ITE2E_PACKAGE='Dev'; Invoke-Pester local-tdd-kit\examples\Issue790.AgentPaneZoom.Tests.ps1 -Tag Issue790`，从真实入口验证两类 pane 均缩放且 plain wheel 不退化。
10. 提交 publishable commit；将 dev-only evidence/orchestration 另作 commit。
11. clean publish worktree 直接 cherry-pick publishable commit。
12. 从 exact publish HEAD用同步、无tool-timeout执行build/deploy，校验source/deployed binary
  SHA-256，并在同一turn继续重跑E2E；也可用durable local-TDD pipeline一次完成这些phase。
13. 本 feature 不依赖真实 provider；deterministic local ACP fixture 即为 agent process boundary。
14. 对 UI/渲染/交互变更捕获该轮 exact publish HEAD 的 fresh success screenshots 并逐图检查。
15. 更新本文件的 stage、validation、review triage、artifact inventory 和 open items。
16. 达到下述 publish confidence gate 后 push dev/publish并创建PR；online review与
  broader local E2E并行，记录两个remote heads和PR URL。

## Reusable TDD Failure Triage

- **TAEF wrapper结果冲突：** 如果`runut`或aggregate wrapper显示目标test body PASS，但另一个
  discovery/architecture phase报告no matching tests并使process非零退出，不能把整条命令记为
  GREEN。定位source-built `TE.exe`和exact test DLL，直接使用`/name:`运行；必须同时满足
  `Total >= 1`、目标test PASS和exit code `0`。把wrapper问题单独记为infrastructure evidence。
- **动态inventory：** locale、resource、fixture、provider或case目录必须在测试运行时枚举；
  parity断言应比较discovered set，不能硬编码当前数量。新增locale时，测试应自动扩大覆盖而不是
  因旧数字失败。`.resw`还要独立验证XML、BOM、EOL、locked tokens和跨locale comment一致性。
- **边界wiring RED：** 当缺口是hard-to-host UI/event/save boundary中的missing call、ordering
  或ownership mutation，可先用最小source-structure test证明该边界，但前提是被调用helper已有
  behavioral unit coverage。Fix后仍必须build owning project并运行neighboring/package behavior；
  source test不能替代产品行为oracle。
- **CRLF-aware diff：** Windows源码使用
  `git -c core.whitespace=cr-at-eol diff --check`；不要把CRLF中的`\r`误报为trailing whitespace。
  该命令不替代resource BOM/XML/EOL验证。
- **非行为source变更与receipt：** source fingerprint覆盖范围内的任何变化（包括code comment）
  都会使旧receipt不再对应exact HEAD。若要声称final-head freshness，必须从新HEAD重建receipt；
  只有在diff可证明不改变行为并明确记录parent identity时，behavioral E2E才可复用直接parent结果。
- **精确process cleanup：** 先按exact installed/AppX root枚举process path并记录PID，再只停止
  这些明确PID，最后重新枚举并要求为0。不得按`WindowsTerminal`、`wta`、`wtcli`或
  `OpenConsole`名称全局终止，也不得使用未解析的变量/通配符作为cleanup target。

## PR Creation And Parallel Review

当publish branch已有clean tracked state、current base ancestry、deterministic
RED-to-GREEN、focused/full relevant source validation和exact-package
build/deploy/freshness evidence时，可以push并创建PR，不必等待broader local E2E完成。

- 使用ordinary push；未经明确授权不得force-push或rewrite history。
- 使用项目`.github/PULL_REQUEST_TEMPLATE.md`结构。
- PR title不得超过20个words。
- `Summary of the Pull Request`不得超过100个words。
- `Validation Steps Performed`不得超过100个words。
- 其他template sections可留空；如填写，保持concise且准确。
- 不得把未运行、blocked或失败的validation写成PASS。
- PR创建后，让online checks/review与同一published HEAD的local package/UI/
  real-integration E2E并行。
- HEAD变化后重新关联online review/checks与local package evidence；需要时从新HEAD重建。
- Agent不得merge PR到`main`。
- Agent不得resolve、dismiss或close任何active review comment/thread，即使后续
  iteration已经修复、重复或使其outdated。Active comments留给用户review和resolve。
- 可以push valid fixes并留下commit/evidence reply，但reply必须保持thread active。

## Implementation Record

- Behavioral change: None yet; baseline-only phase.
- State / API changes: None yet.
- Preserved invariants: Plain wheel scrolling, draft preservation, terminal scrollback, existing mouse selection/paste, and settings restoration.
- Performance implications: None in baseline phase; future fix must perform only constant-time event routing.
- Security / privacy implications: Physical input is scoped to verified test-owned HWND/PID; no credentials or model prompts are captured.
- Rejected alternatives and rationale: Direct `AdjustFontSize` invocation and keyboard action
  dispatch do not prove the physical Ctrl+wheel routing bug; UIA TextPattern was not reliable in
  this build, so UIA is used only to target the physical control while product-reported row count
  and captured pane text provide the deterministic oracle.

记录最终实现的事实，不保留已经失效的设计猜测。若 ownership hypothesis 被证伪，更新
Ownership Hypothesis 并说明哪个 check 改变了判断。

## Validation Matrix

| Layer | Command / Method | Expected | Result | Evidence |
|---|---|---|---|---|
| Bootstrap | `pwsh -NoProfile -File local-tdd-kit\bootstrap.ps1 -Check` | Required tools and selected Dev package available | Passed: PowerShell 7.6.5, Pester 6.1.0, Windows App CLI, Git, Cargo, Dev package, and 158 ItE2E functions | `baseline-fbe0b12ec\bootstrap-check.txt` |
| Focused RED | `$env:ITE2E_PACKAGE='Dev'; pwsh -NoProfile -File local-tdd-kit\Invoke-LocalTddReport.ps1 -Path local-tdd-kit\examples\Issue790.AgentPaneZoom.Tests.ps1 -Tag Issue790 -OutDir local-tdd-kit\artifacts\issue-790-agent-pane-zoom\baseline-fbe0b12ec\focused-red` | Terminal and plain-wheel controls pass; agent Ctrl+wheel fails zoom assertion | Passed 2, failed 1; only agent Ctrl+wheel failed with rows `12 -> 12` and `viewportChanged=True` | `baseline-fbe0b12ec\focused-red\report.html`, `results.xml`, `summary.md` |
| Plain-wheel control | Issue-specific physical wheel case | Chat scrolls; draft and font size unchanged | Passed: viewport changed, draft remained visible, rows `12 -> 12` | `baseline-fbe0b12ec\focused-red\results.xml`, `screenshots\agent-before-plain-wheel.png`, `agent-after-plain-wheel.png` |
| Focused GREEN | Same issue-specific suite after product fix | Both pane types zoom; controls pass | Not started | future exact-publish evidence |
| Neighboring tests | `$env:ITE2E_PACKAGE='Dev'; Invoke-Pester test\e2e\tests\Feature.AgentMouse.Tests.ps1` | No regression | Not started | future report |
| Full relevant suite | `cmd.exe /d /c "call tools\razzle.cmd && runut TerminalApp.LocalTests.dll"` plus relevant ItE2E | All pass | Not started | future report |
| Explicit build | explicit-target WTA `cargo build`, then publish-worktree `bx` in `src\cascadia\CascadiaPackage` | 0 errors and complete AppX payload | Passed after building the initially missing explicit-target `wta.exe` | built AppX and `identity\package.json` |
| Packaged / deployed E2E | issue-specific suite pinned with `ITE2E_PACKAGE=Dev` | Deterministic baseline RED | Passed controls and reproduced one expected product failure | baseline Pester report, identity JSON, and six screenshots |
| Static analysis | `git -c core.whitespace=cr-at-eol diff --cached --check` | No whitespace errors | Passed | staging receipt |

### Exact Publish Identity

- Publish commit: `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`
- Package identity/path: `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr` at
  `C:\bugfix\intelligent-terminal-worktrees\agent-pane-zooming-publish\src\cascadia\CascadiaPackage\bin\x64\Debug\AppX`
- Source binaries and SHA-256: `WindowsTerminal.exe`
  `0F9080992844B5D032849474F2F44AB2C5C1AD7B095AAE88CFD72D456228969A`, `wta.exe`
  `6D063033EE05C22CC159139E78983612E66B453C9604F649671FCFFB685CF4A4`, `wtcli.exe`
  `0B9936EE6CF2564951BD3B26AD371EDEE5E4484493C6FCA9A8485711C0B3D074`
- Deployed/live binaries and SHA-256: the Dev package is registered directly from the exact
  publish-worktree AppX path above, with the same three hashes.
- Identity conclusion: Exact baseline source, registered loose package, and exercised Dev package
  all resolve to publish HEAD `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`; deployment preserved
  both `settings.json` and `state.json`.

测试 source 可以来自 dev-only harness，但被测 app/package 必须来自 exact publish HEAD。
显式设置 package selector，避免 harness 自动选择 Store、Release 或其他已安装版本。

## External Dependency Boundary

No authenticated or quota-consuming provider is required. The baseline test uses the packaged
WTA helper with a deterministic local ACP fixture, so the real process, ConPTY, XAML pointer,
TermControl, and rendering boundaries are exercised without model output.

## Visual Evidence `[UI/渲染/交互变更必填]`

- Screenshot matrix:
  - ordinary terminal before Ctrl+wheel and after Ctrl+wheel up;
  - agent pane before Ctrl+wheel and after Ctrl+wheel up showing unchanged text size and shifted transcript;
  - agent pane before and after plain wheel showing transcript movement with unchanged draft/font;
  - cleanup/restored state after opposite-direction wheel or test teardown.
- Required states: failing baseline、before action、after action、recovery/edge states。
- Required provenance: exact publish commit、package path、source/deployed hashes、capture command。
- Required inspection: product UI 非空且可辨识；目标状态可见；layout 稳定；无 overlap、clipping、
  透明/全黑帧、错误窗口、启动占位画面或 mock 内容冒充真实验收。
- Automated checks: 在可行时加入 target HWND、nonblack pixel、dimensions 和 distinct-frame checks；
  自动检查不能替代逐图人工检查。
- Latest evidence directory:
  `local-tdd-kit\artifacts\issue-790-agent-pane-zoom\baseline-fbe0b12ec\screenshots\`
- Inspection result: terminal text becomes visibly larger and rows change `27 -> 26`; agent text
  size remains unchanged at 12 rows after Ctrl+wheel while the transcript moves; plain wheel also
  moves the transcript without changing row count or losing the draft. All six frames show the
  intended Dev package UI with readable, nonblank content and no clipping or overlap.

每轮触及同一 user-visible path 的修复都要重新截图。不得用旧截图加新测试报告代替本轮证据。

## Review Triage

Current review status: Not started; no PR exists and no product fix has been authored.

Open review items: None. Baseline RED and behavior matrix must be completed before implementation or review.

每轮 review 追加一条记录：

- Date / review ID / head SHA: not applicable before PR creation
- Finding path and summary: none
- Decision: none
- Technical rationale: implementation intentionally deferred
- RED evidence: pending exact-baseline E2E
- Fix or response: none
- GREEN validation: not started
- Publish commit: baseline `fbe0b12ec501b5db1a90962ad7e1bbd0c7d3597b`

Review inventory必须覆盖：

- 所有visible inline/file-level comments和active threads。
- 每个相关review object的完整body，包括suppressed comment/finding sections。
- Generated/suppressed counts；`0` visible comments不等于没有suppressed finding。
- 直接读取raw review body并识别官方zero-comment wording，包括
  `Comments generated: 0 new`。若automation parser与raw body不一致，记录review ID、
  exact HEAD、inline count、suppressed section和parser差异；把它分类为tooling bug，不能
  因此放松exact-head、checks-settled或open-thread reply gates。
- Spelling workflow conclusion、全部annotations和相关log summary；绿色check也可能
  包含需要判断的content annotation。

每条visible、suppressed和spelling finding都必须核对exact HEAD、owning code、
可复现behavior、tests和安全边界后，独立分类为accept、decline或escalate。不要因自动
reviewer身份盲目接受，也不要因check为green直接忽略annotation。Spelling triage需区分
真实repository content问题与external dictionary/network、generated-file或workflow
infrastructure warning；优先修正文案，不随意扩大allowlist/ignore pattern。

Valid finding先建立deterministic RED，再做最小fix并push。任何reply都必须保持
`-NoResolve`语义；不得调用resolve模式或outdated-thread cleanup。Review loop完成不要求
`open threads = 0`：current HEAD已review、checks settled、所有findings完成critical
triage且valid fixes已push即可停止，active comments继续留给用户。

## Local-Only Evidence Inventory

Evidence root: `local-tdd-kit\artifacts\issue-790-agent-pane-zoom`

| Artifact | Path | Proves | Commit/package identity |
|---|---|---|---|
| RED screenshots/log | `baseline-fbe0b12ec\screenshots\` and `focused-red\` | Terminal zoom control works, agent Ctrl+wheel remains unchanged, plain wheel still scrolls | Exact Dev package from baseline `fbe0b12ec` |
| Focused test report | `baseline-fbe0b12ec\focused-red\` | Physical input reached verified HWND and failed only the agent zoom oracle | Exact Dev package from baseline `fbe0b12ec` |
| E2E identity report | `baseline-fbe0b12ec\identity\` | Source, AppX, installed layout, live process, HWND and pane bounds match | Exact Dev package from baseline `fbe0b12ec` |
| GREEN screenshots | future exact-publish evidence | Both pane types zoom and controls remain stable | Not started |
| Deterministic fixture log | `baseline-fbe0b12ec\fixture\` | Agent pane is live and plain wheel crosses ConPTY into WTA | Exact Dev package from baseline `fbe0b12ec` |

- 列出 ignored screenshots、pane captures、fixture logs、test reports、local harness、scripts、
  wire captures 和 provider configurations，并说明每个 artifact 证明哪条 contract。
- 不因文件 ignored 就删除它们；保留用于复现、review follow-up 和后续 framework extraction。
- 若 evidence 不需提交，保留 ignored 状态，并在此记录 path、command、identity、result 和结论。

## Completion Checklist

- [ ] 所有必填 placeholder 已替换；不适用章节已删除。
- [ ] Active task checklist 已清空；没有不冲突的插问导致workflow提前结束。
- [x] Exact baseline 已 build/deploy，并在预期 behavioral oracle 上 RED。
- [ ] Focused regression 先 RED 后 GREEN。
- [ ] Neighboring tests、full relevant suite、explicit build 和 static analysis 已完成。
- [ ] Publishable 与 dev-only commits 边界清晰。
- [x] Exact publish HEAD 已 build/deploy，source/deployed hashes 一致。
- [ ] Packaged/deployed E2E 对 exact publish binary GREEN。
- [ ] 真实外部依赖验收已完成，或明确标记 blocked。
- [ ] Simulated real-user E2E包含真实外部操作、严格结果分类、完整cleanup和exact identity evidence。
- [x] Token-consuming harness和evidence保持local-only，publish branch与CI均不包含或调用它们。
- [x] UI/渲染/交互的 fresh screenshots 已逐图检查并记录 provenance。
- [ ] Review findings 已逐条 triage，accepted fixes 有 RED/GREEN evidence。
- [ ] Visible、file-level和suppressed findings全部完成critical triage。
- [ ] Spelling conclusion、annotations和warnings全部完成critical triage。
- [ ] 所有active comments保持unresolved，等待用户review。
- [ ] PR title/summary/validation满足word limits，其他sections为空或concise。
- [ ] Agent未merge PR到`main`。
- [x] Evidence inventory 能映射全部 user-visible assertions。
- [ ] Dev 与 publish remote heads 已 push 并确认。

## Optional Follow-Ups

- After baseline RED, add the smallest ownership-nearest unit/source test before product implementation.
- After focused GREEN, decide whether the reusable physical wheel helper belongs in publishable `test\e2e` or remains dev-only pending a separate harness PR.

只记录不属于当前 contract 的后续工作，并为其使用独立 issue、branch 或 PR。

以下是本项目的legacy guide。仅供参考，请以实际代码为准：

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
- **Session MCP** exposes `run_command_in_current_shell`, `create_workspace`,
  `delegate_task_in_new_workspace`, and `request_user_input`.
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

Use `WTA_LOG=debug` or `WTA_LOG=trace` for additional Rust tracing. See
`tools/wta/README.md` for current diagnostics and CLI usage.

## Focused design references

- Multi-window helper/master lifecycle:
  `doc/specs/Multi-window-agent-pane.md`
- Session tracking: `doc/specs/hybrid-agent-session-tracking.md`
- Security boundaries: `doc/security-model.md`
- Installer: `doc/building-installer.md`
- WTA customization: `tools/wta/CUSTOMIZATION.md`
