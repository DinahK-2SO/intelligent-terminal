# ACP Usage / Session Cost Feature Handoff

> Last synchronized: 2026-08-06
>
> 这个文件只描述 ACP usage / session cost feature。它应该可以直接复制到新的 dev branch，
> 让下一阶段不需要重新翻阅旧调查记录。实际代码始终是最终 source of truth。

我们已经完成这个feature的第一版，并通过 squash commit `a6e1f4c5b`
(`Show the token usage and cost (#512)`) 合并到 `main`。

历史branch：

- dev branch：`user/DinahK-2SO/acp-price-calc`
- publish branch：`user/DinahK-2SO/show-usage-calc`

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
