# Default-provider Yolo mode 开发与交接

> 本节是新 Yolo UX feature 的 dev-only 事实来源。它只记录当前产品合同、
> scope、TDD计划和worktree纪律，不进入publish branch。通用仓库说明保留在后半部分。

## Current Stage

`2026-09-03`: 产品行为和最小scope已经讨论完成。Dev与publish均基于
`origin/main@b361d91b25dda4b455a7f58ca04909c90f56bae3`。
尚未修改产品代码、测试或resources，尚未build、commit或push。
本文已完成旧feature清理，并记录pre-push、PR metadata、parallel review/E2E和
user-owned comment resolution规则。下一步：停下，等待用户明确授权进入
deterministic RED阶段。

## Branches And Worktrees

- Primary dev:
  `user/DinahK-2SO/yolo-mode-next-dev` /
  `C:\ado\intelligent-terminal-bugfix`.
- Clean publish:
  `user/DinahK-2SO/yolo-mode-next-publish` /
  `C:\ado\intelligent-terminal-yolo-next-publish`.
- Pull request: not created.
- Tracking issue: not assigned.

`AGENTS.md`只属于dev worktree。Publish worktree不得包含本文件、本地harness、
真实provider prompt、raw logs、screenshots、provider homes或ignored evidence。

## Working Rules

1. 每次开始工作先更新`Current Stage`、branch/head、最新`origin/main`和下一条命令。
2. 每个独立root cause先有确定性的RED；首次production edit后立即重跑同一focused check。
3. PR修改尽可能小。除本文明确行为外，不增加provider-specific特殊处理。
4. 共用逻辑放在owning abstraction；不要把一次性判断散落在Settings、`/agent`
   和provider adapters。
5. Publish/CI测试不得调用真实模型。真实provider验证只能进入ignored本地evidence。
6. UI、安全边界或真实provider行为变化后，从exact publish candidate重新
   build/deploy并验证source、recipe、staged、installed和live identities。
7. 不得使用`Remove-AppxPackage`；不得自动登录、切换GitHub账号或修改credentials。
8. 发现相邻问题先记录并讨论，不顺手扩大scope。

## GitHub Identity Gate

每个新的Copilot session在调查、开发、build/test或线上GitHub操作前：

1. 从Copilot/VS Code账号界面确认Copilot账号以`_microsoft`结尾。
2. 运行`gh auth status --hostname github.com`和`gh api user --jq .login`。
3. Active `gh`账号必须是社区账号，且不得以`_microsoft`结尾。
4. 两个认证面分别确认；只记录账号名和时间，不记录token、cookie或account ID。
5. Session重启、账号变化或认证失败后重新执行完整门禁。

## User-visible Goal

Settings中的persisted Yolo toggle只负责**默认agent provider的自动Yolo**。
使用默认provider启动的agent panes保持现有主流程；用户通过`/agent`切换到
非默认provider时，不继承该自动设置。

这不是新的permission system：

- WTA仍只调用reviewed、provider-advertised native session capabilities。
- Provider定义的permission、sandbox、file和network效果不变。
- WTA不替用户选择ACP permission option。
- Product-owned terminal action proposals仍然需要用户确认。

## Locked Product Contract

### Persisted setting

- 保留现有key、boolean类型和默认值：

  ```json
  "agentPane.yoloMode": false
  ```

- 不增加schema migration或per-provider settings map。
- 在Copilot、Claude、Codex和Gemini之间更换Settings默认provider时，
  保留当前toggle值。
- `/agent`不修改persisted toggle。

### Settings provider matrix

| Settings default | Toggle | Persisted behavior | Message |
| --- | --- | --- | --- |
| Copilot | Enabled unless policy blocks | Preserve | No Copilot-specific Settings message |
| Claude | Enabled unless policy blocks | Preserve | None |
| Codex | Enabled unless policy blocks | Preserve | None |
| Gemini | Enabled unless policy blocks | Preserve | Info only while toggle is On |
| OpenCode | Off and disabled | Set draft to `false`; Save persists `false` | Unavailable warning |
| Custom | Existing behavior | No new special handling | No new Yolo message |

OpenCode是本feature唯一的provider-specific forced clear：

- 在Settings选择OpenCode时立即把draft设为`agentPane.yoloMode=false`。
- Toggle显示Off且不可开启；Save后磁盘值也是`false`。
- 切回其他provider仍保持Off，用户必须重新显式开启。
- Legacy `acpAgent=opencode`加`agentPane.yoloMode=true`在runtime和Settings中按Off处理。
- 打开Settings时把legacy组合规范化到draft；用户下次Save时写回`false`。
- 不能仅因application startup加载该legacy组合就后台改写用户文件。

Gemini保持conditional：

- Toggle不灰掉。
- 仅在Gemini被选中且toggle On时显示现有workspace trust信息。
- Gemini只在自己的workspace trust和provider policy允许时启用native mode。
- Intelligent Terminal不写Gemini trusted folders，也不绕过provider policy。

Custom provider不增加任何判断、disabled状态、message或capability classification。

### Group Policy

`AllowYoloMode=0`必须清除实际设置，而不只是clamp effective value：

- Toggle显示Off且disabled，并显示现有organization-policy提示。
- 内存和`settings.json`中的`agentPane.yoloMode`都设为`false`。
- 所有live sessions reconcile到native Off，包括非默认provider和手动enable的session。
- Unknown/unconfirmed disable继续fail closed。
- Policy解除后不恢复旧On值；用户必须重新开启。
- Policy blocked期间外部写入`true`不能改变runtime/UI；下一次settings write规范化为`false`。

Policy UI优先级最高；blocked时不同时显示OpenCode或Gemini notice。

### Automatic runtime inheritance

Settings-owned automatic Yolo使用一个统一规则：

```text
automatic Yolo =
    policy allows Yolo
    AND persisted toggle is On
    AND current session provider ID equals the Settings default provider ID
```

- 按canonical provider ID比较；model变化不改变provider identity。
- Host和WSL中的同一canonical provider视为同一个provider。
- 每个新ACP session仍必须独立advertise并ACK exact native capability。
- Provider discovery、restore、generation fencing、timeouts和fail-closed逻辑继续由
  现有native Yolo coordinator拥有。

### `/agent`

- 切到canonical ID不同于Settings默认值的provider时，主动reconcile native Off；
  不能只是不发送On。
- Off达到known-safe结果之前不释放prompt gate。
- 切到Settings默认provider时，应用persisted toggle并等待native ACK。
- 只切model不改变Yolo inheritance。
- Host/WSL同provider保留inheritance，但新session仍需fresh capability和ACK。
- Provider-owned manual `/config`保持session-scoped，不修改Settings toggle。
- Copilot ACP permission regression继续只在runtime处理；Settings不增加version UI。

### Existing tabs after Settings default changes

- Default-following tabs保持现有行为：retire旧ACP session并rebind/recreate到新默认provider。
- `/agent` override tabs保留当前provider。
- 对这些override tabs重新计算automatic Yolo：
  - provider现在等于新默认值时，继承persisted toggle；
  - provider不再等于默认值时，主动reconcile native Off。
- 对应operation settle前保持prompt gate。

## English UI Copy

### Toggle

- Header:
  `Use Yolo mode for the default agent provider`
- Help:
  `Requests Yolo mode when an agent pane starts with the default provider. The provider defines which confirmations, sandbox restrictions, file access, and network access change. Switching providers in an agent pane does not turn Yolo mode on for a non-default provider.`

### OpenCode

- Title:
  `Yolo mode isn't available for OpenCode`
- Message:
  `OpenCode doesn't provide a supported Yolo mode, so this setting is turned off and unavailable.`
- Severity保持`Warning`；InfoBar不可关闭。
- 只要Settings默认provider是OpenCode就显示，用于解释disabled toggle。

### Gemini

- 保留title:
  `Gemini Yolo mode depends on workspace trust`
- 保留message:
  `Gemini enables Yolo mode only when its workspace trust and provider policy allow it.`
- Severity保持`Informational`；InfoBar不可关闭。
- 仅Gemini加toggle On时显示。

### Policy

复用现有标准message：
`This setting is managed by your organization.`

不为Copilot临时upstream defect或custom provider增加Settings copy。

## Scope

### In scope

- Toggle header/help copy。
- OpenCode forced-Off/disabled行为和warning。
- Gemini现有conditional info行为。
- `AllowYoloMode`清除实际stored setting。
- `/agent`的default-provider-scoped automatic Yolo。
- Settings默认provider变化时重新计算现有`/agent` override tabs。
- 对应focused tests、localization和exact-package validation。

### Out of scope

- Custom provider特殊处理。
- 将inheritance规则接入profile `agentPaneBackend`、saved-layout restore、
  historical-session resume或其他非`/agent` override来源。
- Provider-owned trusted-folder UX或配置写入。
- 新provider mapping、provider negotiation或WTA-owned `/yolo`。
- ACP permission selection或terminal-action confirmation改变。
- Copilot permission regression的Settings UI。
- JSON key重命名或per-provider persistence。
- 不相关的Yolo、sandbox或COM authorization工作。

Publish文档只描述已实现的default-provider和`/agent`合同，不发布future gap列表。

## Modularization And Ownership

不要在`OnAgentSwitchRequested`中内联一组特殊判断。创建一个小型、无副作用、
可复用的inheritance decision abstraction，输入：

- persisted Yolo preference；
- policy state；
- Settings default provider ID；
- current binding/provider ID。

它只返回Settings-owned automatic desired state。当前PR仅连接Settings/default
launch/rebind和`/agent`路径；未来其他入口可直接复用。

| Area | Owner |
| --- | --- |
| Settings toggle/provider notices | `TerminalSettingsEditor/AIAgentsViewModel.*` |
| Built-in provider UI metadata | `src/cascadia/inc/AgentRegistry.h` |
| Persisted setting/policy model | `TerminalSettingsModel/GlobalAppSettings.*` |
| Policy read/watch/hot reload | `src/cascadia/inc/AgentPolicy.h`, TerminalApp watcher |
| Tab binding/default provider/`/agent` | `TerminalApp/TerminalPage.cpp`, `Tab.h` |
| Runtime config wire | agent-ready config, `agent_config_changed`, rebind payload |
| Runtime desired state/prompt gates | `tools/wta/src/app_contracts/yolo.rs`, `app.rs`, `app_events.rs` |
| Native provider transition | `tools/wta/src/protocol/acp/native_yolo.rs` |
| Settings resources | `TerminalSettingsEditor/Resources/**/Resources.resw` |

Host决定Settings preference是否适用于某个tab；Rust coordinator决定exact provider
session如何到达并ACK该状态。

## TDD Plan

Production edit之前为每个独立root cause建立deterministic RED：

1. **Settings**
   - Supported provider change保留toggle。
   - OpenCode清除draft并disabled。
   - Legacy OpenCode+On在Settings Save规范化，不在startup后台写。
   - Gemini保持enabled且只在On时显示info。
   - Custom行为不变。
   - Policy block清除实际stored value。
2. **Inheritance decision**
   - Default provider继承On；non-default为Off。
   - Canonical ID忽略model和Host/WSL source。
   - Policy始终为Off。
3. **`/agent` lifecycle**
   - Default到non-default在first prompt前完成disable。
   - Non-default到default等待enable ACK。
   - Failed/unknown disable保持prompt gate。
   - Manual provider config不写persisted toggle。
4. **Hot Settings default**
   - Default-following tabs按现有行为rebind。
   - `/agent` override tabs保留provider但双向重新计算Yolo。
5. **Policy**
   - Startup/live block持久化`agentPane.yoloMode=false`。
   - 所有live sessions Off；解除policy不恢复On。
6. **UI/localization**
   - Header/help、OpenCode disabled/message、Gemini conditional info和policy优先级。
   - 所有real/pseudo locales key parity；只翻译`<value>`，`<comment>`与en-US一致。

首次实现edit后立即运行同一RED selector。Focused GREEN后才运行neighboring/full suites。

## Validation Gates

- SettingsModel focused tests：persistence、policy、provider notice matrix。
- TerminalApp LocalTests：binding/default-provider和`/agent` routing。
- Focused WTA Yolo/agent-switch tests，使用deterministic ACP barriers，不用sleep。
- Full explicit-target WTA：

  ```powershell
  cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
  ```

- C++/XAML/resource改动后的SettingsEditor和TerminalApp builds。
- 所有修改`.resw`的XML/BOM/EOL/comment/key-parity检查。
- Publishable zero-token Settings加deterministic ACP `/agent` package E2E。
- Policy package case仅在provisioned机器运行；缺少policy-write ACL记为`BLOCKED`。
- Real-provider acceptance如有需要只能local/ignored，不能进入`test/e2e`或CI。
- Exact publish candidate build/deploy/freshness。
- Dev/publish产品tree在本文件和ignored evidence之外必须一致。

## Publish Discipline

- 只在`C:\ado\intelligent-terminal-bugfix`开发和维护本handoff。
- `C:\ado\intelligent-terminal-yolo-next-publish`保持clean，直到自包含commit通过review。
- 只复制publishable commits；不得复制本文件或本地evidence。
- Focused/full source validation与exact-package build/deploy/freshness达到可信状态后
  可以push；broader local E2E在PR创建后与online review并行。
- 未经明确授权不得rewrite inherited history或force-push。
- `origin/main`前进时，final package evidence前先audit并integrate。

## PR Creation And Review Workflow

### Push confidence gate

当publish branch达到足够可信状态后，不必等待全部broader local E2E完成：

1. Require clean tracked publish state and current audited `origin/main` ancestry.
2. Require no `AGENTS.md`、local harness、real-provider prompt、raw evidence或其他
   dev-only path进入publish diff。
3. Require deterministic RED-to-GREEN、focused/neighboring tests、full relevant source
   suites和format/diff checks通过。
4. Require exact publish candidate build/deploy/freshness通过，测试binary与candidate
   HEAD一致。
5. 使用ordinary push发布publish branch；不得force-push。

### PR metadata

Push后创建PR并保留`.github/PULL_REQUEST_TEMPLATE.md`的结构：

- PR title不得超过20个words。
- `## Summary of the Pull Request`不得超过100个words。
- `## Validation Steps Performed`不得超过100个words。
- 其他sections没有适用内容时可以留空；如填写，必须尽量concise且准确。
- 不得把尚未运行、blocked或失败的validation写成PASS。
- PR body只描述publish中实际实现的behavior，不公开dev-only future gap列表。

### Parallel online review and local E2E

PR创建后立即并行推进：

- Online checks、Copilot review和其他reviewers在published HEAD上运行。
- 本地从同一exact published HEAD运行broader package/UI/real-provider E2E。
- 检查spelling workflow的conclusion、annotations和相关log summary；绿色check也可能
  包含需要判断的content annotations。
- 每次publish HEAD变化后，重新确认线上review/check对应的SHA；需要新package
  evidence时从新HEAD重建。
- Local E2E发现的问题先记录、分类并构造deterministic RED，再决定是否修复。

### Critical review triage

持续monitor线上checks、reviews和所有active comments。Review inventory必须同时包含：

- 所有visible inline/file-level comments和active threads。
- Copilot每个相关review object的完整body，包括suppressed comment/finding sections。
- Review summary中的generated/suppressed counts；`0` visible comments不能证明没有
  suppressed finding。
- Spelling check的全部annotations，而不只是check conclusion。

对每条visible、suppressed或spelling finding独立判断：

1. 核对comment针对的exact SHA、代码路径和当前实现。
2. 用现有contract、可复现behavior、tests和安全边界验证其claim。
3. 分类为valid fix、duplicate/already addressed、out of scope或incorrect，并在
   dev-only handoff记录理由和证据。
4. Valid finding先建立deterministic RED，再做最小fix、验证并push新的publish commit。
5. 不因为comment来自自动reviewer就直接接受，也不因为后续代码碰巧改变相关行就
   直接忽略。

Spelling findings必须区分repository content问题与external dictionary/network、
generated-file或workflow infrastructure warning。优先修正文案；不要未经项目惯例
支持就添加dictionary allowlist或宽泛ignore pattern。

### User-owned merge and comment resolution

- Agent不得把PR merge到`main`。
- Agent不得resolve、dismiss、close或以其他方式关闭任何active review
  comment/thread。
- 即使某条comment已在后续iteration修复、变成duplicate或代码行变为outdated，
  也必须保持其active状态，供用户亲自review和resolve。
- 不得调用GraphQL、REST、CLI或UI操作修改active thread的resolution state。
- 使用review-loop脚本时，所有reply必须保持`-NoResolve`语义；不得运行会resolve
  thread的模式，也不得运行outdated-thread cleanup。
- 可以实现并push必要fix，也可以在需要时留下包含commit SHA和证据的reply，
  但reply不能resolve thread。
- Review loop的完成条件不是`open threads = 0`。当current HEAD已有review、
  checks settled、所有comments均完成critical triage且valid fixes已push后即可停止；
  active comments继续保留给用户。
- PR merge和active comment resolution均由用户最终执行。

## Completion Checklist

- [x] Product behavior和minimal scope已确认。
- [x] Dev/publish worktrees来自同一`origin/main`。
- [x] 旧feature branch、review、evidence和test进度已从当前handoff清除。
- [ ] 每个root cause有deterministic RED。
- [ ] Owning abstractions中的minimal implementation完成。
- [ ] Settings、policy、`/agent`和prompt-gate focused suites GREEN。
- [ ] 修改的locales全部通过结构和语义验证。
- [ ] Full WTA及相关C++ builds/tests GREEN。
- [ ] Pre-push exact publish candidate build/deploy/freshness GREEN。
- [ ] Dev/publish product trees和commit slices验证完成。
- [ ] Publish中没有dev-only artifact或real-provider prompt。
- [ ] Publish branch ordinary-pushed并创建符合word limits和template的PR。
- [ ] Online review/checks与同HEAD local E2E并行完成。
- [ ] Publishable zero-token package E2E与所需local-only E2E GREEN或明确BLOCKED。
- [ ] Visible、file-level和suppressed review findings全部完成critical triage。
- [ ] Spelling conclusion、annotations和相关warnings全部完成critical triage。
- [ ] 所有valid review/spelling fixes已验证并push。
- [ ] 所有active comments保持unresolved，等待用户review。
- [ ] PR未被agent merge到`main`。


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
