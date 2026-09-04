# Copilot ACP Yolo-Off Investigation

> 本节是当前调查的dev/test-only事实来源。它只定义Copilot ACP在Yolo Off时的安全行为、
> TDD分支纪律和本地真实provider验证；不得混入暂停中的default-provider Yolo UX PR #828。

## Current Stage

`2026-09-04`: 用户暂停#828，PM正在重新评估OpenCode选择后将Yolo toggle强制Off并
disabled的行为。当前调查从latest
`origin/main@1f694b3790d47d820e6c1c8240ea421bb0a31df1`独立开始；该main已包含
provider-native Yolo、github/copilot-cli#4537的Copilot fail-closed保护，以及#833的
spawn-time helper identity改进。尚未修改产品代码、测试或provider配置，尚未build/deploy
或发送真实模型prompt。

已创建并push两个同base分支：

- Dev: `user/DinahK-2SO/copilot-acp-yolo-off-dev` /
  `C:\ado\intelligent-terminal-bugfix`
- Test: `user/DinahK-2SO/copilot-acp-yolo-off-test` /
  `C:\ado\intelligent-terminal-copilot-acp-yolo-off-test`

Test branch只形成test-first regression、direct ACP probe或dev-only investigation commit；
Dev branch在RED和root cause明确后接收对应test commit及最小产品fix。目前不创建publish
branch，也不创建PR。TDD support来源固定为
`user/DinahK-2SO/local-tdd-kit@01edfdd0edadf1b3947bb373055eec5f1c82c926`，
两worktree的ignored copy位于`.local-tdd-kit-run\kit`，本调查evidence写入
`.local-tdd-kit-run\artifacts\copilot-acp-yolo-off`。

TDD kit在ignored copy位置首次selftest暴露hardcoded `local-tdd-kit` source probe，
准确RED `34/1`；support branch改为location-independent `src` probe并push为上述commit。
Canonical build/deploy selftests为`19/19`，重新复制后的dev ignored kit full Unit为
`35/35`；两个worktree均由local Git exclude隐藏且0个kit文件被track。下一步仅做baseline：
记录installed Copilot CLI版本和Terminal解析出的exact ACP command，运行现有deterministic
Copilot Yolo permission tests；然后从latest main exact package build/deploy/freshness。
完成这些前不得运行真实prompt或编辑产品。

用户提供的exact pre-#505 baseline是已安装Store package
`Microsoft.IntelligentTerminal_0.2.2433.0_x64__8wekyb3d8bbwe`。原bundle为
`C:\Users\xiaomgao\Downloads\Microsoft.IntelligentTerminal_0.2.2433.0_8wekyb3d8bbwe.msixbundle`，
59,198,930 bytes，SHA-256
`2BF9CB7CBB96C141EB2EC3C0CB4F799A0CD721D473AF2E1C0B888A449FE94FBA`；x64 MSIX
SHA-256 `0C2468A90008B4564460CF939188CFCF8CC0D50E1FD7618CA1B00D0CEF325EFE`。
WindowsTerminal/wtcli product version是`0.2.260831003-experimental`，证明build date为
2026-08-31，早于#505 merge `b361d91b@2026-09-03T18:54:35+08:00`；packaged WTA
SHA-256 `62CC4A266B24E89BC1E32818A7D2E9DD26DE5021DCA388AF1E214A6B257844A4`且
`wta --help`中没有Yolo或allow-all host option。

当前resolved `copilot.exe`报告`GitHub Copilot CLI 1.0.83-5`，SHA-256
`58D0104D82408863523AF74D4405FA0CDD71060DB29A56155FD78181BF264ACF`。用户说明在上述
Store package中先通过manual `/allow-all off`和`/config`关闭Yolo；随后相同marker shell
prompt显示`[Y] Allow once / Always allow / [N] Deny` permission UI，tool尚未获准执行。
Evidence：
`.local-tdd-kit-run\artifacts\copilot-acp-yolo-off\manual-pre-yolo-pr-copilot-1.0.83-5-permission.png`，
SHA-256 `AB262E0E8A5424F8B6045A321EC142CE0AEC793611B230C70A90B007735BEF4D`
（1900x727）。这证明exact pre-PR binary上的manual Off path可进入permission flow，并表明
当前open-ended `1.0.81-1+`假设可能过宽；但仍未证明ACP
`session/set_config_option(off)`与slash command走同一路径，也未完成permission
cancelled后marker不存在的自动oracle。下一步用同一个Copilot binary/hash做direct ACP对照。

## Identity And Online Boundaries

- 本Copilot session继续使用已确认的Microsoft内部账号；active `gh`已重新验证为社区账号
  `DinahK-2SO`。两个认证面独立，任何账号变化后重新执行完整门禁。
- 除非调查确实需要并经用户确认，不得使用`DinahK-2SO`账号回复任何线上thread。
- 不修改、push、merge或触发#828的新review，不resolve/reopen其comments。
- 本调查没有tracking issue或PR；不得为了记录本地结果创建线上comment。

## Investigation Goal

判断**当前安装的GitHub Copilot CLI ACP server**在exact session已确认
`allow_all=off`后，是否重新可靠地执行普通ACP permission flow。

当前main的产品保护是：

1. Copilot的native Yolo capability必须是category `permissions`中的exact
   `allow_all` Select contract，On=`on`、Off=`off`。
2. `tools/wta/src/protocol/acp/native_yolo/providers/copilot.rs`把
   `1.0.81-1`及更高版本、未知版本和无法解析版本视为受
   github/copilot-cli#4537影响。
3. 对受影响版本，只要exact session的acknowledged state是Off，WTA在ACP send boundary
   前阻止prompt；即使global Yolo仍On但用户手动`/config allow_all=off`也必须阻止。
4. 该open-ended version gate只能在一个later Copilot release通过真实denied-permission
   probe后缩小或移除。Config ACK、UI显示Off或agent文字声明均不能证明上游已修复。

本调查必须回答：

- 当前实际`copilot`版本和Terminal解析出的ACP stdio command是什么？
- `session/new`是否仍advertise exact `allow_all` on/off contract？
- 对startup/default Off和On→manual Off两条路径，config update是否被exact session ACK？
- 在绕过WTA产品保护的direct ACP probe中，工具调用前是否出现
  `session/request_permission`？
- 不选择permission option时，Copilot是否仍能执行shell tool或产生文件副作用？
- 如果当前版本安全，最小产品变化应是加入哪个verified upper boundary，而不是删除所有
  unknown/future-version fail-closed behavior？

## Causality Proof

“Yolo PR merge前手动`/allow-all on`→`/allow-all off`可以正常询问权限”是重要control，
但不能单独证明ACP config path安全。Copilot自己的slash command和ACP
`session/set_config_option`可能走不同permission-policy实现。

当前用户截图已把该control具体化到exact Store `0.2.2433.0`和Copilot `1.0.83-5`，
因此调查不得再笼统声称所有`1.0.81-1+`场景都已知UNSAFE。它当前可标记为
`manual slash Off = permission request observed on exact pre-#505 binary`；完整SAFE仍要求
拒绝permission后marker不存在。

结论必须建立在以下同版本矩阵上：

| Layer | Required control | What it proves |
| --- | --- | --- |
| Copilot TUI/slash | 同一CLI binary执行manual `/allow-all` Off并拒绝permission | Copilot交互TUI permission engine是否健康 |
| Direct ACP | 同一binary用Terminal exact `copilot --acp --stdio` command、set Off ACK后prompt | 不经过WTA时ACP path是否独立复现 |
| Pre-#505 product source | `41f9754e2865c7526a2b76730c2b4b1a4ac4c27a`或其exact package | merge前产品行为与wire baseline |
| #505/current product | `b361d91b25dda4b455a7f58ca04909c90f56bae3`及latest main | Yolo integration是否发给错误session、漏等ACK或自动回答permission |

所有对照必须固定Copilot executable path、full version和binary hash；旧产品+旧CLI与新产品+
新CLI不能用于归因。Direct ACP client必须正确处理JSON-RPC request ID `0`，并在收到
`session/request_permission`时明确返回`cancelled`。

若同一binary表现为TUI/slash SAFE但direct ACP UNSAFE，则可证明底层root cause在Copilot
ACP permission path；同时必须承认#505通过Settings首次让用户触发该advertised ACP config
path，因此它暴露了用户可见回归，Intelligent Terminal仍负责fail closed。只有direct ACP
SAFE、exact-session ACK正确且product matrix无routing差异时，才可讨论缩小version gate。

## Safety Oracle

对唯一disposable marker文件使用每轮随机path和marker。真实prompt要求Copilot使用自己的
shell tool创建该文件、读回并只回复marker；测试绝不点击或自动选择permission option。

- **SAFE / candidate upstream fix:** `allow_all=off`已经ack；Copilot在tool execution前发送
  `session/request_permission`，且在用户未选择permission时marker文件不存在。Provider
  明确拒绝tool、无副作用也可作为安全结果，但必须记录wire evidence。
- **UNSAFE / regression remains:** 没有permission request，Copilot仍执行tool或marker文件
  出现。Agent返回marker文字但没有真实文件不算tool execution成功。
- **INCONCLUSIVE:** auth/model/quota failure、ACP command错误、capability缺失、timeout、
  harness未捕获完整wire、WTA产品guard提前阻止prompt或cleanup失败。不得把这些结果写成
  SAFE或UNSAFE。

必须区分两层：

1. **Product baseline:** exact main package应继续在受影响版本的Off state阻止prompt，证明
   Intelligent Terminal保护没有退化。
2. **Provider probe:** dev/test-only harness直接连接Terminal实际使用的Copilot ACP stdio
   command，完成initialize/session/new/config update/prompt，绕过WTA version guard，才能
   判断上游provider本身是否修复。

## Scope

### In scope

- Current Copilot CLI/ACP version、command、initialize和session capability inventory。
- `allow_all=off` startup state及On→manual Off state的ACK和permission behavior。
- Direct ACP denied-permission probe、exact package product-block negative control。
- 若真实probe证明修复：Copilot version boundary、对应deterministic tests和spec limitation。
- Exact package build/deploy/freshness及同HEAD zero-token/product/live validation。

### Out of scope

- #828的default-provider inheritance、OpenCode disabled UI或其他Settings UX。
- Claude、Codex、Gemini、OpenCode或custom provider行为变化。
- ACP permission option自动选择、trusted-folder、sandbox或provider-owned policy修改。
- Copilot CLI升级、降级、重新登录或credential修改，除非用户另行批准。
- 新provider mapping、session hooks、history/resume、MCP或terminal-action proposal变化。
- 没有真实SAFE evidence时删除或放宽fail-closed保护。

## Ownership And Key Files

| Concern | Owner |
| --- | --- |
| Copilot native config contract/version gate | `tools/wta/src/protocol/acp/native_yolo/providers/copilot.rs` |
| Exact per-session capability and acknowledged state | `tools/wta/src/protocol/acp/native_yolo.rs` |
| Final prompt dispatch gate | `tools/wta/src/protocol/acp/client.rs` |
| Deterministic ACP behavior tests | `tools/wta/src/protocol/acp/mock_agent_tests.rs` |
| Version/contract tests | `tools/wta/src/protocol/acp/native_yolo_tests.rs` |
| Terminal ACP command resolution | `src/cascadia/inc/AcpModelUtils.h` |
| Product contract | `doc/specs/Yolo-mode.md` |
| Local live harness/evidence | `.local-tdd-kit-run\artifacts\copilot-acp-yolo-off` |

Hypothesis:

```text
Copilot ACP session advertises allow_all=off
  -> current version may still execute provider-owned tools without session/request_permission
  -> WTA's exact-session disabled_prompt_block_reason prevents prompt dispatch
  -> a verified safe release can narrow the version gate, but only for that proven range
```

## Branch And Evidence Discipline

- Test branch先建立RED和probe evidence；在root cause确定前不编辑production。
- Dev branch只接收自包含test commit和经用户同意的产品fix；不要直接merge整个test branch。
- Real-provider prompt、ACP wire capture、provider home/config、raw logs和screenshots全部
  local-only/ignored，不得commit、push或进入CI。
- Deterministic mock tests、若最终需要的version-boundary regression和直接相关spec可以成为
  publishable内容；当前没有publish branch，用户决定修复后再创建。
- 不使用`Remove-AppxPackage`。替换Dev loose-package registration必须保留LocalState。
- 只停止executable path精确属于本调查build/package的PID，不按process name全局终止。
- 测试前逐字节备份settings/state和已有marker；`finally`恢复并验证无backup marker、
  provider/package process或测试文件残留。

## TDD Plan

1. **Environment inventory**
   - `copilot --version`和executable path。
   - 从`AcpModelUtils.h`及实际launch log确认exact ACP command。
   - 只记录版本/path/command shape；不记录token、cookie、account ID或provider home内容。
2. **Existing deterministic baseline**
   - `copilot_permission_regression_version_boundary_is_fail_closed`
   - `copilot_permission_regression_blocks_prompt_when_yolo_is_off`
   - `copilot_permission_regression_blocks_acknowledged_off_with_global_on`
   - `copilot_last_good_permission_version_keeps_prompt_path_available`
3. **Exact main package baseline**
   - 从`1f694b379` build/deploy/freshness。
   - 使用zero-token fixture证明Off state的config ACK和WTA prompt block仍生效。
4. **Direct ACP provider RED/SAFE probe**
   - initialize并创建独立session。
   - 验证exact `allow_all` contract，显式set Off并等ACK。
   - 发送唯一marker prompt，不回答permission。
   - 同时断言wire request、tool event、文件side effect和最终response。
5. **Negative/control matrix**
   - Fresh session/default Off。
   - On ACK后再Off ACK。
   - Product package blocked-prompt control。
   - 只有在安全且额度允许时执行On control；它不能替代Off probe。
6. **Decision**
   - UNSAFE：保留open-ended gate，不改产品；记录新版本evidence。
   - SAFE：先增加当前版本的deterministic boundary RED，再做最小version-range fix。
   - INCONCLUSIVE：修复probe或报告环境block，不编辑产品。

## Validation Gates

- Focused:

  ```powershell
  cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml copilot_permission_regression -- --nocapture
  ```

- Neighboring Copilot/native Yolo tests and prompt-dispatch mock tests。
- Full WTA:

  ```powershell
  cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
  ```

- Rust format/diff check；若C++ command resolution改变则build owning C++ project。
- Exact package build/deploy/freshness；explicit-target WTA、recipe、AppX、installed和live hashes一致。
- Product zero-token test与direct real-provider probe必须分别报告，不能互相冒充。
- 每个结果记录full HEAD、Copilot version、ACP command identity、session/config ACK、permission
  request count、tool side-effect count、marker state、cleanup和artifact path。

## Completion Criteria

- [x] Test/dev branches和TDD copies已从同一latest main准备完成。
- [ ] Existing deterministic Copilot safety tests GREEN。
- [ ] Exact main package receipt/freshness GREEN。
- [ ] Current Copilot ACP command/version已确认。
- [ ] Startup Off和On→Off两条direct ACP probe均有SAFE/UNSAFE/INCONCLUSIVE结论。
- [ ] Product guard与provider behavior证据明确分离。
- [ ] 没有credential、real prompt、wire/log或provider config进入tracked diff。
- [ ] settings/state/marker/processes完整恢复。
- [ ] 只有在SAFE证据成立且用户批准后才创建产品fix和publish branch。

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
