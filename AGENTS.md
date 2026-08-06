# ACP Usage / Session Cost Feature Handoff

> Last synchronized: 2026-08-06
>
> 这个文件只描述 ACP usage / session cost feature。它应该可以直接复制到新的 dev branch，
> 让下一阶段不需要重新翻阅旧调查记录。实际代码始终是最终 source of truth。

我们已经完成这个feature的第一版，并通过 squash commit `a6e1f4c5b`
(`Show the token usage and cost (#512)`) 合并到 `main`。

新的 dev/publish branches:

- dev branch：`user/DinahK-2SO/usage-calc-fix-display`
- publish branch：`user/DinahK-2SO/usage-calc-fix-display-publish`

因为PR是squash merge，旧publish branch不一定会显示为`main`的ancestor，但产品代码已经进入
`main`。下一阶段不要继续基于这两个历史branch开发：请从最新`origin/main`开一个新的dev
branch，把本文件copy过去，并在这里记录新branch名称。

如果下一阶段仍使用dev/publish双branch：publish branch用于正式产品代码和code review，dev
branch还可以包含调查、tracking和本地workflow。上一个publish branch不包含：

- `AGENTS.md`
- `doc/`
- `build/scripts/New-LocalMsixInstaller.ps1`
- `test/e2e/selftests/LocalMsixInstaller.Unit.Tests.ps1`
- `test/e2e/selftests/UsageLocalization.Unit.Tests.ps1`
- 本地E2E framework、wire、provider config和未明确选入review evidence的截图

新的branch可以根据任务调整清单，但继续遵守同一个原则：publish只表达当前产品行为，dev可以
保留历史背景和本地workflow。

========================

## 在开始下一阶段正式开发前

如果下一阶段会改变provider launch、package、agent routing、Bottom Bar、Usage显示或session
管理，请先确认这些live acceptance仍然可以完成：

1. 使用遵守真实ACP wire contract的deterministic Claude和Codex mock；
2. build/deploy existing Intelligent Terminal并launch；
3. 截图并确认Terminal窗口visible且nonblank；
4. 点击Bottom Bar按钮展开agent窗口，截图并确认agent对话UI可见；
5. 选择Claude，截图并确认active agent确实切换为Claude；
6. 选择Codex，截图并确认active agent确实切换为Codex；
7. 回到Terminal，打开Session view，截图并确认session UI可见；
8. 若改变Usage功能，验证context-only、cost-only、both、absent、stale、malformed状态，以及
   tooltip、Automation HelpText和窄窗口布局。

Try to reuse existing tests. 现有framework无法覆盖真实用户操作时，可以在本地开发新的test
framework，但不要把大型新framework放进feature commit。做好modularization，使它未来可以
独立成为新的PR。

本地E2E framework、scripts、wire、provider configs和screenshots不要删除，即使它们被ignore。
需要commit的截图必须复制到非ignored的指定review-evidence目录，否则只在tracking中记录路径和
验证结果。

用PATH中解析到的`pwsh`（PowerShell 7+）做E2E。需要启动同一个host的子进程时，复用：

```powershell
(Get-Process -Id $PID).Path
```

不要硬编码本机PowerShell安装目录。

========================

## Strict Test Driven Development workflow

每一个behavior change必须按以下顺序：

1. 在现有framework中增加或修改最小test，建立RED；
2. 运行focused test，确认它因为预期原因失败；
3. 做最小GREEN implementation；
4. 立即重跑同一个focused validation；
5. 更新新branch的self-contained tracking note；
6. commit产品代码、合适的现有framework tests和tracking；
7. push dev branch；
8. 确认remote同步后才能开始下一个RED步骤。

若push失败、branch分叉或出现无法安全合并的远端提交，停止下一步，先解决同步问题。

注意做好modularization并reuse existing code。若现有架构在多个位置重复定义同类功能，feature
branch先follow existing ownership；大型架构refactoring留到独立branch。不要为了这个feature
创建平行的Usage state/event/UI route。

关于tests是否commit：现有framework能自然cover的tests应该commit；新的本地桌面E2E framework
只保留本地，未来另开framework PR。

========================

## 最终产品设计

### 用户看到什么

当agent提供数据、且用户打开setting时，Terminal Bottom Bar最多显示两个items，顺序固定：

1. Context-window usage；
2. Session cost。

两项互相独立：

- missing cost不能隐藏valid context；
- invalid context不能隐藏valid cost；
- 两项都不存在时整个Usage group隐藏。

不要显示：

- per-turn input/output/cache/reasoning token breakdown；
- account quota、remaining credits、reset time或plan allowance；
- 客户端自己计算的token price；
- 猜测的provider credits/model multiplier；
- unavailable数据的`N/A`、假`0`或placeholder。

### 当前英文copy

Title：

```text
Show context usage and session cost
```

Description：

```text
When available, show context-window usage and session cost in the terminal bottom bar.
```

`session cost`是故意保持generic和unit-neutral的用户文案。除非有新的产品决定和完整localization，
不要改回`billing`、`monetary cost`、`credits`、`AIC`或provider名称。

内部identifier由于兼容性继续保留旧名字：

- setting/API：`ShowTokenUsageAndCost`
- JSON key：`showTokenUsageAndCost`
- projection kinds：`context`、`billing`

不要只为了匹配display copy而rename这些identifier，除非同时设计migration。

### Toggle behavior

- Default：`false`。
- FRE和Settings -> AI Agents写同一个`GlobalAppSettings.ShowTokenUsageAndCost`。
- Toggle off隐藏context和cost，但不停止ingestion，也不清除cache。
- Toggle on立即从cache重新project，不要求agent重发Usage。
- Settings save/reload直接调用`_UpdateBottomBarState()`，不依赖
  `AgentPaneContent::ApplyAgentUsage` raise `StateChanged`。

### Context formatting

主栏显示：

```text
Context Window: <integer>%
```

规则：

- 使用最新`used / size` gauge，不跨turn相加；
- percentage取最近整数，`.5`向上；
- tooltip和Automation HelpText保留exact counts和percentage；
- `size == 0`、`used > size`、malformed或缺字段时隐藏context；
- gauge在compaction后可以下降；model/config变化后`size`也可以变化；
- context usage不是account quota，也不是session累计消耗。

### Cost formatting

主栏显示：

```text
<amount rounded half-up to 2 decimals> <reported unit>
```

规则：

- tooltip和Automation HelpText保留完整精度；
- 正数但小于`0.01`显示`<0.01 <unit>`；
- exact zero合法，显示`0.00 <unit>`；
- currency/unit按agent报告原样保留，不uppercase、不纠正、不转换；
- 不把reported value称为invoice或final bill。

### Snapshot merge语义

Context、cost和未来provider metrics是独立optional fields：

- 新context只替换context；
- 新cost只替换cost；
- missing field不擦除另一个valid field；
- session boundary清除该session的全部Usage；
- transport loss把已存在metric标记stale；stale保留在state但UI隐藏。

========================

## Feature内部数据流与ownership

只需要理解这条feature route：

```text
ACP SessionUpdate::UsageUpdate
  -> Rust normalize_standard_usage()
  -> AppEvent::UsageReported / UsageCleared
  -> owning TabSession merge + UsageStaleness
  -> agent_state_changed.usage JSON projection
  -> TerminalPage::OnAgentStateChanged routes by tab id
  -> AgentPaneContent / AgentUsage::TryUpdateCache
  -> TerminalPage::_UpdateBottomBarState renders active-tab Usage
```

Rust ownership：

- `tools/wta/src/usage.rs`：domain model、standard normalization、validity filtering、projection；
- `tools/wta/src/usage/providers/`：per-provider adapter framework；
- `tools/wta/src/protocol/acp/client.rs`：ACP ingestion和outer Usage event boundary；
- `tools/wta/src/master/mod.rs`：per-session forwarding和pending Usage coalescing；
- `tools/wta/src/app/tab_state.rs`、`app_events.rs`：per-tab cache、merge、clear、staleness；
- `tools/wta/src/app_status_projection.rs`：cross-process JSON projection。

C++ ownership：

- `AgentUsage.{h,cpp}`：strict JSON parser、containment、display formatting；
- `AgentPaneContent.{h,cpp}`：per-tab C++ Usage cache；
- `TerminalPage.cpp`：tab routing、settings refresh、active-tab Bottom Bar rendering；
- `TerminalPage.xaml`：`UsageGroup` slot；
- `MTSMSettings.h` / `GlobalAppSettings.idl`：persisted setting；
- `AIAgents.*`和`FreOverlay.*`：两个toggle entry points。

`ApplyAgentUsage`只有一个runtime caller：`TerminalPage::OnAgentStateChanged`。Caller在apply后负责
active-tab catch-all `_UpdateBottomBarState()`。不要重新在`ApplyAgentUsage`里raise
`StateChanged`，否则一个Usage event会同步刷新Bottom Bar两次。其他真正独立驱动Bottom Bar的
`StateChanged` producers继续有效。

========================

## Error handling、privacy与lifecycle

### Standard ACP normalization

ACP context counts是typed integers，不需要字符串解析。Optional cost只有finite且non-negative才
接受：

- invalid optional cost被省略；
- valid context继续保留；
- zero cost合法；
- chat turn保持成功。

### Future private parser errors

当前没有active private provider parser。未来新增时，parser error必须：

- 只省略该optional contribution；
- 只记录不含value/payload的schema-level warning；
- 不把已经成功的user turn变成error；
- 不泄漏credentials、billing data、prompt或raw payload。

Inner parser在tests里保持fail-fast；containment放在明确的feature boundary，不要散落try/catch。

### C++ cross-process containment

`AgentUsage::Parse`和`UpdateCache`是strict的，可以throw。唯一C++ containment boundary是
`TryUpdateCache(... ) noexcept`：

1. catch parser exception；
2. clear旧Usage cache，避免显示stale数据；
3. return `false`；
4. `OnAgentStateChanged` caller只log固定文字`invalid usage hidden`；
5. caller继续refresh Bottom Bar并隐藏Usage；
6. chat和agent connection继续运行。

下一条valid update会重新填充cache。

### Privacy

- Usage数值不能进入normal logs或telemetry；
- full ACP content只允许trace级，Usage values仍应redact；
- 不为这个feature读取provider credentials；
- raw provider logs、prompts、tokens、account info不能进入commit。

### Lifecycle

Clear Usage on：

- fresh `/new` session；
- helper/agent restart；
- explicit per-tab session reset；
- new/load identity boundary；
- invalid cross-process replacement payload。

Local chat-history clear在ACP session不变时不要清Usage。Model display变化也不清Usage，除非provider
报告replacement gauge。

Background-tab update只更新那个tab的cache；用户切到该tab时再刷新window-level Bottom Bar。

========================

## Provider decisions

我们调查过五个provider的真实response。最终产品只接受标准ACP直接报告的context/cost；当前五个
built-in provider modules全部是：

```text
PrivateUsagePolicy::StandardAcpOnly
trusted_reporter_ids = []
post_turn_commands = []
```

这描述当前实现，不是永久禁止private extension。未来若出现正式、machine-readable、经过真实
wire验证的contract，可以扩展对应provider module和tests。

### Claude

Verified behavior：标准ACP context gauge和session-cumulative USD cost。产品通过common path显示
两项。

当前产品launch在三个live owners中exact pin到：

```text
@agentclientprotocol/claude-agent-acp@0.59.0
```

三个owners：TerminalApp launch mapping、Settings model-probe mapping、Rust agent registry。

Pin是故意的：不写版本会让`npx`每天执行npm当天的`latest`，同一个IT版本在不同机器上可能运行
不同adapter，难以复现和review。不要仅为了升级而删除pin。

2026-08-05 external snapshot：

- Microsoft npm feed的`latest`是`0.63.0`；
- upstream GitHub latest release是`0.64.2`；
- `0.63.0`把ACP SDK从`1.2.1`升级到`1.3.0`，Claude Agent SDK从`0.3.207`
  升级到`0.3.220`；
- Node requirement仍是`>=22`；
- 新版包含context initialization、session/model latency、tool progress、terminal、permission和
  ExitPlanMode相关修复。

Follow-up应该先做完整compatibility test，再统一更新三个live owners、current docs和expectations。
历史capture确实使用`0.59.0`，不要全局替换历史文件。

External package inspection on 2026-08-05显示：adapter默认使用其exact Claude Agent SDK dependency
携带的平台Claude executable。用户全局安装的Claude/ACP adapter不会覆盖IT的pin；显式external
override是`CLAUDE_CODE_EXECUTABLE`。升级时应重新验证这个upstream behavior。离线且未cache exact
package时launch可能失败。

### Codex

Verified behavior：标准ACP context gauge；capture中没有monetary cost，因此当前只显示context。

Historical provider captures使用`1.1.2`；当前产品pin是`1.1.4`。不要把历史result文件里的
`1.1.2`全局替换。新的capture必须使用并记录current product pin。

### GitHub Copilot

GitHub Copilot CLI 1.0.78已经通过标准ACP报告context usage，但还没有trusted standard cost。
当前只显示context，不做任何Copilot-specific Usage处理。

Do not：

- send `/context`；
- send `/usage`；
- parse command output；
- 把`%USERPROFILE%/.copilot`、`events.jsonl`、checkpoint或`totalNanoAiu`当作usage/cost source；
- 根据request count、model metadata或multiplier推算AIC/AI Credits。

背景：我们早期验证过command不消耗额外tokens，也做过command/local-ledger prototype。但
`/usage`不能给产品可信cost，`/context`在标准ACP context出现后不再需要，而user-folder schema
不是supported usage/cost contract，所以这些usage/cost product paths已经全部删除。Session
history/watcher代码可能仍为独立的session-management功能读取Copilot文件；不要误删，也不要把它
复用为Usage source。

Per-provider framework保留。Publish code应该看起来像这些superseded特殊处理从未引入过。这不是
隐瞒历史，而是降低reviewer认知负担。不要用tests/comments永久force或ban未来hypothetical
Copilot extension。若未来有正式contract，把contract、implementation和focused tests一起提交。

### Gemini

调查中的private `_meta.quota`是per-call token data，不是account allowance，也不满足本feature
接受的contract。当前不解析。未来Gemini发送标准ACP context/cost时，common path应自动支持。

### OpenCode

Verified behavior：标准ACP context和cost；captured free model报告`0 USD`。

我们知道OpenCode upstream issue `#38667`：non-USD cost可能错误标成USD。产品不做本地修正，假设
provider报告的currency是authoritative并原样传递。等upstream package修复后升级package，不为
这个bug增删client workaround。

OpenCode 1.18.3的local fixture不是特殊处理；它只是证明真实标准ACP payload
`used/size/cost`能被common normalizer反序列化。

========================

## Localization contract

Resource folders是authoritative locale set；新tooling不要hardcode数量。Feature完成时基线是：

- 89个TerminalApp locale folders；
- 16个TerminalSettingsEditor locale folders；
- 85个真实翻译的non-source locales；
- 3个pseudo-locales使用English fallback。

FRE和Settings的title/description在shared locales中必须一致。Preserve：

- valid XML；
- exactly one UTF-8 BOM；
- `xml:space="preserve"`；
- existing line endings和unrelated resources；
- `qps-ploc`、`qps-ploca`、`qps-plocm`的English fallback。

使用`XmlDocument.PreserveWhitespace = true`之类的XML-aware updater；不要用普通text output批量改
`.resw`。`<comment>`是developer/translator guidance，不会显示给用户。

Feature keys：

- Bottom Bar：`UsageGroup/.../Name`、`Usage_TokensUnit`、`Usage_ContextWindowLabel`
- FRE：`FreOverlay_ShowTokenUsageAndCostLabel.Text`、
  `FreOverlay_ShowTokenUsageAndCostDescription.Text`
- Settings：`AIAgents_ShowTokenUsageAndCost.Header`、
  `AIAgents_ShowTokenUsageAndCost.HelpText`

========================

## Validation baseline与commands

Current committed test ownership：

- Rust normalization/policy：`tools/wta/src/usage.rs`
- ACP routing：`tools/wta/src/protocol/acp/mock_agent_tests.rs`
- Master coalescing：`tools/wta/src/master/tests.rs`
- Per-tab merge/lifecycle/staleness：`tools/wta/src/app_tests.rs`
- C++ parse/cache/display：`src/cascadia/ut_app/AgentUsageTests.cpp`
- Localization parity：`test/e2e/selftests/UsageLocalization.Unit.Tests.ps1`
- Settings/FRE/provider/session E2E：现有`test/e2e/tests/Feature.*` suites

Latest known baseline（只是历史reference，不是永久固定总数）：

- Full WTA suite：1,348 passed，0 failed；
- Terminal x64 Debug build：0 errors，210 existing warnings；
- TerminalApp UnitTests build：0 errors，39 existing warnings；
- `AgentUsageTests`：23 passed，0 failed；
- `UsageLocalization.Unit.Tests.ps1`：5 passed，0 failed；
- Unit-tagged E2E selftests：20 passed，0 failed，19 not selected；
- original PR required checks passed。

每次验证都报告current run counts，不要假设总数必须等于baseline。

Useful commands：

```powershell
cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml

cmd.exe /d /c "tools\razzle.cmd && cd src\cascadia\ut_app && bx"

cmd.exe /d /c "tools\razzle.cmd && cd bin\x64\Debug\UnitTests_TerminalApp && te.exe Terminal.App.Unit.Tests.dll /name:*AgentUsageTests*"

Import-Module Pester -MinimumVersion 5.0.0 -Force
Invoke-Pester -Path test/e2e/selftests/UsageLocalization.Unit.Tests.ps1
Invoke-Pester -Path test/e2e/selftests -Tag Unit
```

========================

## Local evidence必须保留

Local desktop orchestration、provider configs、credentials、wire captures、screenshots和custom
mock frameworks不进入feature product commits。不要因为它们被ignore就删除。

Known local artifact families包括：

- `test/e2e/artifacts/real-copilot-usage-ui/`
- `test/e2e/artifacts/copilot-usage-command/`
- `test/e2e/artifacts/copilot-context-command/`
- `test/e2e/artifacts/copilot-cli-acp-usage-bug/`
- `test/e2e/artifacts/opencode-acp/`
- `test/e2e/artifacts/real-gemini-acp/`
- `test/e2e/artifacts/token-usage-toggle/`
- `test/e2e/artifacts/step9-usage/`
- `test/e2e/artifacts/usage-localization/`
- `test/e2e/artifacts/session-cost-localization/`

分享或commit任何capture前，检查并清除prompts、credentials、local paths、account identifiers、
tokens和provider logs。

========================

## Review hygiene与历史guardrails

Publish code只表达当前behavior：

- 不保留force/ban superseded provider-specific behavior的tests/comments；
- 这是为了降低review cognitive load，不是隐瞒历史；
- 历史原因保留在dev-only handoff/tracking；
- 未来有正式特殊处理时，把verified contract、implementation和tests一起提交；
- 对low-confidence review comment先沿owning code path验证，不直接接受或拒绝。

本PR的review经验：

- low-confidence duplicate-refresh comment经过sole caller tracing后确认有效，删除了重复
  `StateChanged`；
- `<cstddef>`建议有效，因为header直接用`size_t`；删除`<string_view>`建议无效，因为public API
  直接用`std::wstring_view`；
- spelling不认识`USD`时应加allowlist，不应修改合法currency fixture。

Do not accidentally reintroduce：

- per-turn token breakdown UI；
- Gemini private quota parsing；
- Copilot `/context`、`/usage` probing或user-folder log parsing；
- inferred AIC/credits；
- local token-to-price calculation；
- invalid context的`N/A`/over-100%显示；
- visible copy中的`billing`/provider credit wording；
- Usage apply和caller同时refresh Bottom Bar。

========================

## Future follow-ups

1. **Claude adapter upgrade**
   - 保留exact pin；
   - 测试approved feed最新版本（2026-08-05为`0.63.0`），或等待upstream `0.64.2`同步；
   - 验证initialize、auth、session/new/load、model config、chat、cancel、tools、permissions、
     terminal、context、cost和offline/package cache；
   - 同时更新三个live launch owners和current docs；保留历史`0.59.0`capture。

2. **Eliminate launch metadata duplication**
   - Claude/Codex command当前在TerminalApp、Settings和Rust分别定义；
   - 在独立architecture PR中改成single generated/shared source，并加drift tests。

3. **GitHub Copilot standard cost**
   - 跟踪upstream feature request；
   - 可用后先抓真实wire；
   - 优先使用common standard normalizer，只有official contract确实需要时才做special handling。

4. **Gemini standard Usage**
   - Gemini发送标准ACP context/cost后重新验证；
   - 不把private `_meta.quota`提升为本产品数据。

5. **OpenCode currency fix**
   - 跟踪anomalyco/opencode `#38667`；
   - 升级package，不增加/删除client workaround。

6. **Dedicated E2E framework PR**
   - 保留并modularize本地desktop automation；
   - 未来在独立PR中发布，不扩大usage feature diff。

7. **Documentation freshness**
   - current-state docs跟随live pin；
   - historical captures保留当时真实版本，例如Codex历史`1.1.2`与当前`1.1.4`。

Future private provider source必须满足：

- official/supported machine-readable contract；
- exact family/reporter/schema identity；
- sanitized real wire fixtures和version evidence；
- malformed/missing/partial tests；
- no credentials或unsupported local files；
- standard ACP存在时不duplicate；
- failure containment不影响chat；
- focused publish diff不编码speculative future behavior。

========================

## Definition of Done for next follow-up

一个follow-up step完成必须满足：

- behavior符合本contract或明确记录的新decision；
- 有focused RED/GREEN evidence；
- relevant full tests/build通过；
- logs/telemetry不包含Usage values；
- UI copy变化时完成localization/accessibility；
- local E2E evidence保留且敏感/ignored artifacts不误commit；
- dev/publish scope正确；
- commit已push且branch同步；
- 本handoff更新完成，下一branch无需重新调查。


以下是project-wide 的一些background knowledge。仅供参考，请以实际代码实现为准。

=================================================



# Intelligent Terminal (Windows Terminal Fork)

AI-native Windows Terminal — agents (Copilot, Claude, Gemini, custom) can understand, fix, and automate terminal workflows.

## Core Components

- **WTA** (Windows Terminal Agent) — orchestrator binary. Launches agents, passes Terminal Protocol connection info. Agents control WT via `wtcli`.
  - Launch: `wta delegate --agent <agent> --delegate-agent <delegate> --cwd <cwd> "<prompt>"`
- **WT Protocol** (`IProtocolServer`) — sole integration surface. WinRT IDL + COM out-of-process server (MBM marshaling, MTA thread). Discovery via `WT_COM_CLSID` env var.
  - IDL: `src/cascadia/TerminalProtocol/TerminalProtocol.idl`
  - Server: `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp`
- **WTCLI** — CLI client consuming `IProtocolServer` via `CoCreateInstance(CLSCTX_LOCAL_SERVER)`. Agents shell out to `wtcli list-panes`, `wtcli capture-pane`, etc.
- **ACP** (Agent Control Protocol) — JSON-RPC 2.0 spoken inside the helper+master architecture. `wta-helper` ↔ `wta-master` over a named pipe; `wta-master` ↔ agent CLI subprocess over stdio. The C++ side no longer participates in ACP directly — agent panes are plain `ConptyConnection`s hosting a `wta-helper` child. See `doc/specs/Multi-window-agent-pane.md`.

## UX

| Trigger | Behavior |
|---------|----------|
| `>Toggle AI assistant` | Opens/toggles agent pane (`openAgentPane` action) |
| `?<prompt>` | Delegates to hidden background WTA process |
| `?` (empty) | No-op |
| `&` | Background task mode (future, C9) |

Agent pane: position configurable (`bottom`/`right`/`top`/`left`). Color-coded VT output.

## Settings (`settings.json`)

```jsonc
{
    "acpAgent": "copilot",           // "copilot", "gemini", or "custom:<cmd>"
    "acpModel": "",                  // Model override
    "acpCustomCommand": "",          // Command for custom agent
    "agentPanePosition": "bottom",
    "delegateAgent": "copilot",      // Agent for ?<prompt> delegation
    "delegateModel": "",
    "delegateCustomCommand": "",
    "autoFixEnabled": true,
    "aiIntegration.coordinator.enabled": false,
    "aiIntegration.coordinator.commandline": "wta",
    "aiIntegration.coordinator.profile": "{fd19208a-412b-4857-8a2d-9ca592b4b16e}",
    "aiIntegration.confirmation.readOperations": "auto",
    "aiIntegration.confirmation.createOperations": "auto",
    "aiIntegration.confirmation.inputOperations": "auto",
}
```

## Architecture

```
WindowEmperor (one WT process, N AppHosts/windows)
  |-- TerminalProtocolComServer (COM, MTA thread, WT_COM_CLSID)
  |-- SharedWta (singleton) -- spawns --> wta-master ──► agent CLI (ACP/stdio)
  |                                          ▲
  |                                          │ ACP/JSON-RPC over named pipe
  +-- AppHost[] → TerminalWindow → TerminalPage
        |-- CommandPalette (? / & prefixes)
        |-- Per-tab agent pane: ConptyConnection ───► wta-helper (conpty child)
        |                                            (one helper per tab, pre-warmed)
        +-- Protocol bridge (TerminalPage.Protocol.cpp)

External: Agent → wtcli → COM (IProtocolServer) → TerminalProtocolComServer → WindowEmperor
```

**Per-tab + per-window routing.** Each agent pane has its own helper bound
to an `owner_tab_id` (= WT tab StableId) and a `window_id`. All inbound
events that mutate per-tab state (`set_agent_state`, `tab_changed`,
`tab_closed`, `tab_renamed`) carry both ids; helpers filter by `window_id`
and (for `tab_changed`) by owner-lock in `switch_tab_session`. Outbound
helper events (`agent_state_changed`, `agent_status`, `autofix_state`,
`close_agent_pane`) carry `tab_id` so C++ can route via
`_FindTabByStableId` instead of fanning out across every pane / window.
See `doc/specs/Multi-window-agent-pane.md` §7.

**Helper is pre-warmed per tab.** Every new tab spawns a stashed agent
pane on creation (`_InitializeTab` → `_AutoCreateHiddenAgentPaneShared`
with `autoStash=true`, `--start-stashed`), so the helper is running and
its ACP session connects in the background from the start — even if the
user never opens the pane. This is what lets autofix work on a tab the
user hasn't interacted with. The agent CLI itself is spawned once by
`wta-master` at startup and shared across all helpers (each helper's
`initialize` is a cached replay; only `session/new` round-trips to the
CLI). `--start-stashed` only seeds `pane_open=false`; it does not defer
the handshake. The pre-warm is skipped when wta is unavailable, GPO
blocks all agents, or the tab arrived with an agent pane via cross-window
drag-in (`agentLeavesSeen > 0`). See `TabManagement.cpp:366`.

**Agent pane toggle = stash, not destroy.** `Ctrl+Shift+.` /
`Ctrl+Shift+/` / the bottom-bar button toggle via
`Tab::StashAgentPane`/`RestoreStashedAgentPane` (built on WT's
`Pane::HidePane`/`RestorePane`). Helper + conpty + ACP session + chat
history all survive the toggle. The pane is only destroyed on tab close
or `Ctrl+C×2` in the TUI. See spec §8.

## Key Files

| Area | Path |
|------|------|
| Agent integration | `src/cascadia/TerminalApp/TerminalPage.cpp`, `TerminalPage.Protocol.cpp` |
| Agent pane wrapper | `src/cascadia/TerminalApp/AgentPaneContent.cpp` (XAML chrome around the helper's `TermControl`) |
| Tab-side stash | `src/cascadia/TerminalApp/Tab.cpp` (`StashAgentPane`, `RestoreStashedAgentPane`, `HasStashedAgentPane`) |
| Command Palette | `src/cascadia/TerminalApp/CommandPalette.cpp` |
| Protocol IDL | `src/cascadia/TerminalProtocol/TerminalProtocol.idl` |
| COM Server | `src/cascadia/WindowsTerminal/TerminalProtocolComServer.cpp` |
| Shared master spawn | `src/cascadia/TerminalApp/SharedWta.cpp` |
| wta-master | `tools/wta/src/master/mod.rs` |
| wta-helper / App | `tools/wta/src/app.rs`, `tools/wta/src/main.rs` |
| Settings | `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`, `MTSMSettings.h` |
| Settings UI | `src/cascadia/TerminalSettingsEditor/AIAgents.xaml` |
| Process coord | `src/cascadia/WindowsTerminal/WindowEmperor.cpp` |

## Autofix

Detects command failures in other panes and auto-suggests fixes via the agent.

**Pipeline**: Shell emits `OSC 133;D;<exit_code>` → `TerminalPage` raises `ProtocolVtSequenceReceived` → COM server forwards to clients → WTA (via `wtcli listen --json`) classifies → `maybe_trigger_autofix()`.

**Requirements**: PowerShell shell integration (OSC 133 marks), a helper
whose ACP session has reached `Connected`, `wtcli` on PATH. The pane does
**not** need to be visible — the per-tab pre-warmed helper (see
Architecture) makes autofix work on a stashed pane. But a failure that
lands before the helper's session connects (cold start of master/agent
CLI, in-flight `session/new`, or a `Failed` agent) is **dropped**:
`trigger_autofix_inner` early-returns when `state != Connected`
(`app.rs:6820`). The bottom-bar notification banner still shows; only the
autofix pill / LLM call is skipped, and the failure is not re-triggered
once the session later connects.

**Key code**: `tools/wta/src/app.rs` (`classify_wt_event`, `maybe_trigger_autofix`), `TerminalPage.cpp:2650-2740` (event handlers), `TerminalProtocolComServer.cpp` (`_ensurePageEventsRegistered`).

**Diag log**: `wta-ensure-host.log` in the WTA log directory — shows event flow, classification, and autofix triggers.

## Hooks plugin auto-upgrade

When IT is installed or upgraded, the bundled `wt-agent-hooks` plugin
(`tools/wta/wt-agent-hooks/{copilot,claude,gemini-extension}/`) needs to
re-land into any agent CLI the user already opted into (via Settings UI /
FRE "Install hooks" or `wta hooks install`). This is handled silently by
`agent_hooks_installer::upgrade_installed_hooks`, fired once per
`wta-master` startup on a blocking-pool thread.

**Trigger model — bundle version is the upgrade signal.** A tiny state
file `<LocalCache>/IntelligentTerminal/hooks-upgrade-state.json` records
the bundle version this wta process last saw per CLI. At startup we read
each CLI's bundle `plugin.json` / `gemini-extension.json` (cheap, <5ms)
and compare; if all match, we return immediately (no spawns, no IO
beyond the cache compare). Only after the user installs / upgrades IT
does the bundle version change → cache miss → per-CLI flow runs once,
then the state file is rewritten and the fast path resumes.

**Opt-in only.** Even on cache miss, CLIs that don't already have
`wt-agent-hooks` installed are skipped. The auto-upgrade never installs
into a CLI the user hasn't accepted. Disabled plugins are also skipped
(`enabled: false` in Copilot's `config.json` / `claude plugin list`).

**Per-CLI strategy.** Copilot and Claude use their `plugin update`
subcommands; before invoking them we rewrite any stale marketplace
`source.path` to the current bundle dir (Copilot: existing
`cleanup_stale_copilot_marketplace`; Claude: new
`cleanup_stale_claude_marketplace`). Gemini's `extensions update`
silently returns `NOT_UPDATABLE` when the recorded install source no
longer exists (typical after an MSIX version-dir bump), so we peek at
`~/.gemini/extensions/wt-agent-hooks/.gemini-extension-install.json`
first: if `type==local` AND `source` is still under the current bundle,
run `extensions update` in place; otherwise fall back to
uninstall+install while preserving the `isActive` flag.

**Trigger-point caveat.** The agent CLI master spawns concurrently may
already be past its plugin-load step by the time `plugin update` writes
the new files — so the freshly upgraded hooks may not take effect until
the next agent restart. Acceptable because blocking master startup on a
Node-based `plugin update` (1-30s) would hurt every IT-upgrade boot.

**Diag**: `wta-install-hooks.log` (existing) plus `target=agent_hooks`
+ `target={copilot,gemini}_hooks` trace events in
`wta-main_master.log` show every per-CLI decision (`upgrade decision`
log line carries `installed_version`, `bundle_version`, `action`).

## Logs & runtime data layout

WTA runtime data lives under the **package-private** store, split by lifetime
into two roots (both resolved in `runtime_paths.rs`, both falling back to the
same bare path when the process has no package identity):

```
# Packaged (every production wta process — helper is a conpty child of the
# packaged WindowsTerminal.exe, master is spawned in-package by SharedWta):

  …\Packages\<PackageFamilyName>\LocalState\IntelligentTerminal\   <- STATE root
      prompts\                      (prompt overrides)             intelligent_terminal_root()
      agent-pane-sessions.jsonl     (session origin index)
      master-pipe.txt               (helper↔master rendezvous)

  …\Packages\<PackageFamilyName>\LocalCache\Local\IntelligentTerminal\  <- LOCAL/cache root
      logs\<pkgver>\                (ALL logs for that build — Rust wta-*.log,
                                     C++ terminal-agent-pane.log, PS hook-trace.log)
      hook-bundle-staging\ …        (hook-installer staging)
      hooks-upgrade-state.json      (per-CLI bundle version cache for the
                                     hooks auto-upgrade fast-path)

# Unpackaged (dev builds run straight out of the Cargo target dir, tests):
# BOTH roots collapse to the legacy bare %LOCALAPPDATA%\IntelligentTerminal\.
```

Rationale for the split: **State** = persistent, must-survive, package-private
data → `LocalState` (alongside the WT app's own `settings.json` / `state.json`).
**Local/cache** = transient, regenerable diagnostics → `LocalCache\Local`, the
cache store that doesn't roam / back up.

Both roots are package-private — removed on uninstall and isolated between the
dev-sideload family (`IntelligentTerminal_rd9vj3e6a2mbr`) and the store family
(`Microsoft.IntelligentTerminal_8wekyb3d8bbwe`) — instead of sharing one bare
`%LOCALAPPDATA%\IntelligentTerminal` directory. The family name comes from
`GetCurrentPackageFamilyName` (windows-sys); the `Packages\<pfn>\LocalState` and
`…\LocalCache\Local` paths are what WinRT `ApplicationData.Current.LocalFolder`
/ `LocalCacheFolder` resolve to, so we construct them directly rather than
pulling in the WinRT projection.

**All three writers share one per-version dir** `logs\<pkgver>\`, where
`<pkgver>` is the **package version** (`GetCurrentPackageId`, e.g. `0.8.0.2`) —
read identically at runtime by Rust (`logging::package_version`) and C++
(`IntelligentTerminal::PackageVersionDir`), so no build-time version sync is
needed:
- Rust wta processes → `logging::log_dir()` (`logs\<pkgver>\wta-*.log`).
- C++ `AgentPaneLog.h` → `IntelligentTerminal::LogDirVersioned()` →
  `terminal-agent-pane.log` (renamed from the old `wta-agent-pane.log`).
- PowerShell hooks (`send-event.ps1`) → `hook-trace.log`, via the
  `WTA_HOOK_LOG_DIR` env var set to `LogDirVersioned()` (C++ ConptyConnection
  for shell panes; `spawn.rs` for agent-pane CLIs).

`IntelligentTerminal::LogDir()` stays the **root** (`…\logs`, no version) and is
used only by the bug-report-zip action so it archives every version at once.
Unpackaged (dev-from-cargo / tests) has no package identity → all writers fall
back to the flat bare `…\logs\`.

> Earlier builds wrote everything to the bare `%LOCALAPPDATA%\IntelligentTerminal`
> regardless of identity (the `LOCALAPPDATA` env var is **not** redirected into
> the sandbox on Win10/11). There is no migration — old data is left in place
> and simply ignored.

**Log level** is controlled by the `WTA_LOG` (or `RUST_LOG`) env var. When
unset, the default comes from the build: **debug builds default to `debug`,
release builds default to `info`** (`logging::default_filter_directive`). Set
`WTA_LOG=debug|trace` for the noisy traces, or `WTA_LOG=warn` to quiet a
release build further.

**Logging is initialized once** in `main()` immediately after arg parsing
(`logging::init(&process_label(&cli))`), before locale/ETW setup, so even
early-startup failures land on disk. The non-blocking appender's `WorkerGuard`
lives in a global and is flushed via `logging::shutdown_flush()` on every exit
path — including before each `std::process::exit` (which would otherwise skip
the guard drop and lose buffered records). Every launch mode — including
short-lived `wtcli`-style commands — now writes a log file (previously only 6
entry points did).

**Per-version storage + retention** (`logging::housekeeping`): each build's
logs live in their own subdir, `logs\<pkgver>\` (the package version — see
above). On every start, `prune_old_version_dirs` keeps **only the current
version's dir** and deletes all other version dirs wholesale. The current
version's dir is never a deletion target, so cleanup is **lock-free and
concurrency-safe** (no process can delete a file another is writing). Within the
current version's dir, per-PID helper logs older than **3 days** are pruned and
`wta-cli.log` rotates daily keeping 3 days (`max_log_files`).

### Log files in the helper+master architecture

```
wta-main_master.log        — wta-master process: agent CLI spawn, named pipe accept
                              loop, per-helper routing, session_to_helper map updates,
                              agent CLI exit detection, connection failures
wta-main_helper-{pid}.log  — each wta-helper process (one file per PID, so concurrent
                              per-tab helpers don't interleave): pipe connect, ACP
                              initialize, session/new, prompts, agent responses,
                              TUI lifecycle, connection failures
wta-cli.log                — short-lived wtcli-style commands (list-*, capture-pane,
                              listen, sessions, …); daily-rotated, 3-day retention
wta-delegate.log           — `?<prompt>` delegation flow (separate from agent pane)
wta-probe.log              — `probe-models` ACP model-list probe
wta-install-hooks.log      — `hooks install` agent-hook bridge installation
wta-ensure-host.log        — WT-side background ensure-running diagnostics (kept from
                              M3-M6 era; remains useful for SharedWta lifecycle)
wta-acp-debug.log          — low-level ACP JSON-RPC wire trace
```

Two files in the per-version dir are **not** written by the Rust wta binary —
`hook-trace.log` (PowerShell hooks) and `terminal-agent-pane.log` (C++ side);
see **All three writers share one per-version dir** above. They live in the
same `logs\<pkgver>\` and so are cleaned together with the Rust logs when that
version's dir ages out.

### Tracking flows by `target` field

All tracing uses structured `target` + key=value fields. Grep patterns for common
scenarios:

| Goal | Grep |
|---|---|
| Master process lifecycle | `target=master` (in `wta-main_master.log`) |
| Who's connected to master right now | `live_helpers=` in `wta-main_master.log` (climbs on connect, drops on disconnect) |
| Which helper owns a SessionId | `step="helper→agent" op="new_session" session_id=…` |
| Trace one prompt end-to-end | grep `session_id="X"`, look for `step="helper→agent" op="prompt"` (sent) then `step="master→helper" op="session_notification"` (response chunks) |
| Helper pipe lifecycle | `target=master helper_id=…` shows connect+exit |
| Agent CLI failures | `target=agent_stderr` |
| Connection failures (either side) | `"exiting with error"` — `target=master` in `wta-main_master.log`, `target=helper` in `wta-main_helper-{pid}.log`; plus inline `step="acp_initialize"` / `step="pipe_connect"` for the helper handshake |
| Internal control routing | `target=internal_control` (legacy; mostly empty post-Z) |

### Example: end-to-end trace of one user prompt

```
[helper] target=acp_client                — pipe connected to master
[helper] target=acp_client                — ACP initialize sent
[helper] target=acp_client                — session/new → session_id=abc-123
[master] step=helper→agent op=new_session — registered abc-123 → helper_id=2
[helper]                                  — user pressed Enter, sending prompt
[master] step=helper→agent op=prompt      — forwarding to agent CLI (sid=abc-123)
[master] step=agent→helper kind=agent_message_chunk — agent CLI streamed first chunk
[master] step=master→helper               — wrote chunk back to helper_id=2 pipe
[helper]                                  — chunk applied to TabSession.messages
[master] step=helper→agent op=prompt elapsed_ms=842 stop_reason=…  — turn ended
```

If any step is missing, the failure is at the previous step.

## Build

There are two independent build systems. **Both must be built** before F5.

### 1. WTA (Rust) — build first

```bash
# Kill stale WTA processes first
taskkill //f //im wta.exe 2>/dev/null; true

cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
# Output: tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe
#
# Always pass --target explicitly — the wapproj prefers
# tools/wta/target/<triple>/<profile>/wta.exe over the bare target/<profile>
# fallback, and a stale explicit-target binary will silently shadow your
# fresh bare-target build.
```

### 2. Terminal (C++ / MSBuild)

**Command line (incremental):**
```bash
cmd.exe //c "tools\razzle.cmd && bcz no_clean"
# Release: bcz rel no_clean
# Output: bin/x64/Debug/
```

**Visual Studio F5 (debug):**
- Set `CascadiaPackage` as startup project → F5
- MSBuild copies `wta.exe` from Cargo output into the package layout
  (via Content items in `CascadiaPackage.wapproj`)
- The deployed `wta.exe` sits next to `WindowsTerminal.exe` in the
  package directory, inheriting package identity for COM access

### Safe Debug deployment

After a Debug Terminal build, use this wrapper to deploy C++, XAML, IDL,
`wtcli`, manifest, resource, packaging, or mixed changes:

```powershell
.\build\scripts\Invoke-IntelligentTerminalDebugDeployment.ps1 `
    -AppxRecipePath src\cascadia\CascadiaPackage\bin\x64\Debug\CascadiaPackage.build.appxrecipe
```

The script validates the dev package and loose Debug layout, closes only exact
PIDs running from that layout, deploys it, and reopens Intelligent Terminal if
needed. It terminates IT panes and agent sessions but never ordinary Windows
Terminal. Never stop `WindowsTerminal.exe` by name; use `-WhatIf -Verbose` when
process selection is uncertain.

Do not use full deployment for `wta.exe`-only changes; use the WTA hot-refresh
flow. Static assets such as `wt-agent-hooks` are not `wta.exe`-only changes.

### Full rebuild flow (typical dev cycle)

```bash
# 1. Build WTA (always use --target — see note above)
taskkill //f //im wta.exe 2>/dev/null; true
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml

# 2. Build & run Terminal from VS
#    F5 in Visual Studio (CascadiaPackage project)
#    — or from command line:
cmd.exe //c "tools\razzle.cmd && bcz no_clean"
```

### Package identity & COM

The COM server (`TerminalProtocolComServer`) is registered under the
Terminal's package identity. `wtcli.exe` and `wta.exe` must also have
package identity to activate it via `CoCreateInstance`. This is why:

- `wta.exe` is deployed **inside the package** (next to `WindowsTerminal.exe`)
- `_DetectWtaPath()` prefers the co-located `wta.exe` over dev-build paths
- Running `wta.exe` from `tools/wta/target/debug/` directly will fail with
  `0x80073D54` (APPMODEL_ERROR_NO_PACKAGE) when calling COM methods

If autofix or the agent pane stops working after a debug launch, check
`%TEMP%\wta-ensure-host.log` for the `0x80073D54` error — it means
the wrong (unpackaged) `wta.exe` was used.

## Installer

See **[doc/building-installer.md](doc/building-installer.md)** for full details.

Two distribution formats:

| Format | Script | Output |
|--------|--------|--------|
| **MSIX ZIP** (packaged) | Manual assembly from MSBuild output | `artifacts/local-installer/*-msix.zip` |
| **Self-extracting EXE** (unpackaged) | `build/scripts/New-WtaLocalInstaller.ps1` | `artifacts/local-installer/*-setup.exe` |
