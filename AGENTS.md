# ACP Usage / Session Cost Feature Handoff

> Last synchronized: 2026-08-05
>
> This file is the self-contained handoff for the Intelligent Terminal ACP usage/session-cost
> feature. It is meant to be copied into a fresh follow-up development branch. A reader should not
> need the old investigation documents to understand the current product, the decisions behind it,
> or the remaining work. The current code is always the final source of truth if this file drifts.

## 1. Current Status

The first production version is complete and landed in `main` through squash commit
`a6e1f4c5b` (`Show the token usage and cost (#512)`). Because GitHub used a squash merge, the old
publish branch is not necessarily an ancestor of `main` even though its product changes landed.

Historical branches:

- Development: `user/DinahK-2SO/acp-price-calc`
- Review/publish: `user/DinahK-2SO/show-usage-calc`

Do not use either historical branch as the base for the next phase. Start the next development
branch from current `origin/main`, copy this file into it, and record the new dev/publish branch
names here before changing product code.

The feature currently:

- consumes stable ACP session `UsageUpdate` data;
- can display context-window occupancy and session cost independently;
- is hidden by default behind one shared FRE/Settings toggle;
- stores Usage per agent tab/session in memory;
- does not calculate prices, convert currencies, or infer billing units;
- does not use any provider-specific private Usage source today;
- contains a provider adapter framework for future verified needs;
- degrades to hidden Usage on malformed data without breaking chat.

## 2. User Experience Contract

### 2.1 Visible data

Show at most two items in the Terminal Bottom Bar, in this order:

1. Context-window usage, when a valid context gauge is available.
2. Session cost, when a valid cost is available.

Do not show:

- per-turn input/output/cache/reasoning token breakdown;
- account quota, remaining credits, reset time, or plan allowance;
- locally calculated token cost;
- guessed provider credits or model multipliers;
- `N/A`, fake zero, or placeholder values for unavailable data.

Either item may appear by itself. Missing cost must not hide valid context. Invalid context must not
hide valid cost.

### 2.2 Current English UI copy

Title:

```text
Show context usage and session cost
```

Description:

```text
When available, show context-window usage and session cost in the terminal bottom bar.
```

`session cost` is deliberately generic and unit-neutral UI wording. Do not change it to
`billing`, `monetary cost`, `credits`, `AIC`, or a provider name without a new product decision and
full localization update.

Internal identifiers remain historical for compatibility:

- setting/API name: `ShowTokenUsageAndCost`;
- JSON key: `showTokenUsageAndCost`;
- projection kinds: `context` and `billing`.

Do not rename these merely to match newer display copy unless a migration is designed.

### 2.3 Toggle behavior

- Default: `false`.
- FRE and Settings -> AI Agents write the same `GlobalAppSettings.ShowTokenUsageAndCost` value.
- The toggle controls the entire Usage group: context and cost are both hidden when off.
- Turning the toggle off does not stop ingestion or clear the cache.
- Turning it back on immediately re-projects cached data; the agent need not report again.
- Settings save/reload directly calls `_UpdateBottomBarState()`. This path does not depend on
  `AgentPaneContent::ApplyAgentUsage` raising `StateChanged`.

### 2.4 Formatting and accessibility

Context main text:

```text
Context Window: <integer>%
```

- Use the latest valid `used / size` gauge.
- Percentage is rounded to the nearest integer with `.5` rounded up.
- Tooltip and Automation HelpText preserve exact counts and the percentage.
- Provider display strings may be retained when supplied by a future verified adapter.
- Hide context when `size == 0`, `used > size`, the count is malformed, or required data is absent.

Cost main text:

```text
<amount rounded half-up to 2 decimals> <reported unit>
```

- Preserve full reported precision in tooltip and Automation HelpText.
- A positive value below `0.01` displays as `<0.01 <unit>`.
- Exact zero is valid and displays as `0.00 <unit>`.
- Do not validate, uppercase, correct, or convert a provider-reported currency string.

All visible states must remain usable on narrow layouts and must not rely only on color.

## 3. Data Semantics

### 3.1 Context window

ACP `UsageUpdate.used` and `UsageUpdate.size` form a current context-window gauge.

- Replace the previous gauge; never add gauges across turns.
- The gauge may decrease after compaction.
- `size` may change after a model/config change.
- `used` can include system instructions, tools, history, and provider-managed context.
- It is not account quota and not cumulative lifetime token consumption.

### 3.2 Cost

ACP cost is optional. Treat the reported amount and currency as provider/agent-owned data.

- Never derive cost from token counts or a local price table.
- Never convert one unit to another.
- Never claim the value is an invoice or final provider bill.
- Claude captures established session-cumulative cost behavior.
- OpenCode's captured zero cost does not establish whether its cost field is per-call or cumulative.

### 3.3 Snapshot merge

Context, cost, and future provider metrics are independent optional fields.

- A newly reported context replaces context only.
- A newly reported cost replaces cost only.
- Missing fields do not erase other valid fields.
- Session-boundary operations clear all Usage for that session.
- Transport loss marks present metrics stale; stale metrics stay in state but are hidden from UI.

## 4. Current Architecture

### 4.1 End-to-end flow

```text
ACP agent
  -> wta-master forwards SessionNotification to the owning helper
  -> helper WtaClient handles SessionUpdate::UsageUpdate
  -> normalize_standard_usage()
  -> AppEvent::UsageReported { session_id, snapshot }
  -> owning TabSession merges UsageSnapshot and UsageStaleness
  -> app_status_projection builds agent_state_changed.usage
  -> TerminalPage::OnAgentStateChanged routes by tab id
  -> AgentPaneContent caches through AgentUsage::TryUpdateCache
  -> TerminalPage::_UpdateBottomBarState renders active-tab Usage
```

The master has a bounded notification channel. When a helper is slow, pending Usage is coalesced by
session/metric so the latest context does not erase an undelivered cost.

### 4.2 Rust ownership

- `tools/wta/src/usage.rs`
  - `UsageSnapshot`, `UsageContext`, `UsageCost`, `UsageProjection`, `UsageStaleness`;
  - standard normalization;
  - context validity filtering;
  - provider-neutral projection.
- `tools/wta/src/usage/providers/mod.rs`
  - provider adapter trait and registry;
  - dormant private-input shapes and policies.
- `tools/wta/src/usage/providers/{copilot,claude,codex,gemini,opencode}.rs`
  - one module per built-in family;
  - all currently return no private contribution and declare `StandardAcpOnly`.
- `tools/wta/src/protocol/acp/client.rs`
  - standard `UsageUpdate` ingestion;
  - invalid update containment into `UsageCleared`;
  - generic future provider orchestration.
- `tools/wta/src/master/mod.rs`
  - reliable per-session routing and pending Usage coalescing.
- `tools/wta/src/app_contracts/event.rs`
  - `UsageReported` and `UsageCleared` events.
- `tools/wta/src/app/tab_state.rs`
  - per-tab `usage` and `usage_staleness`.
- `tools/wta/src/app_events.rs`
  - merge, clear, lifecycle, and transport-staleness handling.
- `tools/wta/src/app_status_projection.rs`
  - cross-process JSON projection.

Current WTA dependency:

```toml
agent-client-protocol = "1.3.0"
```

### 4.3 C++ ownership

- `src/cascadia/TerminalApp/AgentUsage.{h,cpp}`
  - strict JSON parser;
  - cache update/containment;
  - pure primary-display selection and formatting.
- `src/cascadia/TerminalApp/AgentPaneContent.{h,cpp}`
  - per-tab Usage cache;
  - `ApplyAgentUsage` updates the cache but does not raise `StateChanged`.
- `src/cascadia/TerminalApp/TerminalPage.cpp`
  - routes `agent_state_changed` by stable tab id;
  - logs fixed diagnostics only;
  - owns the active-tab Bottom Bar refresh;
  - directly re-renders after settings reload.
- `src/cascadia/TerminalApp/TerminalPage.xaml`
  - owns the `UsageGroup` slot.
- `src/cascadia/TerminalSettingsModel/MTSMSettings.h`
  - persisted setting, default `false`.
- `src/cascadia/TerminalSettingsEditor/AIAgents.*`
  - Settings toggle projection.
- `src/cascadia/TerminalApp/FreOverlay.*`
  - FRE toggle initialization and save.

### 4.4 Refresh ownership

`ApplyAgentUsage` has one runtime caller: `TerminalPage::OnAgentStateChanged`. That caller performs
the active-tab catch-all `_UpdateBottomBarState()` after applying Usage. Do not re-add a
`StateChanged.raise()` inside `ApplyAgentUsage`; it causes two synchronous Bottom Bar refreshes for
one update. Other `AgentPaneContent::StateChanged` producers remain valid for states that drive the
bar independently.

## 5. Error Handling and Privacy

### 5.1 Standard ACP normalization

Typed context counts do not require string parsing. Optional cost is accepted only when finite and
non-negative.

- Invalid optional cost is omitted.
- Valid context survives.
- Zero cost is valid.
- The chat turn remains successful.

### 5.2 Future private parser errors

No private provider parser is active today. If one is added later, a provider parsing error must:

- omit that optional contribution;
- emit only a schema-level warning without values;
- not turn a completed user turn into an error;
- not leak payloads, credentials, or billing data to logs.

Inner parser/normalizer code should remain fail-fast in tests. Containment belongs at explicit outer
feature boundaries, not in many scattered catches.

### 5.3 C++ cross-process containment

`AgentUsage::Parse` and `UpdateCache` are strict and may throw on malformed schema.
`TryUpdateCache(... ) noexcept` is the one C++ containment boundary:

1. catch any parser exception;
2. clear the old Usage cache so stale data is not shown;
3. return `false`;
4. log only `invalid usage hidden`;
5. refresh the Bottom Bar, which hides Usage;
6. leave chat and the agent connection running.

The next valid update repopulates the cache.

### 5.4 Logging and sensitive data

- Usage numeric values must not enter normal logs or telemetry.
- Full ACP content is trace-only, and Usage values remain redacted even there where implemented.
- Never read provider credentials for this feature.
- Never copy raw provider logs, user prompts, tokens, or account information into committed files.

## 6. Provider Matrix and Decisions

All five built-in provider modules currently declare:

```text
PrivateUsagePolicy::StandardAcpOnly
trusted_reporter_ids = []
post_turn_commands = []
```

This describes current enabled behavior, not a permanent ban. If a provider later supplies a
supported private contract, its adapter and tests may be extended after real wire validation and
review.

| Provider | Verified data | Current product behavior | Follow-up |
|---|---|---|---|
| Claude | Standard context gauge and cumulative USD cost | Display both through the common path | Validate and upgrade the pinned adapter explicitly |
| Codex | Standard context gauge; no cost in captures | Display context only | Re-capture against current adapter pin |
| GitHub Copilot | Current CLI 1.0.78 reports standard context; no trusted cost | Display context only; no special handling | Wait for supported ACP cost, then test locally |
| Gemini | Private per-call token metadata, no accepted standard Usage/cost in investigation | Display nothing; do not parse private quota | Wait for standard ACP context/cost |
| OpenCode | Standard context and cost; captured free model reported `0 USD` | Display provider-reported values unchanged | Upgrade package after upstream currency fix |

Provider versions and upstream issue status in this section are an external compatibility snapshot
verified on 2026-08-05, not values derived from the repository. Re-check them before acting on a
follow-up. Product launch pins and current code behavior remain repository facts.

### 6.1 Claude

The original verified capture used:

```text
@agentclientprotocol/claude-agent-acp@0.59.0
```

Current product launch is pinned to `0.59.0` in three live owners:

- Terminal app launch mapping;
- Settings model-probe launch mapping;
- Rust agent registry.

The exact pin is intentional: an unversioned `npx` command executes whatever npm calls `latest`
that day, causing the same Intelligent Terminal version to behave differently across machines and
making failures difficult to reproduce.

As of 2026-08-05:

- the configured Microsoft npm feed reports `0.63.0` as `latest`;
- upstream GitHub reports `0.64.2` as the latest release;
- `0.63.0` upgrades ACP SDK `1.2.1 -> 1.3.0` and Claude Agent SDK
  `0.3.207 -> 0.3.220`;
- Node requirement remains `>=22`;
- newer versions include context initialization, session/model latency, tool-progress, terminal,
  permission, and ExitPlanMode fixes.

Do not remove the pin merely to get updates. Follow up by testing an approved newer version, then
update all live launch owners, current docs, and expectations in one focused change. Do not rewrite
historical captures that genuinely used `0.59.0`.

External package inspection on 2026-08-05 showed that the adapter normally uses the
platform-specific Claude executable shipped with its exact Claude Agent SDK dependency. A user's
globally installed Claude or ACP adapter version does not override the product pin;
`CLAUDE_CODE_EXECUTABLE` is the adapter's explicit external override. Thus a user's global 0.57 or
0.63 adapter can coexist with IT's 0.59 adapter; IT still launches 0.59 and does not upgrade or
downgrade the global installation. Re-verify this upstream behavior during an adapter upgrade.
Offline launch can fail when the exact pinned package is not cached.

### 6.2 Codex

Historical provider captures used adapter `1.1.2`; current product launch is pinned to `1.1.4`.
Do not globally replace `1.1.2` in historical result files. New compatibility evidence must use and
record the current product pin.

### 6.3 GitHub Copilot

Final decision: no Copilot-specific Usage processing.

Do not:

- send `/context`;
- send `/usage`;
- parse command output;
- read `%USERPROFILE%/.copilot` session logs;
- read `events.jsonl`, checkpoints, `totalNanoAiu`, or local ledgers;
- infer AIC/AI Credits from request counts or model metadata.

Background: earlier prototypes tried command probes and user-folder checkpoints. `/usage` did not
return valid cost for the product, `/context` became unnecessary after standard ACP context support,
and user-folder schemas were unsupported internal details. All product handling was removed.

The generic provider framework remains. Publish code and tests should look like the superseded
special behavior was never introduced. This is review-load reduction, not concealment: historical
rationale belongs in dev-only notes, while publish code should express only current behavior.
Do not add tests that permanently force or ban hypothetical future Copilot extensions. If a real
supported contract arrives, add its implementation and tests together.

### 6.4 Gemini

Gemini's investigated private `_meta.quota` data represents per-call token counts, not an account
allowance. It does not satisfy this feature's accepted contract. Do not parse it. Standard ACP data
should work automatically if Gemini adopts it later.

### 6.5 OpenCode

Assume the currency supplied by OpenCode is authoritative and pass it through unchanged. Do not add
a local correction for anomalyco/opencode issue `#38667` (non-USD cost mislabeled as USD). Upgrade
OpenCode after the upstream package contains the fix.

The local provider fixture using OpenCode 1.18.3 is not special product behavior. It proves a real
standard ACP payload (`used`, `size`, `cost`) can be deserialized by the common normalizer.

## 7. Localization Contract

Resource folders are authoritative; never hardcode locale counts in new tooling. At feature
completion the relevant sets were:

- 89 TerminalApp locale folders;
- 16 TerminalSettingsEditor locale folders;
- 85 real translated non-source locales;
- 3 pseudo-locales using English fallback.

The shared FRE/Settings title and description must match in every shared locale. Preserve:

- valid XML;
- exactly one UTF-8 BOM;
- `xml:space="preserve"`;
- existing line endings and unrelated resources;
- English fallback for `qps-ploc`, `qps-ploca`, and `qps-plocm`.

Use an XML-aware updater with `XmlDocument.PreserveWhitespace = true`; do not bulk-edit `.resw`
with ordinary text output commands. Translator comments are developer/translator guidance and are
not shown to users.

Bottom Bar keys:

- `UsageGroup/[using:Windows.UI.Xaml.Automation]AutomationProperties/Name`
- `Usage_TokensUnit`
- `Usage_ContextWindowLabel`

FRE keys:

- `FreOverlay_ShowTokenUsageAndCostLabel.Text`
- `FreOverlay_ShowTokenUsageAndCostDescription.Text`

Settings keys:

- `AIAgents_ShowTokenUsageAndCost.Header`
- `AIAgents_ShowTokenUsageAndCost.HelpText`

## 8. Lifecycle Rules

Usage belongs to an ACP session and active tab.

Clear Usage on:

- a fresh `/new` session;
- helper/agent restart;
- explicit per-tab session reset;
- new/load identity boundaries where old session data no longer applies;
- invalid cross-process replacement payload.

Do not clear Usage on local chat-history clearing when the underlying ACP session is unchanged.
Model display changes preserve Usage unless the provider reports a replacement gauge.

Background-tab updates change that tab's cache but do not refresh the window-level Bottom Bar until
the tab becomes active. Active-tab `OnAgentStateChanged` owns the immediate refresh.

## 9. Testing and Validation

### 9.1 Current committed test ownership

- Rust normalization/policy: `tools/wta/src/usage.rs`
- Standard ACP routing: `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- Master coalescing/routing: `tools/wta/src/master/tests.rs`
- Per-tab merge/lifecycle/staleness: `tools/wta/src/app_tests.rs`
- C++ parse/cache/display: `src/cascadia/ut_app/AgentUsageTests.cpp`
- Localization parity: `test/e2e/selftests/UsageLocalization.Unit.Tests.ps1`
- Settings toggle: `test/e2e/tests/Feature.SettingsUi.Tests.ps1`
- FRE toggle: `test/e2e/tests/Feature.FreAgentSetup.Tests.ps1`
- Provider switching/connectivity: `test/e2e/tests/Feature.AgentMatrix.Tests.ps1`
- Session view: `test/e2e/tests/Feature.SessionList.Tests.ps1`

### 9.2 Latest known validation baseline

These counts are historical baselines, not permanent expected totals:

- Full WTA suite after the latest `main` merge: 1,348 passed, 0 failed.
- Terminal x64 Debug build after that merge: 0 errors, 210 existing warnings.
- TerminalApp UnitTests build: 0 errors, 39 existing warnings.
- `AgentUsageTests`: 23 passed, 0 failed.
- `UsageLocalization.Unit.Tests.ps1`: 5 passed, 0 failed.
- Unit-tagged E2E selftests: 20 passed, 0 failed, 19 not selected by the filter.
- The original PR's required checks passed before merge.

Always report current counts from the run; do not assert that totals must stay equal to these.

### 9.3 Useful commands

Use the explicit Rust target consistently so packaging does not pick up a stale binary:

```powershell
cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
```

Build TerminalApp unit tests from a razzle environment:

```powershell
cmd.exe /d /c "tools\razzle.cmd && cd src\cascadia\ut_app && bx"
```

Run AgentUsage TAEF tests:

```powershell
cmd.exe /d /c "tools\razzle.cmd && cd bin\x64\Debug\UnitTests_TerminalApp && te.exe Terminal.App.Unit.Tests.dll /name:*AgentUsageTests*"
```

Run localization/selftests with PowerShell 7+ resolved from `PATH`:

```powershell
Import-Module Pester -MinimumVersion 5.0.0 -Force
Invoke-Pester -Path test/e2e/selftests/UsageLocalization.Unit.Tests.ps1
Invoke-Pester -Path test/e2e/selftests -Tag Unit
```

For all E2E work:

- run under the current `pwsh` resolved from `PATH`;
- when a child needs the same host, reuse `(Get-Process -Id $PID).Path`;
- do not hardcode a machine-specific PowerShell installation path.

### 9.4 Minimum packaged/live acceptance

The original feature passed the following live desktop preflight. Re-run the affected portions for
follow-ups that change provider launch, package contents, agent routing, Bottom Bar rendering, or
session management:

1. Use deterministic Claude and Codex mocks that speak the real ACP wire contract.
2. Build and deploy the existing Intelligent Terminal package, then launch it.
3. Capture a screenshot and verify the Terminal window is visible and nonblank.
4. Open the agent pane from the Bottom Bar; capture a screenshot and verify the conversation UI.
5. Select Claude; capture evidence that the active agent actually changed to Claude.
6. Select Codex; capture evidence that the active agent actually changed to Codex.
7. Return to the terminal, open the Session view from the Bottom Bar, and capture evidence that the
  session UI is visible.
8. For Usage changes, inject or obtain context-only, cost-only, both, absent, stale, and malformed
  states; verify visibility, tooltip, accessibility text, and no overlap on desktop/mobile-sized
  windows where applicable.

Prefer existing E2E helpers. If they cannot express a required interaction, build the new harness
locally and modularly, keep it ignored, and reserve framework publication for a separate PR.

## 10. Local E2E Evidence

Local desktop orchestration, provider configs, credentials, wire captures, screenshots, and custom
mock frameworks are intentionally not part of this feature's product commits. Preserve them; do
not delete them merely because they are ignored.

Known local artifact families include:

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
- local ACP mock launchers and provider bridge configs.

Before transferring or committing any capture, inspect it for prompts, credentials, local paths,
account identifiers, tokens, and provider logs. Screenshots remain local unless deliberately copied
to a non-ignored review-evidence directory.

## 11. Development Workflow for the Next Branch

### 11.1 Branch setup

1. Fetch `origin/main`.
2. Confirm `origin/main` contains `a6e1f4c5b` or a later equivalent feature landing.
3. Create a fresh follow-up dev branch from `origin/main`.
4. Copy this file into that branch.
5. Record the new dev branch and optional publish branch near the top of this file.
6. Do not silently continue work on the historical branches.

If the next phase again uses a dev/publish split, keep publish review-focused. The previous publish
branch intentionally excluded:

- `AGENTS.md`;
- all of `doc/`;
- `build/scripts/New-LocalMsixInstaller.ps1`;
- `test/e2e/selftests/LocalMsixInstaller.Unit.Tests.ps1`;
- `test/e2e/selftests/UsageLocalization.Unit.Tests.ps1`;
- local-only E2E framework files, wire captures, and screenshots not intended for that product PR.

Adapt the exclusion list to the new PR, but preserve the principle: publish contains current
product behavior and existing-framework tests; dev may also contain investigation history and local
workflow material.

### 11.2 Strict TDD loop

For every behavioral step:

1. Add or change the smallest existing-framework test to establish RED.
2. Run the focused test and confirm it fails for the intended reason.
3. Make the smallest GREEN implementation.
4. Immediately rerun the same focused validation.
5. Update the branch's self-contained tracking section or dev-only tracking document.
6. Commit the product code, appropriate existing-framework tests, and tracking note.
7. Push the dev branch.
8. Confirm the remote is synchronized before starting another RED step.

If push fails, branches diverge, or remote commits cannot be safely integrated, stop before the
next step and resolve synchronization first.

Do not introduce a large new E2E framework into a feature commit. Keep new local framework code
modular and ignored for a later dedicated PR. Existing repository test frameworks should be
committed when they naturally cover the behavior.

### 11.3 Engineering scope

- Reuse the existing ACP route, provider registry, per-tab state, projection, and Bottom Bar.
- Do not create a parallel Usage state/event/UI architecture.
- Follow main's current module ownership after refactors.
- Avoid broad architectural cleanup in a feature follow-up; record real debt for a separate branch.
- Do not revert unrelated user changes in a dirty worktree.

### 11.4 Review hygiene

Publish code should express current behavior only.

- Do not retain comments/tests that force or ban superseded provider-specific behavior.
- This is to reduce reviewer cognitive load, not to hide history.
- Keep historical rationale in this dev-only handoff/tracking material.
- If special handling becomes necessary later, introduce the verified contract, implementation,
  and tests together so reviewers evaluate one coherent change.
- Treat low-confidence review comments as hypotheses: trace the owning code path before accepting
  or declining them.

Examples from the completed PR:

- A low-confidence duplicate-refresh comment was valid after tracing the sole caller; the redundant
  `StateChanged` raise was removed.
- A suggestion to add `<cstddef>` was valid because the header directly used `size_t`; deleting
  `<string_view>` was not valid because the public API directly uses `std::wstring_view`.
- `USD` was added to the spelling allowlist instead of altering legitimate currency fixtures.

## 12. Historical Decisions That Must Not Reappear Accidentally

The following approaches were explored and then superseded:

- displaying per-turn input/output/cache/reasoning token breakdown;
- parsing Gemini private quota metadata;
- sending Copilot `/context` and `/usage` after user turns;
- interpreting `/usage Requests` as AI Credits/AIC;
- reading Copilot user-folder logs or usage checkpoints;
- locally calculating provider price from tokens or model metadata;
- presenting invalid context as `N/A` or over 100%;
- using visible copy such as `token usage and cost`, `usage and billing`, or provider-specific
  credit wording;
- raising Usage `StateChanged` and then refreshing the Bottom Bar again in the caller.

Historical tests/captures may mention these, but new publish code must not restore them without a
new explicit decision.

## 13. Follow-up Backlog

### Priority follow-ups

1. **Claude adapter upgrade**
   - Keep an exact pin.
   - Test the newest version available in the approved npm feed (currently `0.63.0`) or wait for
     upstream `0.64.2` to synchronize.
   - Validate initialize, authentication, session/new/load, model config, chat, cancellation,
     tools, permissions, terminal updates, context, cost, and packaging cache behavior.
   - Update all live launch owners and current docs together; preserve historical `0.59.0` captures.

2. **Eliminate launch metadata duplication**
   - Claude/Codex commands are duplicated in TerminalApp, Settings, and Rust.
   - Move toward one generated/shared source with drift tests in a separate architecture PR.

3. **GitHub Copilot standard cost**
   - Track the upstream request for ACP cost data.
   - When available, capture real wire data first.
   - Prefer the common standard normalizer; add special handling only if an official contract
     requires it.

4. **Gemini standard Usage**
   - Re-test when Gemini emits standard ACP context/cost.
   - Do not promote private `_meta.quota` token counts into this product surface.

5. **OpenCode currency fix**
   - Monitor anomalyco/opencode `#38667`.
   - Upgrade the package rather than adding/removing a client workaround.

6. **Dedicated E2E framework PR**
   - Preserve and modularize local desktop automation.
   - Move it into a separate PR that can test real user interactions without bloating feature diffs.

7. **Documentation freshness**
   - Historical captures may legitimately name old versions.
   - Current-state docs must track live pins (for example, Codex product pin is now `1.1.4`, while
     old captures used `1.1.2`).

### Future provider extension rules

Before enabling any private provider source, require:

- an official or explicitly supported machine-readable contract;
- exact family/reporter/schema identity;
- sanitized real wire fixtures;
- version/compatibility evidence;
- malformed/missing/partial-value tests;
- no credentials or unsupported local files;
- no duplicate reporting when standard ACP data exists;
- failure containment that preserves chat;
- a focused publish diff that does not encode speculative future behavior.

## 14. Repository Runtime Context for Follow-up Work

### 14.1 Product process model

Intelligent Terminal is a Windows Terminal fork with three relevant integration layers:

- **WTA**: Rust orchestrator. A shared `wta-master` owns agent CLI processes; one pre-warmed
  `wta-helper` runs inside each tab's stashed agent pane.
- **ACP**: JSON-RPC between helper <-> master over a named pipe and master <-> agent CLI over stdio.
- **WT Protocol / wtcli**: package-identity COM surface used by agents and WTA to inspect or control
  Terminal panes.

Simplified layout:

```text
WindowsTerminal package
  -> SharedWta starts one wta-master
       -> agent CLI(s) over ACP/stdio
  -> each tab owns a stashed agent pane
       -> ConptyConnection starts one wta-helper
       -> helper connects to master over ACP/named pipe
  -> wtcli activates the packaged Terminal Protocol COM server
```

The hidden agent pane is stashed, not destroyed. Its helper, ACP session, chat history, and Usage
cache survive pane toggle. The pane is destroyed on tab close or the explicit TUI close sequence.

Every helper is anchored to an owner tab id and window id. Inbound state updates carry routing ids;
outbound events carry `tab_id`. Usage must remain on this existing per-tab route and must never be
fanned out globally.

### 14.2 Package identity

`wta.exe` and `wtcli.exe` need the Terminal package identity to activate the COM server. The package
build copies `wta.exe` beside `WindowsTerminal.exe`. Running a Cargo-output `wta.exe` directly can
fail COM activation with `0x80073D54` (`APPMODEL_ERROR_NO_PACKAGE`).

For package/COM/UI changes, deploy the packaged Debug layout. For a `wta.exe`-only change, build the
normal host-target binary at `tools/wta/target/debug/wta.exe` and use the repository's WTA
hot-refresh flow rather than a full app deployment. Static assets and hook bundles are not
WTA-only changes.

Safe Debug deployment after a build:

```powershell
./build/scripts/Invoke-IntelligentTerminalDebugDeployment.ps1 `
    -AppxRecipePath src/cascadia/CascadiaPackage/bin/x64/Debug/CascadiaPackage.build.appxrecipe
```

The wrapper targets only processes running from the dev layout. Never kill every
`WindowsTerminal.exe` by name. Use `-WhatIf -Verbose` when process selection is uncertain.

### 14.3 Build order

For normal WTA-only iteration, use the host target expected by the WTA hot-refresh flow:

```powershell
Get-Process wta -ErrorAction SilentlyContinue | Stop-Process -Force
cargo build --manifest-path tools/wta/Cargo.toml
```

For a packaged validation cycle, an explicit target is also supported:

```powershell
Get-Process wta -ErrorAction SilentlyContinue | Stop-Process -Force
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
```

Choose one WTA output convention for the cycle and stay consistent. The package project searches
the explicit-target binary first, then the host-target binary. A stale explicit-target binary can
therefore shadow a fresh host-target build during packaging.

Then build Terminal:

```powershell
cmd.exe /d /c "tools\razzle.cmd && bcz no_clean"
```

For Visual Studio debugging, use `CascadiaPackage` as the startup project.

### 14.4 Runtime data and logs

Packaged state and cache are package-family-private:

```text
%LOCALAPPDATA%/Packages/<PFN>/LocalState/IntelligentTerminal/
%LOCALAPPDATA%/Packages/<PFN>/LocalCache/Local/IntelligentTerminal/
```

Logs live under the cache root in `logs/<package-version>/`. Important files:

- `wta-main_master.log`: agent spawn, helper routing, session ownership;
- `wta-main_helper-<pid>.log`: helper pipe, ACP session, prompt/UI lifecycle;
- `wta-cli.log`: short-lived WTA CLI commands;
- `wta-delegate.log`: `?<prompt>` delegation;
- `wta-probe.log`: provider probes;
- `wta-install-hooks.log`: hooks installation;
- `wta-ensure-host.log`: SharedWta/background-host lifecycle;
- `wta-acp-debug.log`: low-level ACP trace;
- `terminal-agent-pane.log`: C++ agent-pane path;
- `hook-trace.log`: PowerShell hook path.

Unpackaged Cargo runs and tests have no package identity. Their state/cache roots collapse to:

```text
%LOCALAPPDATA%/IntelligentTerminal/
%LOCALAPPDATA%/IntelligentTerminal/logs/
```

Unpackaged logs are flat rather than grouped under a package-version subdirectory.

Set `WTA_LOG` or `RUST_LOG` to control Rust log level. Debug builds default to `debug`; release
builds default to `info`. Usage values must remain absent from normal diagnostics even when tracing
other ACP flow.

### 14.5 Current relevant settings

```jsonc
{
    "acpAgent": "copilot",
    "acpModel": "",
    "acpCustomCommand": "",
    "agentPanePosition": "bottom",
    "delegateAgent": "copilot",
    "delegateModel": "",
    "delegateCustomCommand": "",
    "showTokenUsageAndCost": false
}
```

Use setting-model APIs rather than editing JSON ad hoc in product code. Respect GPO-filtered agent
lists and custom-agent policy.

## 15. Definition of Done for a Follow-up Step

A follow-up step is done only when:

- the behavior matches this product contract or an explicitly recorded new decision;
- focused RED and GREEN evidence exists;
- the relevant full test/build surface passes;
- logs and telemetry contain no Usage values;
- localization/accessibility are updated when UI copy or controls change;
- local E2E evidence is preserved but sensitive/ignored artifacts are not accidentally committed;
- dev and publish scopes are correct;
- commits are pushed and the branch is synchronized;
- this handoff is updated so the next branch can continue without reconstructing the history.
