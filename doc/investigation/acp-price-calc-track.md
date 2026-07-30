# ACP Usage / Cost Implementation Track

This file records completed, tested implementation steps for
[acp-price-calc.md](acp-price-calc.md). Each completed step is committed and pushed with the
code it describes.

## Scope Guardrails

- First release displays only standard ACP v1 `SessionUpdate::UsageUpdate` context-window data and
  optional monetary cost.
- No end-turn input/output display, private Gemini quota parsing, local price conversion,
  credential access, billing API calls, or currency correction.
- Rust owns validation, normalization, state, coalescing, and projection. C++/XAML only cache and
  render normalized data.
- Development paths fail fast. One outer Usage containment boundary is added only after the inner
  pipeline and tests are complete.
- Existing unit/integration frameworks are committed. The local desktop E2E orchestration,
  screenshots, provider configs, and wire captures remain under git-ignored
  `test/e2e/artifacts/` or the user profile and are not committed.
- E2E requires PowerShell 7.2+ through the existing portable harness. Commands resolve `pwsh`
  from PATH; child processes that need the same host reuse the current process executable.

## TDD Plan

| Step | RED test | Smallest GREEN implementation | Status |
|---|---|---|---|
| 0. Provider/build baseline | Existing registry, coordinator, WSL ACP, ItE2E, and live provider gates | Pin verified adapters and preserve historical command identification | Complete |
| 1. Reliable master delivery | Saturated helper queue must retain only the latest `UsageUpdate` | Per-session latest-value state and helper wake/drain path | Complete |
| 2. Standard normalizer | Valid ACP usage normalizes; zero size, non-finite/negative cost, and invalid currency fail | Provider-neutral domain types and stable ACP normalizer | Complete |
| 3. Helper dispatch | `SessionNotification::UsageUpdate` emits a typed app event; malformed input returns `Err` | Route normalizer output through existing `AppEvent` channel and store it on the owner tab | Complete |
| 4. Session lifecycle | Cumulative session usage replaces prior values and clears on new/load/agent identity boundaries | Apply explicit reset rules while model changes preserve usage | Complete |
| 5. Existing state projection | `agent_state_changed` contains normalized usage or explicit null | Extend `project_tab_state`; no new COM/IDL route | Complete |
| 6. C++ cache/parser | Routed normalized JSON updates or clears the correct tab cache | Extend `OnAgentStateChanged` and `AgentPaneContent` | Complete |
| 7. Bottom Bar UI | C++/XAML tests assert hidden/visible/format/accessibility states | Add right-aligned `UsageGroup` before Session button | Complete |
| 8. Outer containment/privacy | Usage failure hides only Usage; logs contain no values | Add one outer boundary and usage-specific redaction | Complete |
| 9. Final integration | Rust full suite, x64 Debug build, and local ignored E2E | Verify end-to-end behavior and update design/current-state tables | Complete |
| 10. Partial/error UI states | Cost-only, tokens-only, malformed, and absent reports never crash UI | Add one tested primary-display state and deterministic local mocks | Complete |
| 11. Provider extension boundary | Every known family has a module; unverified private payloads yield no data | Add a typed provider registry with empty trust allowlists | Complete |
| 12. PowerShell 7 E2E host | Historical fixed-install-path implementation | Superseded by portable Step 30 | Superseded |
| 13. Token breakdown Bottom Bar | Input/output metrics render as `(in)`/`(out)` with reported cost in a bounded third slot | Extend only the pure C++ display policy | Complete |
| 14. Standard turn Usage and Gemini runtime | Independent metrics merge; standard end-turn Usage wins; exact Gemini private identity is the only fallback | Extend the Rust domain, wire prompt responses, and use the official Gemini ACP launch | Complete |
| 15. Self-contained provider capture harness | Missing script and command/question/output drift fail the local contract | One PowerShell 7 JSON-RPC client with the five exact prototype commands | Complete |
| 16. Real provider comparison results | Missing, malformed, mismatched-question, or credential-bearing results fail validation | Run all five local ACP agents and save one sanitized JSON result each | Complete |
| 17. Dynamic same-session provider turns | Fixed one-question plans and stale result files fail the harness contract | Drive an indexed question array in one session per provider and clean result before capture | Complete |
| 18. Two-turn provider comparison results | Missing rounds or different session IDs fail result validation | Regenerate ten real ACP JSON files and compare first/second-turn Usage | Complete |
| 19. Context/cost-only Bottom Bar | Input/output metrics must not render or keep Usage visible | Select only context-window and monetary-cost metrics in the pure C++ display policy | Complete |
| 20. ACP-only runtime policy | Standard context/cost continues; turn-token and Gemini-private paths produce no Usage | Remove token runtime ingestion and private Gemini behavior while retaining provider interfaces | Complete |
| 21. Provider-owned context capacity | Zero-size and over-capacity gauges must route unchanged and keep chat flowing | Remove client-side context ratio rejection while retaining independent cost validation | Complete |
| 22. Provider-rejected turn recovery | A prompt protocol error must be visible without failing its healthy session | Keep `Protocol` failures connected while ending only the rejected turn | Complete |
| 23. Optional cost isolation | Invalid optional cost must not discard valid context or log values | Make context normalization infallible and omit only invalid cost | Complete |
| 24. Local clear preserves Usage | `/clear` must not hide the unchanged provider session's context/cost | Move Usage resets from chat clearing to explicit ACP session boundaries | Complete |
| 25. Metric-aware master coalescing | New pending context must not erase an undelivered optional cost | Merge pending context/cost semantics before latest-value replacement | Complete |
| 26. Per-metric stale state | Transport loss must not present retained Usage as current | Track context/cost freshness independently and hide stale primary metrics | Complete |
| 27. Provider-reported currency | Non-uppercase or non-three-character currency must pass through unchanged | Remove application-level currency shape policy | Complete |
| 28. Main integration | Main's WTA module extraction must retain every Usage contract and pass full desktop/provider validation | Merge main, migrate code/tests to new owners, repair stale launch assertions | Complete |
| 29. Compact cost display | Main bar must show two-decimal cost without losing reported precision | Add exact decimal rounding plus full-value tooltip/HelpText | Complete |
| 30. Portable PowerShell host | Tracked files must not contain a machine-specific pwsh installation path | Restore main's PATH/current-host behavior and keep local harnesses ignored | Complete |
| 31. One-click packaged installer | Plan must be portable and clean x64 build must produce a signed validated MSIX ZIP | Add dynamic tool discovery, ordered dependencies, signing, and ZIP verification | Complete |
| 32. Provider-neutral Gemini coverage | Tests must not freeze a temporary Gemini compatibility gap as a vendor-specific exclusion | Remove Gemini-negative cases while retaining standard ACP and generic private-metadata contracts | Complete |
| 33. Default-off Usage preference | Valid context/cost must stay hidden by default and appear only when the persisted preference is enabled | Add `showAgentUsage` and gate only the Bottom Bar display projection | Complete |
| 34. Settings Usage toggle | Settings > Agents must expose a localized two-way toggle for the shared preference | Reuse the projected-setting macro and existing SettingContainer pattern | Complete |
| 35. First-run Usage toggle | FRE must initialize and save the same default-off preference | Follow the existing FRE card/code-behind pattern without duplicating setting state | Complete |
| 36. Token-only visibility semantics | Turning token usage off must not suppress separately reported monetary cost | Filter only context-window tokens and rename the preference/UI contract to `showTokenUsage` | Complete |
| 37. Packaged toggle E2E | Both UI entry points and Bottom Bar behavior must work in the deployed package | Add existing-framework UI contracts, stable automation ID, and settings-reload re-projection | Complete |
| 38. Final design sync | Final PM toggle semantics and both UI ownership paths must be documented as current behavior | Update status, current-state table, UI contract, and implemented scope | Complete |
| 39. Whole Usage group visibility | Turning the toggle off must hide both context tokens and monetary cost | Gate the complete display projection before selecting either metric | Complete |
| 40. Explicit usage-and-cost contract | Setting, controls, and text must state that both metrics are controlled | Rename to `showTokenUsageAndCost` and “Show token usage and cost” | Complete |

## Completed Steps

> Steps 13-14 record an earlier prototype decision to display turn token breakdown and parse
> Gemini private quota. Step 19-20 supersede that product behavior after the five-provider,
> two-turn investigation and team review. Step 27 supersedes Step 23's currency-shape filtering;
> amount validity and metric isolation remain unchanged. Step 30 supersedes Step 12's fixed
> PowerShell installation path.

### Step 40 - Explicit Usage-and-Cost Contract

**RED**

- Changed the SettingsModel test to require the `showTokenUsageAndCost` JSON key and
  `ShowTokenUsageAndCost` WinRT property.
- Compilation failed because the interim token-only setting property did not satisfy that public
  contract.

**GREEN**

- Renamed the new, not-yet-released setting to `showTokenUsageAndCost`, retaining default `false`.
  No compatibility alias or migration is needed within this unshipped feature branch.
- Renamed Settings/FRE view-model properties, XAML elements, automation IDs, resource keys,
  diagnostics, and tracked ItE2E selectors to the explicit usage-and-cost terminology.
- Updated visible UI text to “Show token usage and cost” and descriptions to state that both
  context-window token usage and monetary cost appear in the Bottom Bar.
- Updated local ignored Usage/E2E scripts to set the new key explicitly.

**Validation**

- Focused `showTokenUsageAndCost` SettingsModel test: 1 passed, 0 failed.
- AgentUsage test class: 18 passed, 0 failed.
- CustomAgentAndPolicy test class: 26 passed, 0 failed.
- SettingsEditor and TerminalApp focused builds: 0 errors.
- Resource contracts: SettingsEditor 16/16 and TerminalApp 89/89 locale files retain BOM/XML and
  contain exactly the new two-key family.
- Source audit found no interim product-code setting/property/control/resource identifiers.
- Editor diagnostics and CRLF-aware patch whitespace check: clean.

**Committed files**

- `src/cascadia/TerminalSettingsModel/MTSMSettings.h`
- `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/TerminalApp/FreOverlay.{xaml,cpp}`
- `src/cascadia/TerminalSettingsEditor/AIAgents.xaml`
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.{h,idl}`
- `src/cascadia/TerminalApp/Resources/*/Resources.resw`
- `src/cascadia/TerminalSettingsEditor/Resources/*/Resources.resw`
- `src/cascadia/UnitTests_SettingsModel/CustomAgentAndPolicyTests.cpp`
- `test/e2e/tests/Feature.FreAgentSetup.Tests.ps1`
- `test/e2e/tests/Feature.SettingsUi.Tests.ps1`
- `doc/investigation/acp-price-calc-track.md`

### Step 39 - Whole Usage Group Visibility

**Scope correction**

- Product clarification established that “token usage” in the PM request names the complete
  token-usage-and-cost surface, not a request to leave monetary cost visible independently.
- This step supersedes Step 36's token-only display behavior. Provider data reception and caching
  remain unchanged; only the complete Bottom Bar Usage projection is hidden while disabled.

**RED**

- Changed the pure display contract to require a snapshot containing valid context and cost to
  return no items and `visible=false` when the preference is disabled.
- The focused test failed because the token-only implementation still returned the cost item.

**GREEN**

- Renamed the pure display parameter to `showUsageAndCost` and restored an early empty return when
  disabled.
- Removed token-specific filtering from metric selection; when enabled, the existing independent
  context/cost availability and stale rules still apply.

**Validation**

- Focused whole-group display test: 1 passed, 0 failed.
- AgentUsage test class: 18 passed, 0 failed.
- Terminal App unit-test project build: 0 errors.
- Editor diagnostics and CRLF-aware patch whitespace check: clean.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h`
- `src/cascadia/TerminalApp/AgentUsage.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`

### Step 38 - Final Design Sync

**Review**

- Re-read `acp-price-calc.md` after packaged E2E. It still ended at Step 29 and did not record the
  PM's default-off token setting, the two UI entry points, token-only filtering, or immediate cache
  re-projection.

**Update**

- Updated status/date and the current repository facts.
- Documented `showTokenUsage=false`, monetary-cost independence, data/cache behavior, settings hot
  reload, and the shared-model/separate-UI ownership of FRE versus Settings.
- Updated the implemented minimum scope without rewriting the earlier provider investigation or
  superseded prototype history.

**Validation**

- Cross-checked every documented symbol/key against the final compiled code and packaged E2E
  results from Steps 33-37.
- Markdown link/path and CRLF-aware patch whitespace checks: clean.

**Committed files**

- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 37 - Packaged Toggle E2E

**RED**

- Added existing ItE2E feature tests requiring the FRE token toggle to exist and default Off, and
  the Settings toggle to default Off and persist `showTokenUsage=true` through the real Save flow.
- Against the previously deployed package, the FRE test failed because `ShowTokenUsageToggle` did
  not exist. The Settings tests were environment-skipped because VS Code retained foreground and
  the existing keyboard accelerator could not open Settings.
- A local ignored UIA flow bypassed that foreground dependency and found a second behavior RED:
  changing `showTokenUsage` to true persisted correctly but did not reveal cached context Usage
  until another agent event arrived.

**GREEN**

- Added a stable `ShowTokenUsageToggle` automation ID to the Settings toggle and made the existing
  framework test follow the product's Toggle -> Save persistence flow.
- `_RefreshUIForSettingsReload` now calls the existing `_UpdateBottomBarState`, re-projecting
  cached per-tab Usage after presentation-only settings change. No provider event or duplicate
  cache is needed.
- Reused the existing ItE2E framework for committed tests. The UIA-only Settings opener, package
  deployment orchestration, wire injection, scripts, results, and screenshots remain ignored under
  `test/e2e/artifacts/token-usage-toggle/`.

**Validation**

- Full Debug WTA + CascadiaPackage build succeeded; the deployed WTA SHA256 matched the Cargo
  output. The initially installed signed MSIX could not use `Remove-AppxPackage
  -PreserveApplicationData`, so its LocalState was backed up, checked 6/6 files, deployed as a
  development layout, restored, and verified file-by-file by SHA256.
- Committed Settings/FRE feature files against final Dev package: 5 passed, 0 failed, 3 skipped.
  The skips are the pre-existing foreground-keyboard Settings cases; the equivalent pure-UIA local
  flow passed.
- Local ignored UIA E2E:
  - FRE toggle visible and Off by default.
  - Settings toggle visible and Off by default; Toggle -> Save persisted `showTokenUsage=true`.
  - Token Off with injected context+cost: cost visible, context hidden.
  - Token On by settings hot reload with no new provider event: cached context and cost visible.
- AgentUsage tests: 18 passed, 0 failed. CustomAgentAndPolicy tests: 26 passed, 0 failed.
- TerminalApp and SettingsEditor focused builds: 0 errors. Editor diagnostics and CRLF-aware patch
  whitespace check: clean.
- Screenshot review passed with no overlap or clipping:
  - `test/e2e/artifacts/token-usage-toggle/fre-token-usage-off.png`
  - `test/e2e/artifacts/token-usage-toggle/settings-token-usage-off.png`
  - `test/e2e/artifacts/token-usage-toggle/settings-token-usage-on.png`
  - `test/e2e/artifacts/token-usage-toggle/bottom-bar-token-usage-off.png`
  - `test/e2e/artifacts/token-usage-toggle/bottom-bar-token-usage-on.png`

**Committed files**

- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/TerminalSettingsEditor/AIAgents.xaml`
- `test/e2e/tests/Feature.FreAgentSetup.Tests.ps1`
- `test/e2e/tests/Feature.SettingsUi.Tests.ps1`
- `doc/investigation/acp-price-calc-track.md`

### Step 36 - Token-Only Visibility Semantics

**Scope correction**

- The PM requirement says token usage is hidden by default. Steps 33-35 initially interpreted the
  preference as controlling the complete context/cost group, which also hid monetary cost.
- This step supersedes that intermediate semantic: the toggle controls only context-window token
  usage. Monetary cost remains visible whenever it is independently reported and current.

**RED**

- Changed the pure display contract to require one retained cost item when token visibility is
  disabled for a snapshot containing both context and cost. It failed because the display was
  completely hidden.
- Changed the SettingsModel contract to require the token-specific `showTokenUsage` JSON key and
  `ShowTokenUsage` property. Compilation failed because only the broader interim property existed.

**GREEN**

- Moved the preference into metric selection: disabled token visibility skips only
  `acp.context.window`; `acp.billing.cost` continues through the existing formatting, tooltip, and
  accessibility paths.
- Renamed the new persisted setting and WinRT/UI bindings from `showAgentUsage` to
  `showTokenUsage`, retaining the required default of `false`.
- Renamed both Settings and FRE controls/resources to token-specific identifiers and wording.
  Existing reviewed locale values were updated to token-specific translations; other FRE locales
  retain the safe English fallback pending the formal localization pipeline.

**Validation**

- Focused token-only display test: 1 passed, 0 failed.
- Focused `showTokenUsage` SettingsModel test: 1 passed, 0 failed.
- AgentUsage test class: 18 passed, 0 failed.
- CustomAgentAndPolicy test class: 26 passed, 0 failed.
- SettingsEditor and TerminalApp focused builds: 0 errors.
- Token resource contracts: SettingsEditor 16/16 and TerminalApp 89/89 locale files retain BOM/XML,
  contain exactly the new two-key family, and contain no interim resource keys.
- Source audit found no remaining `ShowAgentUsage`, `showAgentUsage`, or old UI resource/accessor
  identifiers.

**Committed files**

- `src/cascadia/TerminalSettingsModel/MTSMSettings.h`
- `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`
- `src/cascadia/TerminalApp/AgentUsage.{h,cpp}`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/TerminalApp/FreOverlay.{xaml,cpp}`
- `src/cascadia/TerminalSettingsEditor/AIAgents.xaml`
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.{h,idl}`
- `src/cascadia/TerminalApp/Resources/*/Resources.resw`
- `src/cascadia/TerminalSettingsEditor/Resources/*/Resources.resw`
- `src/cascadia/UnitTests_SettingsModel/CustomAgentAndPolicyTests.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`

### Step 35 - First-Run Usage Toggle

**RED**

- Added FRE code-behind initialization, accessibility, persistence, and diagnostic references to
  `ShowUsageToggle` before the XAML element existed.
- The focused TerminalApp build failed with six C3861 errors because the generated
  `ShowUsageToggle` accessor was missing.

**GREEN**

- Added a first-run `Border/Grid/ToggleSwitch` card matching the existing FRE settings form. The
  toggle defaults Off in XAML, initializes from `GlobalAppSettings.ShowAgentUsage`, and writes the
  same setting during the existing Save flow.
- Added localized accessibility naming and On/Off content through the existing FRE resource and
  code-behind patterns.
- Added both resource keys to every discovered TerminalApp locale with `XmlDocument`. Sixteen
  locales reuse the reviewed SettingsEditor translations; the remaining locales use an accurate
  English fallback pending the repository's formal localization pipeline rather than committing
  unreviewed machine translations.
- No shared UI abstraction was introduced: FRE and Settings retain their existing separate UI
  ownership while sharing the settings-model source of truth.

**Validation**

- TerminalApp focused build: 0 errors; the generated XAML accessor and code-behind compiled.
- FRE resource contract: 89/89 discovered locale files are well-formed XML, retain UTF-8 BOMs,
  and contain exactly the two `FreOverlay_ShowUsage` keys.
- Resource diff audit: each locale has exactly two added resource entries and no unrelated XML
  normalization churn.
- CRLF-aware patch whitespace check and editor diagnostics: clean.

**Committed files**

- `src/cascadia/TerminalApp/FreOverlay.xaml`
- `src/cascadia/TerminalApp/FreOverlay.cpp`
- `src/cascadia/TerminalApp/Resources/*/Resources.resw`
- `doc/investigation/acp-price-calc-track.md`

### Step 34 - Settings Usage Toggle

**RED**

- Added a `SettingContainer` and `ToggleSwitch` in Settings > Agents bound two-way to
  `ViewModel.ShowAgentUsage` before that view-model property existed.
- The focused SettingsEditor build failed with XAML compiler error WMC1110: property
  `ShowAgentUsage` was not found on `AIAgentsViewModel`.

**GREEN**

- Projected `GlobalAppSettings.ShowAgentUsage` through `AIAgentsViewModel` using the existing
  `PERMANENT_OBSERVABLE_PROJECTED_SETTING` pattern. The generated setter writes directly to the
  shared settings model and raises the existing property-changed notifications.
- Added the toggle to the Agent pane group, immediately after pane position, using the existing
  `SettingContainer + ToggleSwitch` layout and a two-way binding.
- Added title and help text to every discovered SettingsEditor locale. Resource files were edited
  with `XmlDocument`, retain UTF-8 BOMs, and include translator comments.

**Validation**

- SettingsEditor focused build: 0 errors; the new XAML binding compiled successfully.
- Localized resource contract: 16/16 discovered locale files are well-formed XML, retain their
  UTF-8 BOM, and contain exactly the two `AIAgents_ShowAgentUsage` keys.
- CRLF-aware patch whitespace check and editor diagnostics: clean.

**Committed files**

- `src/cascadia/TerminalSettingsEditor/AIAgents.xaml`
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.h`
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.idl`
- `src/cascadia/TerminalSettingsEditor/Resources/*/Resources.resw`
- `doc/investigation/acp-price-calc-track.md`

### Step 33 - Default-Off Usage Preference

**Investigation**

- The first-run experience and Settings > Agents share `GlobalAppSettings`, but not UI controls
  or view models. FRE uses `FreOverlay.xaml` with direct code-behind reads/writes; Settings uses
  `AIAgents.xaml` with `AIAgentsViewModel` bindings.
- This feature follows those existing ownership boundaries. A future refactor may extract shared
  agent-setting controls, but this feature does not introduce that architectural change.
- Context-window usage and monetary cost currently share one Bottom Bar `UsageGroup`. The
  preference controls that complete group while ACP data continues to be received and cached.

**RED**

- Added a SettingsModel contract requiring `showAgentUsage` to default to `false` and round-trip
  an explicit `true` value.
- Added an AgentUsage contract requiring valid context and cost to produce an empty, hidden
  display when disabled and the existing two display items when enabled.
- The first focused build failed with C2660 because `BuildPrimaryDisplay` did not accept the new
  visibility input.

**GREEN**

- Added the inheritable global `showAgentUsage` setting with a default of `false`.
- Extended the pure AgentUsage display projection with a visibility input. Disabled display
  returns no items, while parsing, ACP routing, and per-pane Usage caching remain unchanged.
- Passed the current setting from `TerminalPage` into the Bottom Bar display projection, so
  enabling the preference can reveal already-reported data without waiting for another turn.

**Validation**

- Terminal App unit-test project build: 0 errors.
- SettingsModel unit-test project build: 0 errors.
- AgentUsage test class: 18 passed, 0 failed.
- CustomAgentAndPolicy test class: 26 passed, 0 failed.
- CRLF-aware patch whitespace check and editor diagnostics: clean.

**Committed files**

- `src/cascadia/TerminalSettingsModel/MTSMSettings.h`
- `src/cascadia/TerminalSettingsModel/GlobalAppSettings.idl`
- `src/cascadia/TerminalApp/AgentUsage.h`
- `src/cascadia/TerminalApp/AgentUsage.cpp`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/UnitTests_SettingsModel/CustomAgentAndPolicyTests.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`

### Step 32 - Provider-Neutral Gemini Coverage

**RED**

- A focused source audit found dedicated Gemini-private quota mock behavior and three adapter tests
  whose only assertion was that Gemini usage did not surface.
- These cases duplicated the provider-neutral private-metadata boundary and made a temporary
  interoperability state look like a permanent vendor-specific product contract.

**GREEN**

- Removed the Gemini-private prompt-response mock behavior and its negative dispatch test.
- Removed the Gemini adapter's dedicated negative test module while retaining the adapter as a
  future extension point.
- Kept the provider-neutral positive ACP `UsageUpdate` routing test and the registry-wide contract
  that unverified private metadata does not invent usage for any provider.
- Product behavior is unchanged: standard ACP context/cost is accepted without provider-specific
  gating, including when Gemini emits it in a future compatible release.

**Validation**

- `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml usage`:
  22 passed, 0 failed.
- Full WTA Rust suite: 1,222 passed, 0 failed.
- Focused source audit found no remaining Gemini-private negative mock/test identifiers.
- Generic contracts `session_notification_routes_usage_update` and
  `provider_adapters_do_not_invent_unverified_private_usage` remain present and passing.
- `rustfmt --check` passes for the remaining Gemini adapter. The mock file has unrelated existing
  whole-file formatting drift, so this deletion-only step intentionally does not reformat it;
  patch whitespace and editor diagnostics are clean.

**Committed files**

- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/usage/providers/gemini.rs`
- `doc/investigation/acp-price-calc-track.md`

### Step 31 - One-Click Packaged Installer

**RED**

- Added existing Pester unit contracts requiring a tracked installer script, manifest-derived
  version/output paths, x64 and ARM64 target mapping, and no machine-specific installation paths.
- RED failed 3/3 because `build/scripts/New-LocalMsixInstaller.ps1` did not exist.
- The first complete x64 run exposed a clean-build dependency failure: direct project builds did
  not apply the solution-level `OpenConsoleProxy` dependency, so `ITerminalHandoff.h` was missing.

**GREEN**

- Added `New-LocalMsixInstaller.ps1`, defaulting to x64 Release, with dynamic discovery of
  PATH-resolved Cargo, repository MSBuild setup, and the newest registered Windows SDK x64
  `mdmerge.exe` / `signtool.exe` tools.
- The script reads package version/publisher from `Package-Dev.appxmanifest`; it contains no fixed
  Visual Studio edition, drive, SDK version, package version, or PowerShell install directory.
- Explicitly passes `MdMergePath`, `WindowsSDK_ExecutablePath`, and `ExecutablePath` to nested
  MSBuild invocations, preventing the previously observed `mdmerge` exit 9009.
- Prebuilds `Host.Proxy.vcxproj`, Settings Model, and Settings Editor before CascadiaPackage so
  generated handoff headers, WinMD projections, and XBF files exist deterministically.
- Creates/reuses a local matching PFX/CER pair, validates publisher/thumbprint/expiry, signs the
  exact manifest-version MSIX, assembles the ZIP, checks required entries, and rejects any PFX in
  the distributable.

**Validation**

- Plan/portability Pester contracts: 3 passed, 0 failed.
- PowerShell parser and editor diagnostics: clean.
- First complete x64 run RED: missing `ITerminalHandoff.h`; no `mdmerge` 9009 occurred.
- Corrected complete x64 Release run: WTA, OpenConsoleProxy, Settings Model, Settings Editor,
  CascadiaPackage, signing, and ZIP assembly all succeeded.
- Full ItE2E Unit suite: 14 passed, 0 failed. The documented no-restore/no-rebuild fast path also
  re-signed and reassembled the existing package successfully.
- Final output ZIP: `intelligent-terminal-0.8.0.2-x64-msix.zip`, 20,250,144 bytes, SHA256
  `6AA4FD8C92E22EC8A56322E182E3C49892CA7DE87B9363871C9259AF3CE91E07`.
- ZIP contains signed MSIX, public CER, x64 XAML dependency, `Install-Msix.ps1`, and FRE reset;
  no PFX. MSIX identity is `IntelligentTerminal 0.8.0.2 x64`, contains `wtcli.exe` and a signature
  entry, and its embedded WTA hash matches the x64 Release WTA artifact.

**Committed files**

- `build/scripts/New-LocalMsixInstaller.ps1`
- `test/e2e/selftests/LocalMsixInstaller.Unit.Tests.ps1`
- `doc/building-installer.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 30 - Portable PowerShell Host

**RED**

- Added a tracked-file portability audit requiring no exact machine-specific PowerShell install
  path under `test/e2e`, `doc/investigation`, or `AGENTS.md`.
- RED found 40 tracked occurrences, including shared ItE2E runners, bootstrap, policy tools,
  self-tests, examples, and feature documentation.

**GREEN**

- Restored 12 shared `test/e2e` framework files to `main` instead of carrying a feature-PR test
  framework fork. Main resolves `pwsh` from PATH and uses the current process executable when an
  elevated child must run under the same host.
- Removed fixed installation paths from task instructions, provider-capture examples, and current
  design/guardrail text. PowerShell 7.2+ remains required by the existing module manifest.
- Updated the ignored local build/deploy script to validate `PSEdition=Core` and major version 7+
  without assuming an installation directory. Local E2E scripts and screenshots remain ignored.

**Validation**

- RED tracked portability audit: 40 hard-coded occurrences.
- GREEN tracked portability audit: 0 hard-coded occurrences.
- Shared ItE2E PowerShell files parse successfully.
- ItE2E unit self-tests and bootstrap `-Check` run under PATH-resolved `pwsh`.

**Committed files**

- Restored shared `test/e2e` files from `main`.
- `AGENTS.md`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`
- `doc/investigation/per-provider-investigation/README.md`
- Local ignored `test/e2e/artifacts/devops/Build-Deploy-Launch-Local.ps1` remains uncommitted.

### Step 29 - Compact Cost Display

**RED**

- Added pure C++ display contracts requiring `1.235 -> 1.24`, `1.234 -> 1.23`, positive
  `0.004 -> <0.01`, and exact zero `0 -> 0.00` in the Bottom Bar.
- Required each cost display item to retain the full provider-reported text (`1.235 USD`,
  `0.004 USD`, etc.) separately for hover and accessibility.
- The focused build failed because `PrimaryDisplay` had only a vector of strings and no per-item
  `text` / `fullText` contract.

**GREEN**

- Replaced primary display strings with typed `PrimaryDisplayItem { text, fullText }`; retained
  `BuildPrimaryDisplayTexts` as a compatibility projection for existing pure-format tests.
- Cost formatting uses decimal-string rounding rather than binary floating-point conversion, so
  half-up behavior is deterministic for provider text. Context values remain unmodified.
- Positive values below one cent display `<0.01 <currency>` instead of the misleading
  `0.00 <currency>`; exact zero displays `0.00 <currency>`.
- Each cost TextBlock receives the complete provider value through XAML Tooltip and
  `AutomationProperties.HelpText`. Rust state, ACP payload precision, currency, and cost
  aggregation semantics are unchanged.

**Validation**

- RED focused C++ build failed on missing `PrimaryDisplay::items` / `fullText`.
- GREEN cost-rounding/full-text test: 1 passed, 0 failed.
- Full `AgentUsageTests`: 17 passed, 0 failed, 0 skipped.
- x64 Debug WTA and CascadiaPackage build/deploy/launch succeeded; deployed WTA SHA256:
  `AF272C68B606EDED5A553A00C2CBC22DC2412D613C6260CD1B3E7C6547C2ACD0`.
- Synthetic full desktop pipeline displayed `<0.01 USD`, exposed exact UIA HelpText
  `0.004 USD`, and showed the same full value in the real hover Tooltip. Context-only follow-up
  retained both the compact display and exact full value. Local ignored screenshot:
  `test/e2e/artifacts/step9-usage/full-pipeline-cost-tooltip.png`.
- Synthetic cost-only, context-only, over-capacity, and no-Usage desktop scenarios all passed;
  chat continued, the process stayed alive, and each produced a local ignored screenshot.
- Real OpenCode `opencode/deepseek-v4-flash-free` displayed `11923 / 200000 Tokens` and exact-zero
  `0.00 USD`; input/output token breakdown remained hidden. Local ignored screenshot:
  `test/e2e/artifacts/opencode-acp/opencode-context-cost.png`.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h`
- `src/cascadia/TerminalApp/AgentUsage.cpp`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 28 - Main Integration

**Merge and conflicts**

- Merged `main` at `84c4d7da5` into `user/DinahK-2SO/acp-price-calc`.
- Resolved three content conflicts: `test/e2e/README.md`, `tools/wta/src/app.rs`, and
  `tools/wta/src/master/mod.rs`.
- Main had extracted the large App and Master files. Adopted that structure and migrated Usage
  contracts/events to `app_contracts/event.rs`, handling to `app_events.rs`, projection to
  `app_status_projection.rs`, App tests to `app_tests.rs`, and Master tests to `master/tests.rs`.
- Preserved main's PowerShell/UI documentation while retaining the repository-required absolute
  PowerShell 7 path.

**Integration RED and GREEN**

- The first full merged Rust run failed 5 tests because main's newly extracted Master tests still
  expected deprecated `gemini --experimental-acp`; production and the existing registry correctly
  returned the previously verified official `gemini --acp`. Updated only the stale assertions.
- The next Master run failed 1 test because the extracted assertion omitted the branch's pinned
  Claude adapter version. Updated it to `@agentclientprotocol/claude-agent-acp@0.59.0`.
- Migrated the complete provider-owned Usage test surface into main's new test owners, including
  owner-tab routing, independent metric merge, lifecycle boundaries, protocol-error recovery,
  per-metric stale state, reliable coalescing, and route-rebind cleanup.
- Updated ignored local desktop fixtures to the final contract: over-capacity context is displayed,
  prior cost is retained, and normalized cost-only injection uses canonical `acp.billing.cost`.
  These local scripts/screenshots remain uncommitted as required.

**Validation**

- Merged WTA test target compiled successfully with `cargo test --no-run`.
- Focused Usage/provider, helper dispatch, App lifecycle/recovery/stale, and Master coalescing/rebind
  tests all passed and were discovered by the merged test binary.
- Master module: 64 passed, 0 failed.
- Full WTA Rust suite: 1226 passed, 0 failed.
- `AgentUsageTests`: 16 passed, 0 failed, 0 skipped.
- x64 Debug WTA and CascadiaPackage build/deploy/launch succeeded from merged source. Deployed
  package: `IntelligentTerminal_0.8.0.2_x64__rd9vj3e6a2mbr`; WTA SHA256:
  `06B7E64C6993651496F3094355FC5EBCAC60A4CC47F9B36110F5DAE36F256456`.
- Synthetic full pipeline passed: over-capacity `987654321 / 123456789 Tokens` displayed while
  `0.004 USD` remained visible and both chat turns survived.
- Synthetic edge cases passed: cost-only, context-only, over-capacity, and no-Usage; every process
  stayed alive and each scenario produced a screenshot.
- Real Gemini `gemini-3.1-flash-lite`: prompt completed and private quota remained hidden.
- Real OpenCode 1.18.3 `opencode/deepseek-v4-flash-free`: displayed
  `11925 / 200000 Tokens` and reported `0 USD`; input/output breakdown remained hidden.
- Visual inspection confirmed the Bottom Bar contents above and found no overlap.

**Committed files**

- Merge from `main` plus conflict resolutions.
- `tools/wta/src/{app,app_events,app_status_projection,app_tests}.rs`
- `tools/wta/src/app_contracts/event.rs`
- `tools/wta/src/master/{mod,tests}.rs`
- `test/e2e/README.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 27 - Provider-Reported Currency

**RED**

- Replaced the currency-omission test with a pass-through contract covering `US`, `USDD`, `usd`,
  `US1`, and `U$D`.
- The focused test failed on the first value because the normalizer omitted its cost solely for
  not matching the application's three-uppercase-ASCII-letter policy.

**GREEN**

- Removed currency length and uppercase checks from standard ACP Usage normalization.
- WTA now preserves the provider-reported currency string unchanged and performs no correction,
  conversion, or semantic inference. This matches the existing OpenCode product decision.
- Cost amount must still be finite and non-negative before it can be displayed; invalid amount
  remains isolated from valid context.
- C++'s generic normalized-item length and non-empty checks remain cross-process UI safety bounds,
  not currency-format policy.

**Validation**

- RED currency pass-through test: 1 failed, 0 passed (`None` versus reported `US`).
- GREEN currency pass-through test: 1 passed, 0 failed.

**Committed files**

- `tools/wta/src/usage.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 26 - Per-Metric Stale State

**RED**

- Added an App-state test requiring transport loss to immediately project retained context and
  cost as stale, then requiring a context-only report after same-session reconnect to refresh only
  context while cost remains stale.
- The Rust RED failed because transport loss emitted no Usage projection and every projected item
  was hard-coded fresh.
- Added a C++ test with stale context plus fresh cost. It failed with two visible primary items
  instead of only the fresh cost.

**GREEN**

- Added per-tab, per-metric `UsageStaleness` separate from provider values. Transport loss marks
  only present metrics stale; each subsequent `UsageReported` refreshes only metrics it contains.
- New/load/restart/reset/session-id boundaries clear both values and freshness state. Local
  `/clear` preserves both.
- `agent_state_changed` projects the real context/cost stale flags instead of constant `false`.
- C++ retains stale items in the tab cache but excludes them from the primary Bottom Bar. A fresh
  sibling metric remains visible; when all reported metrics are stale the Usage group collapses
  until the provider reports again.

**Validation**

- RED Rust stale-state test: 1 failed, 0 passed (no stale projection).
- GREEN Rust stale-state test: 1 passed, 0 failed.
- RED C++ stale-display test: 1 failed, 0 passed (expected 1 item, received 2).
- GREEN C++ stale-display test: 1 passed, 0 failed.
- `AgentUsageTests`: 16 passed, 0 failed, 0 skipped.
- Rust Usage tests: 11 passed; lifecycle tests: 7 passed; stale-state test: 1 passed.
- Full WTA Rust suite: 1156 passed, 0 failed.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/app.rs`
- `src/cascadia/TerminalApp/AgentUsage.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 25 - Metric-Aware Master Coalescing

**RED**

- Strengthened the existing saturated-helper latest-value test with two same-session updates: the
  first reports context plus `0.004 USD`, and the newer update reports context only.
- The focused test failed with `cost: None`, proving whole-notification replacement discarded the
  undelivered optional metric before the helper's existing per-metric merge could see it.

**GREEN**

- Pending Usage still replaces context with the newest provider gauge for that SessionId.
- When a newer pending update omits optional cost, master now carries forward the same owner's
  undelivered cost; an explicitly reported newer cost continues to replace the old one.
- Session rebind still clears the old owner's pending entry before the new route becomes visible,
  so no metric crosses helper ownership.

**Validation**

- RED master coalescing test: 1 failed, 0 passed (`None` versus `0.004 USD`).
- GREEN master coalescing test: 1 passed, 0 failed.

**Committed files**

- `tools/wta/src/master/mod.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 24 - Local Clear Preserves Usage

**RED**

- Replaced the old generic clear-history expectation with a `/clear` command contract requiring
  the same ACP session's Usage snapshot to remain visible.
- The focused test failed because `TabSession::clear_chat_history` erased Usage even though
  `/clear` does not create, load, restart, or drop the provider session.

**GREEN**

- Removed Usage mutation from generic local chat-history clearing.
- Added explicit Usage resets at the actual session boundaries that reuse that helper: `/new`,
  `load_session`, `/restart`, and `reset_tab_session`; new SessionId binding already cleared it.
- Model changes and `/clear` preserve Usage because neither operation changes the provider-owned
  session context or cumulative cost.
- Added restart and reset regression guards so future local-chat refactors cannot leak old Usage
  across a real session replacement.

**Validation**

- RED `/clear` lifecycle test: 1 failed, 0 passed.
- First GREEN run exposed one reset placed on `/clear` instead of `/new`: 3 passed, 2 failed.
- Corrected lifecycle slice: 5 passed, 0 failed.
- Final lifecycle slice with restart/reset guards: 7 passed, 0 failed.

**Committed files**

- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 23 - Optional Cost Isolation

**RED**

- Replaced amount and currency rejection tests with contracts requiring valid context to survive
  non-finite, negative, or non-canonical optional cost values.
- Changed the helper privacy test to require `UsageReported` with context and no cost while still
  proving the token sentinels never enter logs.
- All three focused tests failed because cost validation rejected the entire `UsageUpdate`.

**GREEN**

- Made standard context normalization infallible after typed ACP deserialization: every provider
  `used`/`size` pair becomes the context snapshot without client capacity policy.
- Optional cost is attached only when its amount is finite and non-negative and its currency has
  the ACP three-uppercase-ASCII-letter shape; otherwise only that optional metric is omitted.
- Removed the helper's conversion of cost validation failures into ACP `invalid_params`, so cost
  cannot clear valid context or interfere with the notification stream.
- OpenCode's verified standard fixture continues to normalize its reported context and currency
  unchanged.

**Validation**

- RED optional-cost isolation tests: 3 failed, 0 passed.
- GREEN optional-cost isolation tests: 3 passed, 0 failed.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/protocol/acp/client.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/usage/providers/opencode.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 22 - Provider-Rejected Turn Recovery

**RED**

- Strengthened the existing typed protocol-error test to require the error line to remain visible,
  the turn to return to `Idle`, and the connection to remain `Connected`.
- The focused test failed because `AppEvent::AgentError` changed the global state to
  `Failed("protocol error")` even though `AgentFailure::Protocol` declares that the session lives.

**GREEN**

- `AgentFailure::Protocol` now leaves the current connection state unchanged while reusing the
  existing per-turn progress cleanup, `Idle` transition, duplicate suppression, and error line.
- Authentication, handshake, resource, and transport-loss recovery paths remain unchanged.
- A provider can therefore reject a context-heavy prompt without WTA declaring its still-live ACP
  session dead; capacity recovery remains provider-owned.

**Validation**

- RED protocol-error state test: 1 failed, 0 passed (`Failed` versus `Connected`).
- GREEN protocol-error state test: 1 passed, 0 failed.

**Committed files**

- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 21 - Provider-Owned Context Capacity

**RED**

- Replaced the old invalid-ratio test with provider-neutral contracts requiring both
  `used=1,size=0` and `used=101,size=100` to normalize unchanged.
- Added helper dispatch coverage requiring zero-size and over-capacity notifications to emit
  `UsageReported` and leave the following chat notification flowing.
- All three focused tests failed against the client-owned `size != 0` and `used <= size` checks.

**GREEN**

- Removed `ZeroContextSize` and `ContextUsedExceedsSize` from the Usage error taxonomy and deleted
  both relational checks from the standard ACP normalizer.
- Context Usage is now observational only: WTA preserves the provider's two non-negative ACP
  counters and does not infer rejection, compaction, or capacity policy from their relationship.
- Optional monetary-cost validation remains unchanged for the next isolated TDD step.

**Validation**

- RED context normalizer: 1 failed, 0 passed.
- RED helper dispatch tests: 2 failed, 0 passed.
- GREEN provider-owned context tests: 3 passed, 0 failed.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 20 - ACP-Only Context/Cost Runtime Policy

**RED**

- Changed the typed snapshot/projection contracts to context and cost only. The focused build
  failed because production still required `input_tokens` and `output_tokens` fields.
- Changed Gemini's provider contract to `StandardAcpOnly`, an empty trusted-reporter list, and
  no-op private quota extraction.
- Kept the real OpenCode 1.18.3 standard `UsageUpdate` fixture as a required context/cost GREEN
  path; its reported currency is consumed unchanged.

**GREEN**

- Removed optional input/output fields and projection metrics from the Rust Usage domain; merge
  still preserves independent optional context and monetary cost for future reviewed extensions.
- Disabled the ACP SDK end-turn token Usage feature and removed all PromptResponse token ingestion.
- Removed Gemini private quota runtime dispatch and changed its adapter to the same standard-only,
  no-op behavior as other providers without verified private context/cost schemas.
- Retained the provider registry, `ProviderUsageInput` variants (including PromptResponseMeta and
  already-fetched ProviderApiResponse), context/cost/custom metric contribution types, and Copilot
  `Reserved` policy for future standard or separately reviewed support.
- Kept Gemini's official `--acp` launch and non-Usage startup model compatibility; only its private
  Usage handling was removed.

**Validation**

- RED focused build: two missing-field errors for `input_tokens` / `output_tokens`.
- Usage/provider tests: 15 passed, 0 failed, including Gemini private payload no-op and real
  OpenCode standard context/cost normalization.
- Prompt dispatcher Gemini-private no-op integration: 1 passed, 0 failed.
- Full WTA Rust suite: 1153 passed, 0 failed.
- Provider extension interface grep confirms PromptResponseMeta, ProviderApiResponse, typed
  adapter registry, and Copilot Reserved policy remain.
- x64 Debug WTA + CascadiaPackage build/deploy succeeded; deployed WTA SHA256 matched the Cargo
  artifact (`C00BB1513...F1842B`).
- Local standard pipeline E2E passed: context `1024 / 8192 Tokens` and cost `0.004 USD` rendered,
  null cleared Usage, and malformed Usage remained contained.
- Real Gemini CLI E2E completed its prompt with Usage hidden; local screenshot:
  `test/e2e/artifacts/real-gemini-acp/gemini-private-usage-hidden.png`.
- Real OpenCode 1.18.3 E2E displayed only `11926 / 200000 Tokens` and its reported `0 USD`, with
  token breakdown hidden. The currency was consumed unchanged; local screenshot:
  `test/e2e/artifacts/opencode-acp/opencode-context-cost.png`.

**Committed files**

- `tools/wta/Cargo.toml`
- `tools/wta/src/usage.rs`
- `tools/wta/src/usage/providers/{mod,gemini,opencode}.rs`
- `tools/wta/src/protocol/acp/client.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/investigate-gemini.md`
- `doc/investigation/acp-price-calc-track.md`

### Step 19 - Context/Cost-Only Bottom Bar

**RED**

- Replaced the prior input/output formatter expectation with a contract that supplies input,
  output, context, and cost but requires only `1024 / 8192 Tokens` and `0.004 USD`.
- Added an explicit two-item cap and an input/output-only hidden-state contract.
- The first focused run failed exactly on the old behavior: three rendered items and
  `MaxPrimaryItems == 3` (12 passed, 2 failed).

**GREEN**

- Reduced the primary display cap to two and selected only `acp.context.window` followed by
  `acp.billing.cost`. Input/output and unknown/custom metrics remain parsed but do not render.
- Visibility now derives from the filtered display texts, so input/output-only reports collapse
  the Usage group instead of leaving an empty visible container.
- Preserved context-only, cost-only, context+cost, malformed-clear, and no-report behavior.

**Validation**

- x64 Debug TerminalApp unit-test build: succeeded with 0 errors.
- `AgentUsageTests`: 15 passed, 0 failed, 0 skipped.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h/.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`

### Step 15 - Self-Contained Provider Capture Harness

**RED**

- Added a local contract test before the capture script existed. It failed with
  `Missing capture script: ...\Invoke-Providers.ps1`.
- The contract fixes the exact shared question, five result names, and the same launch commands
  currently used by the Intelligent Terminal prototype.

**GREEN**

- Added one PowerShell 7 script with no repository-module imports or generated dependencies.
- The script drives newline-delimited ACP JSON-RPC over stdio through `initialize`, `session/new`,
  and `session/prompt`, collects all session updates and final response, and writes one structured
  JSON document per provider.
- `-PlanOnly` makes command/question/output drift testable without launching providers;
  `-Provider` permits a failed provider to be rerun independently.
- The writer rejects credential-like fields before creating a result file and never persists
  stderr or environment values.

**Validation**

- RED contract: failed because `Invoke-Providers.ps1` did not exist.
- GREEN contract: `Per-provider ACP capture contract: PASS` under the required PowerShell 7 host.

**Committed files**

- `doc/investigation/per-provider-investigation/Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Invoke-Providers.ps1`
- `doc/investigation/acp-price-calc-track.md`

### Step 16 - Real Provider Comparison Results

**RED**

- Added a result validator before the output directory existed. It failed with
  `Missing result directory`.
- The first live run exposed a strict-mode defect when successful JSON-RPC responses omitted the
  optional `error` member. The script was fixed to inspect properties explicitly.
- Claude, Codex, Copilot, and Gemini completed. OpenCode established its ACP session but its current
  default `opencode/big-pickle` failed the prompt with `No provider available`.
- Added a plan contract requiring an explicit OpenCode model; it failed because the plan did not
  expose one. After adding model selection, the uniform-result-schema validator failed because the
  four earlier files lacked the new field.

**GREEN**

- Made mixed response/notification handling strict-mode safe without weakening malformed stdout
  failures.
- Kept the exact prototype launch command `opencode acp` and selected the locally advertised,
  direct-health-checked `opencode/deepseek-v4-flash-free` model through standard ACP
  `session/set_config_option`.
- Regenerated all five files with one schema. Every agent received exactly
  `The answer to life, the universe and everything?` and returned an answer containing `42`.
- Results retain raw structured ACP response objects and session updates, not a hand-authored
  provider summary.

**Validation**

- Script/command/question/model/output contract: PASS.
- Five-result schema/question/answer/credential guard: PASS.
- Exactly five JSON files exist: `claude.json`, `codex.json`, `copilot.json`, `gemini.json`, and
  `opencode.json`.
- Captured versions: Claude ACP 0.59.0, Codex ACP 1.1.2, Copilot 1.0.75, Gemini CLI 0.51.0,
  OpenCode 1.18.3.
- Exact configured Gemini key and common Google/OpenAI/GitHub/JWT credential shapes were absent
  from every result.

**Committed files**

- `doc/investigation/per-provider-investigation/README.md`
- `doc/investigation/per-provider-investigation/Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Results.ps1`
- `doc/investigation/per-provider-investigation/result/*.json`
- `doc/investigation/acp-price-calc-track.md`

### Step 17 - Dynamic Same-Session Provider Turns

**RED**

- Expanded the harness contract to two questions. The old single-question plan failed with
  `Expected 10 provider turns, got 5`.
- The contract requires per-provider turn indices and derives expected filenames from the question
  array index; no provider filename is manually enumerated.
- Added a cleanup contract that creates stale `summary.md` and `old.json` files and requires the
  script's `-CleanOnly` path to leave the result directory empty.

**GREEN**

- Replaced the scalar question with an ordered array and generated a flattened provider/turn plan
  using the loop index (`provider-N.json`). Future questions only require one array entry.
- Each provider process now initializes and creates one ACP session, optionally selects its model
  once, and loops through every planned prompt in that same session.
- Session updates are sliced per turn before each JSON file is written, while initialize,
  new-session, and model-selection evidence remains available in every result.
- Every real capture run removes and recreates the whole result directory before launching a
  provider. `-CleanOnly` reuses the same cleanup boundary for deterministic tests.

**Validation**

- RED contract: expected 10 turns but received 5.
- GREEN plan/numbering/model/cleanup contract: PASS under PowerShell 7.
- Old five single-turn JSON files and `summary.md` were removed before validation.

**Committed files**

- `doc/investigation/per-provider-investigation/Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/README.md`
- Previous `doc/investigation/per-provider-investigation/result/*` files (deleted)
- `doc/investigation/acp-price-calc-track.md`

### Step 18 - Two-Turn Provider Comparison Results

**RED**

- Ran the multi-turn result validator after Step 17 intentionally removed all prior outputs. It
  failed with `Expected 10 JSON results, got 0`.
- The validator requires every provider's two files to share exactly one `newSession.sessionId`,
  match the indexed question plan, contain a non-empty answer, and retain `42` for turn 1.

**GREEN**

- Captured both ordered questions in one live ACP session for each of Claude, Codex, Copilot,
  Gemini, and OpenCode, producing ten automatically numbered JSON files.
- Found and fixed a harness-test isolation defect before final validation: cleanup testing now uses
  a unique temporary `-ResultDirectory`, so running the plan contract after capture preserves the
  real results. Default real captures still clear the official result directory first.
- Recorded turn-scoped updates separately while repeating the shared initialize/new-session/model
  evidence in both files for direct inspection.

**Validation**

- PowerShell plan/numbering/model/isolated-cleanup contract: PASS; real result count remained 10.
- Ten-result question/turn/schema/non-empty-answer/same-session/credential guard: PASS.
- Exactly ten JSON files exist: `claude-1/2`, `codex-1/2`, `copilot-1/2`, `gemini-1/2`, and
  `opencode-1/2`.
- Exact configured Gemini key and common Google/OpenAI/GitHub/JWT credential shapes are absent.
- Claude prompt Usage is per-call including cache; its standard cost increased cumulatively from
  0.17178825 to 0.1898541 USD. Codex and OpenCode prompt Usage are per-call including cache;
  `usage_update.used` behaves as a latest context gauge. Gemini private input reflects each call's
  prompt/context including history and output is turn-specific. Copilot reports no structured
  Usage in either turn.

**Committed files**

- `doc/investigation/per-provider-investigation/Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Invoke-Providers.ps1`
- `doc/investigation/per-provider-investigation/Test-Results.ps1`
- `doc/investigation/per-provider-investigation/README.md`
- `doc/investigation/per-provider-investigation/result/*-1.json`
- `doc/investigation/per-provider-investigation/result/*-2.json`
- `doc/investigation/acp-price-calc-track.md`

### Step 13 - Token Breakdown Bottom Bar

**RED**

- Added `BuildPrimaryDisplayTextsFormatsInputOutputAndCost` before the display policy supported
  token direction labels or a third primary item. The test requires `12341 (in)`, `23 (out)`, and
  reported cost in that order.

**GREEN**

- Added explicit `(in)` and `(out)` formatting for normalized token metrics.
- Increased the bounded primary display from two to three items and prioritized input, output,
  and reported cost when a breakdown exists.
- Preserved the existing context/cost fallback when no token breakdown is present. No provider,
  ACP, or credential logic was added to C++.

**Validation**

- `AgentUsageTests`: 14 passed, 0 failed, 0 skipped.
- Existing context/cost fallback and empty/clear behavior remain covered by the same C++ suite.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h/.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`

### Step 14 - Standard Turn Usage and Gemini Runtime

**RED**

- Added input/output projection and same-session merge contracts before `UsageSnapshot` had
  independent optional fields. The focused Rust build failed with missing-field errors.
- Added a real OpenCode `PromptResponse.usage` contract before enabling the ACP SDK's
  `unstable_end_turn_token_usage` feature and consuming turn usage.
- Added strict Gemini quota contracts before wiring private prompt metadata. Tests require the
  trusted host family to be exactly `gemini`, the real initialize reporter to be exactly
  `gemini-cli`, and the source to be `PromptResponse._meta`.
- Added official-launch tests while the registry and both C++ launch builders still emitted the
  deprecated `--experimental-acp` flag; the tests failed with the old command.
- The first real desktop run authenticated and created a Gemini ACP session, then failed because
  Gemini CLI 0.51.0 returns `Method not found` for the redundant startup `session/set_model` RPC.
  A focused compatibility test was added before the exact identity/error predicate existed and
  failed to compile.

**GREEN**

- Extended the typed snapshot with optional context/input/output/cost and merged only fields
  present in each incoming report. App state still resolves every update through SessionId to the
  owner tab and resets at the existing session lifecycle boundaries.
- Enabled standard ACP end-turn Usage. A standard response always wins; provider-private metadata
  is consulted only when the standard field is absent.
- Wired Gemini's verified `_meta.quota.token_count` adapter through independent host family and
  real initialize reporter identities. It emits input/output only and never invents context,
  currency, or cost.
- Migrated Gemini launch and Settings probe paths to official `gemini --acp`.
- Treats `MethodNotFound` as redundant only at initial model application for the exact
  `gemini + gemini-cli` identity, where the model was already supplied on the launch command.
  Runtime model switches and every other error/provider remain strict; the compatibility path
  emits a warning.

**Validation**

- Persisted Gemini user configuration: official CLI 0.51.0 returned
  `GEMINI_USER_CONFIG_READY` without process-local credential injection.
- Focused startup-model identity/error test: passed.
- Usage/provider and ACP mock-dispatch tests: passed, including standard-over-private precedence
  and exact Gemini reporter/source rejection.
- Full WTA Rust suite: 1156 passed, 0 failed.
- x64 Debug WTA + CascadiaPackage build/deploy: succeeded; deployed WTA SHA256 matched the Cargo
  artifact.
- Real Gemini desktop E2E with `gemini-3.1-flash-lite`: prompt marker received; Bottom Bar showed
  separate input/output counts; currency remained hidden. Local screenshot:
  `test/e2e/artifacts/real-gemini-acp/gemini-official-input-output.png`.
- Local Step 7/9/10 UI regressions passed for context+cost fallback, malformed containment,
  cost-only, tokens-only, error, and no-report states.
- Gemini settings, trusted-folder override, synthetic workspace, package settings backups, and
  Dev processes were absent/restored after E2E. API key values were not logged or committed.

**Committed files**

- `tools/wta/Cargo.toml`
- `tools/wta/src/agent_registry.rs`
- `tools/wta/src/usage.rs`
- `tools/wta/src/usage/providers/{mod,gemini,opencode}.rs`
- `tools/wta/src/protocol/acp/client.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/master/mod.rs`
- `tools/wta/src/app.rs`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/TerminalSettingsEditor/AIAgentsViewModel.cpp`
- `doc/investigation/acp-price-calc.md`
- `doc/investigation/investigate-gemini.md`
- `doc/investigation/acp-price-calc-track.md`
- Local E2E framework, wire captures, and screenshots remain git-ignored and uncommitted.

### Step 0 - Provider and Build Baseline

**Result**

- Verified published adapter pins on 2026-07-22:
  - `@agentclientprotocol/claude-agent-acp@0.59.0`
  - `@agentclientprotocol/codex-acp@1.1.2`
- Kept the previous unpinned Claude command, Codex `1.1.0`, unpinned official Codex command, and
  deprecated Zed Codex command as identification-only compatibility aliases. New sessions always
  use the pinned commands.
- Kept latest-main OpenCode registry/model behavior while resolving the stash conflict.
- Synchronized the Rust registry, Terminal launch builder, Settings model probe, WSL ACP command,
  and dependency documentation.
- Completed local high-fidelity provider/UI preflight with real adapters, Agent Maestro 2.10.0,
  and VS Code LM. The ignored evidence directory contains Terminal, Agent pane, Claude, Codex,
  Session view, official Codex 1.1.2, and tool-call screenshots.

**Validation**

- `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml agent_registry::tests -- --nocapture`
  - 14 passed, 0 failed.
- `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml coordinator::tests -- --nocapture`
  - 74 passed, 0 failed.
- `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml wsl_acp::tests -- --nocapture`
  - 7 passed, 0 failed.
- Pre-conflict full Rust suite: 1119 passed, 0 failed.
- x64 Debug incremental solution build: succeeded with 0 errors.
- ItE2E framework baseline: 11 hermetic tests and 12 Dev live tests passed.
- Final local provider checks showed `Claude Agent v0.59.0`, current-path Codex, official
  `Codex v1.1.2`, real prompt replies, terminal tool side effects, and a visible Session view.

**Committed files**

- Design/investigation documentation and this tracking note.
- Adapter pin and compatibility changes in existing product/registry code.
- Dependency setup documentation.
- No local E2E harness, screenshot, provider config, credential, or wire-log files.

### Step 1 - Reliable Master Usage Delivery

**RED**

- Added `rebinding_session_clears_previous_helpers_pending_usage` before adding the shared route
  binding boundary.
- Focused test failed to compile with `E0425` because `bind_session_route` did not exist. This
  exposed that a SessionId rebound from helper A to helper B could retain A's pending usage and
  later deliver it to the wrong helper.

**GREEN**

- Added one `bind_session_route` boundary reused by both `session/new` and `session/load`.
- The boundary holds the documented `session_to_helper -> pending_usage` lock order, clears the
  previous owner's pending usage, installs the new route, and returns the route count.
- Standard ACP `UsageUpdate` notifications bypass the ordinary bounded chunk queue, replace the
  previous value by SessionId, wake helpers through a watch generation, and are drained only by
  their owning helper.
- Disconnect cleanup removes pending usage for sessions owned by the departing helper.
- Usage values remain unlogged; only routing identifiers and schema-level event kinds are traced.

**Validation**

- RED command: focused test failed with two `cannot find function bind_session_route` errors.
- GREEN focused test: 1 passed, 0 failed.
- `master::tests`: 63 passed, 0 failed.
- Full WTA Rust suite: 1120 passed, 0 failed.

**Committed files**

- `tools/wta/src/master/mod.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`

### Step 5 - Existing State Projection

**RED**

- Added pure event-builder tests before the builder existed.
- The focused build failed with two missing `build_agent_state_changed_event` errors.
- Tests require context and optional cost items, stable metric/unit/source/scope fields, and
  explicit `usage: null` when no snapshot exists.

**GREEN**

- Added typed `UsageProjection` / `UsageProjectionItem` structures.
- Context projects first as `acp.context.window` with decimal used/limit text and unit `token`.
- Optional cumulative cost projects as `acp.billing.cost` with the validated ISO currency code as
  its unit. No amount conversion or arithmetic occurs.
- Both items identify `scope=session`, `source=acp_standard`, and `stale=false`.
- Extracted a pure `build_agent_state_changed_event`; production `project_tab_state` reuses it and
  continues through the existing `agent_state_changed` route.
- Missing usage serializes as null so C++ can clear stale cached UI state.

**Validation**

- RED command failed with two missing-builder compiler errors.
- GREEN projection tests: 2 passed, 0 failed.
- Full WTA Rust suite: 1135 passed, 0 failed, 0 warnings.
- `usage.rs` passes rustfmt; no App rustfmt differences overlap Step 5 lines.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state/transport update in `doc/investigation/acp-price-calc.md`

### Step 6 - C++ Parser and Per-Pane Cache

**RED**

- Added five TerminalApp TAEF parser tests before creating `AgentUsage.h`; the focused project
  build failed with C1083 (missing header).
- After the parser passed, added two atomic cache tests before `UpdateCache` existed; the build
  failed with C2039 (missing member).

**GREEN**

- Added a pure `AgentUsage` parser independent of XAML/WinRT construction.
- Accepts null/empty as explicit clear and validates the complete item array atomically before
  replacing the cache. Malformed input throws and preserves the previous cache.
- Bounds item count and string lengths, validates decimal/scientific text, and requires typed
  metric/value/unit/scope/source/stale fields. No provider calculation or raw provider JSON is
  stored.
- `AgentPaneContent` caches only parsed items and raises its existing `StateChanged` event after a
  successful replace/clear. No IDL or new COM event route was added.
- `TerminalPage::OnAgentStateChanged` consumes the optional `usage` member for the routed tab.
  Missing means no change; null clears; object updates; another JSON type fails fast.

**Validation**

- Parser RED: focused C++ build failed because `AgentUsage.h` did not exist.
- Cache RED: focused C++ build failed because `AgentUsage::UpdateCache` did not exist.
- `AgentUsageTests`: 7 passed, 0 failed, 0 skipped.
- TerminalApp unit-test project build: succeeded with 0 errors.
- Full x64 Debug incremental solution build: succeeded with 0 errors (existing XAML/PRI warnings).
- clang-format reports no violations on new files or changed lines.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h/.cpp`
- `src/cascadia/TerminalApp/AgentPaneContent.h/.cpp`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/TerminalApp/TerminalAppLib.vcxproj`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `src/cascadia/ut_app/TerminalApp.UnitTests.vcxproj`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`

### Step 7 - Bottom Bar Usage UI

**RED**

- Added two TerminalApp TAEF display-model tests before adding any display builder.
- The focused build failed with C2039 because `AgentUsage::BuildPrimaryDisplayTexts` and
  `AgentUsage::MaxPrimaryItems` did not exist.
- The tests require `1024 / 8192 Tokens`, `0.004 USD`, and a two-item maximum so Usage cannot
  crowd out the Session button.

**GREEN**

- Added one pure, provider-neutral display builder over the validated normalized cache. It emits
  at most two texts, formats the standard context metric with its limit and localized Tokens
  unit, and otherwise preserves normalized value/unit text without conversion or arithmetic.
- Added a right-aligned `UsageGroup` in the existing Bottom Bar star column immediately before
  the Session button. It starts collapsed and has a localized UI Automation name.
- `_UpdateBottomBarState` clears and rebuilds the group from the active tab's
  `AgentPaneContent` cache before the diagnostics gate, so Usage remains independent of
  diagnostics connection state. Empty or cleared usage collapses the group.
- Added the en-US source resources for the accessibility name and locked Tokens unit while
  preserving the resource file's UTF-8 BOM.

**Validation**

- RED build reported the expected C2039 errors for `BuildPrimaryDisplayTexts` and
  `MaxPrimaryItems`.
- `AgentUsageTests`: 9 passed, 0 failed, 0 skipped.
- TerminalApp unit-test project build: succeeded with 0 errors.
- Full x64 Debug incremental solution build: succeeded with 0 errors.
- `Resources.resw`: UTF-8 BOM preserved and XML parse valid.
- Rebuilt WTA and CascadiaPackage, clean-deployed Dev package 0.8.0.2, and verified the installed
  WTA and WindowsTerminal binary hashes match the current build outputs.
- Local ignored UI proof published typed `agent_state_changed.usage` to a stable tab ID. UIA read
  `UsageGroup` with `1024 / 8192 Tokens` and `0.004 USD`; the screenshot showed both values fully
  visible before the Session button. Publishing `usage: null` removed the group and both texts.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h/.cpp`
- `src/cascadia/TerminalApp/TerminalPage.xaml/.cpp`
- `src/cascadia/TerminalApp/Resources/en-US/Resources.resw`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`
- No local E2E script or screenshot files.

### Step 8 - Outer Containment and Privacy

**RED**

- Added a production-boundary test before defining `dispatch_session_notification` or
  `AppEvent::UsageCleared`; the focused build failed with E0599 for both missing symbols.
- The boundary test requires malformed Usage to emit a clear event and the following agent text
  chunk to keep flowing on the same session.
- Added a captured-tracing test with two sentinel token values and an App state test requiring
  only the owner tab's Usage to clear while its chat, another tab's Usage, and `Connected` state
  remain unchanged.

**GREEN**

- Kept `session_notification` and `normalize_standard_usage` as fail-fast inner functions. Their
  direct malformed-input test still returns `Err` and emits no state event.
- Added one `dispatch_session_notification` boundary at the production ACP notification entry.
  Only errors from a recognized Usage update are contained; the boundary emits
  `AppEvent::UsageCleared` and returns to the notification stream.
- `App::handle_event` resolves `UsageCleared` through the existing SessionId-to-tab map and clears
  only that tab's snapshot. The next state projection emits `usage: null` through the existing
  route, so C++ hides `UsageGroup` without a new COM/IDL path.
- Removed value-bearing normalizer error text from tracing and ACP error data. The outer warning
  records only fixed `schema=acp.v1.session_usage`, `source=acp_standard`, and
  `outcome=rejected` fields. Usage trace continues to suppress the full update payload.

**Validation**

- RED build reported missing `AppEvent::UsageCleared` and
  `WtaClient::dispatch_session_notification`.
- Containment/chat-continuity test: 1 passed, 0 failed.
- Inner fail-fast test: 1 passed, 0 failed.
- Captured-log privacy test: 1 passed, 0 failed; schema was present and both sentinel values were
  absent.
- Owner-tab clear/isolation test: 1 passed, 0 failed.
- Usage normalizer tests: 5 passed, 0 failed.
- ACP mock-agent/client tests: 31 passed, 0 failed.
- Full WTA Rust suite: 1138 passed, 0 failed.
- No rustfmt differences overlap Step 8 production or test lines; broader crate formatting drift
  remains outside this change.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/protocol/acp/client.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`

### Step 9 - Final Integration

**RED**

- Added a local ignored standalone ACP agent that emits a valid standard `usage_update` followed
  by an agent text chunk. The first full desktop run proved master delivery and helper
  normalization (`first_event=usage_update`) but the Bottom Bar stayed hidden: updating App state
  did not immediately project `agent_state_changed` to C++.
- Added an existing-framework App test requiring `UsageReported` to project an owner-tab usage
  object immediately and `UsageCleared` to project null. Before the projection capture and refresh
  existed, the focused build failed with E0599 for `take_projected_test_events`.

**GREEN**

- Both Usage event branches now resolve the owner tab through the existing SessionId map, mutate
  that tab, and immediately reuse `project_tab_state`. No new transport or C++ route was added.
- Added test-only capture at the existing projection boundary so the focused test verifies the
  exact production event builder and owner-tab ID without replacing the production publisher.
- Kept the local desktop harness ignored. Its standalone agent returns a unique SessionId for
  every `session/new`, and the verifier pins the agent pane to the same foreground window/tab as
  UI Automation so multi-window restore state cannot cross-wire the proof.

**Validation**

- Projection RED: focused build failed because `take_projected_test_events` did not exist.
- Projection GREEN: 1 passed, 0 failed.
- All usage-filtered Rust tests: 15 passed, 0 failed.
- Full WTA Rust suite: 1139 passed, 0 failed.
- Final full x64 Debug solution build: succeeded with 0 errors (170 existing warnings).
- Rebuilt WTA, refreshed the deployed loose Dev 0.8.0.2 package, and verified its WTA hash matches
  the current build.
- Existing ACP probe verified the ignored standalone agent's protocol-v1 initialize, unique
  session, valid `usage_update`, `FINAL_USAGE_CHAT_OK` chunk, and `end_turn` response.
- Full desktop pipeline passed through agent -> master -> helper -> App ->
  `agent_state_changed` -> C++: UIA read `1024 / 8192 Tokens` and `0.004 USD`; the visible
  screenshot is 62,486 bytes.
- A second prompt emitted malformed Usage and then `FINAL_CONTAINMENT_CHAT_OK`. Both chat replies
  remained visible, Usage collapsed, and the contained screenshot is 64,222 bytes.
- Deployed-run logs contained the fixed schema/source/outcome rejection warning and neither
  malformed sentinel value. Visual inspection confirmed no overlap with the Session button.

**Committed files**

- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`
- No local standalone agent, E2E verifier, log, or screenshot files.

### Step 10 - Partial, Error, and Missing Usage States

**RED**

- Added four TerminalApp TAEF tests before `BuildPrimaryDisplay` existed. The focused build failed
  with C2039/C3861 for the missing builder.
- The tests require cost-only normalized items to show one currency value, tokens-only items to
  show one context ratio, and both contained-error clear and no-report states to collapse Usage.
- Standard ACP v1 requires `used` and `size`; only `cost` is optional. Therefore tokens-only,
  malformed, and no-report mocks run through ACP wire, while cost-only is tested at the
  normalized projection contract consumed by C++ (the shape a future trusted extension uses).

**GREEN**

- Added a pure `PrimaryDisplay { texts, visible }` state that reuses the existing formatter.
- `_UpdateBottomBarState` consumes that state, so one tested visibility decision owns empty,
  one-item, and two-item rendering. XAML does not contain provider or scenario branches.
- Extended the ignored standalone ACP agent with deterministic `tokens-only`, `error`, and
  `none` scenarios. Added a local four-scenario desktop verifier with chat markers, UIA
  visibility/text checks, screenshots, and process-liveness assertions.
- The local verifier resolves each pane from its current structured helper log. This avoids a
  known local test-framework race where concurrent helpers can interleave append-only JSONL
  records; no test-framework file is committed in this feature change.

**Validation**

- RED build reported missing `AgentUsage::BuildPrimaryDisplay`.
- `AgentUsageTests`: 13 passed, 0 failed, 0 skipped.
- Full x64 Debug solution build: succeeded with 0 errors (169 existing warnings).
- CascadiaPackage clean build: succeeded with 0 errors; deployed Dev 0.8.0.2 Terminal and WTA
  hashes matched current build outputs.
- ACP probes: tokens-only emitted valid `usage_update` without cost; error emitted malformed
  Usage then a chat chunk; no-report emitted only a chat chunk. All returned `end_turn`.
- Desktop cost-only: displayed only `0.004 USD`; chat continued; process remained alive.
- Desktop tokens-only: displayed only `1024 / 8192 Tokens`; chat continued; process remained
  alive.
- Desktop malformed error: Usage collapsed, `EDGE_ERROR_OK` remained visible, and the process
  remained alive.
- Desktop no-report: Usage stayed collapsed, `EDGE_NO_USAGE_OK` remained visible, and the process
  remained alive.
- Visual inspection found no Bottom Bar overlap. Error-run logs contained the redacted rejection
  warning and neither malformed sentinel value.

**Committed files**

- `src/cascadia/TerminalApp/AgentUsage.h/.cpp`
- `src/cascadia/TerminalApp/TerminalPage.cpp`
- `src/cascadia/ut_app/AgentUsageTests.cpp`
- `doc/investigation/acp-price-calc-track.md`
- Current-state/edge-contract update in `doc/investigation/acp-price-calc.md`
- No local mock, E2E verifier, helper log, or screenshot files.

### Step 11 - Modular Provider Usage Boundary

**RED**

- Added provider registry contract tests before the module existed. The focused build failed with
  E0583 because `usage/providers` was missing.
- Tests require one adapter for every `KNOWN_AGENTS` family, explicit private-usage policy,
  fail-closed lookup for unknown/custom agents, and no data from unverified private payloads.

**GREEN**

- Added `tools/wta/src/usage/providers/` with separate `copilot`, `claude`, `codex`, `gemini`, and
  `opencode` modules behind one `ProviderUsageAdapter` interface and registry.
- Centralized the five Rust family IDs in `agent_registry`; launch profiles, historical command
  aliases, and provider modules now share those constants. C++-to-Rust codegen remains separate.
- The interface accepts session-update metadata, prompt-response metadata, extension
  notifications, and already-fetched provider API responses. Network/auth and CLI credential
  access are deliberately outside this parser boundary.
- Provider contributions can independently contain context, cost, or custom metrics, preserving
  the cost-only normalized shape without inventing standard ACP token fields.
- Every module explicitly implements extraction but currently returns an empty contribution.
  Trusted reporter allowlists are empty until a real wire schema and reporter identity are
  verified. Unknown/custom agents receive no private adapter and continue through standard ACP.
- Policies are explicit: Copilot `Reserved`; Claude/Codex/OpenCode `StandardAcpOnly`; Gemini
  `OutOfScope`. Standard ACP remains provider-neutral and runs before this future extension layer.
- The private registry is intentionally not runtime-wired yet: effective family and exact
  reporter identity must first be carried from the trusted master handshake into helper state.

**Validation**

- RED build reported missing module `providers`.
- Usage tests: 9 passed, 0 failed (5 standard normalizer + 4 provider contracts).
- Agent registry tests: 14 passed, 0 failed.
- Full WTA Rust suite: 1143 passed, 0 failed.
- No compiler warning originated from `usage.rs` or `usage/providers`.

**Committed files**

- `tools/wta/src/agent_registry.rs`
- `tools/wta/src/usage.rs`
- `tools/wta/src/usage/providers/mod.rs`
- `tools/wta/src/usage/providers/{copilot,claude,codex,gemini,opencode}.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state/interface update in `doc/investigation/acp-price-calc.md`

### Step 12 - Fixed PowerShell Install Path (Superseded by Step 30)

**RED**

- Added two existing-framework unit contracts before the host helpers existed. Both failed with
  `CommandNotFoundException` for `Get-ItPowerShell7Path` and `Assert-ItPowerShell7Host`.

**Historical GREEN**

- Added one fixed default-install executable path. Step 30 removes this machine-specific policy.
- Every ItE2E module import validates the current process path, so direct Pester runs and report
  runners fail fast under another PowerShell host. The module manifest still enforces 7.2+.
- Bootstrap validates the exact host before dependency checks. FRE's pwsh execution-policy probe
  uses the same resolver rather than PATH lookup.
- Updated runner/tool examples to the absolute executable. The two `powershell.exe` references
  that remain are intentional WinPS 5.1 compatibility tests, not E2E hosts.
- Local Usage ACP mocks launch through an ignored `.cmd` wrapper whose only executable is the
  canonical PowerShell 7 path; the mock also validates its own process path.

**Validation**

- RED: both host helper tests failed because the functions did not exist.
- The configured host resolved to PowerShell 7.6.3 x64 on the development machine.
- ItE2E unit self-tests: 13 passed, 0 failed.
- ItE2E live self-tests: 12 passed, 0 failed in 30.67 seconds; cleanup left no processes.
- Canonical report runner: 13 passed, 0 failed; HTML/XML/Markdown artifacts generated under the
  ignored artifacts directory.
- Bootstrap `-Check`: exit 0; winapp, Pester 6.0.1, Dev package, and module import succeeded.
- Windows PowerShell 5.1 module import was rejected by the 7.2 requirement.
- Both policy setup tools rejected Windows PowerShell before UAC or registry work.
- ACP mock probe launched through the canonical host and completed initialize, tokens-only Usage,
  chat marker, and `end_turn` with exit 0.

**Committed files**

- Existing ItE2E module/host helpers, FRE helper, bootstrap, unit self-test, and runner docs.
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`
- Local Usage mock launcher remains git-ignored.

### Step 4 - Session Usage Lifecycle

**RED**

- Added four lifecycle tests before changing reset behavior. `/clear`, `/new`, and
  `load_session` retained stale usage and failed; global model change already preserved usage and
  passed.
- Added a second RED test showing that a reconnect binding a new ACP SessionId retained the old
  session's usage snapshot.

**GREEN**

- Added usage reset to the existing `TabSession::clear_chat_history` owner reused by `/clear`,
  `/new`, and `load_session`; no duplicate reset logic was added at call sites.
- `AgentConnected` clears usage only when the bound SessionId changes. Repeated connected events
  for the same session do not erase its usage.
- Global and per-tab model changes do not clear session-cumulative usage.
- Tab close and app restart already drop their in-memory `TabSession`; no persistence was added.

**Validation**

- Initial RED run: 1 passed (model preservation), 3 failed (clear/new/load stale usage).
- Connection RED run: 1 failed because the old snapshot survived a new SessionId.
- GREEN lifecycle tests: 5 passed, 0 failed.
- Full WTA Rust suite: 1133 passed, 0 failed.
- No rustfmt differences overlap Step 4 changed lines.

**Committed files**

- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`

### Step 3 - Helper Dispatch and Owner-Tab Storage

**RED**

- Added existing-framework ACP client tests for a valid `UsageUpdate` and a malformed zero-size
  update before adding the event variant.
- Added an App state test that binds a session to a non-active tab and requires usage to update
  only that owner.
- RED failures showed the missing `AppEvent::UsageReported` variant and `TabSession.usage` field.

**GREEN**

- `WtaClient::session_notification` now recognizes typed ACP v1 `UsageUpdate`, runs the standard
  normalizer, and emits `AppEvent::UsageReported`.
- Recognized malformed usage returns ACP `invalid_params`; it never reaches App state.
- `App::handle_event` resolves the event's SessionId through the existing `session_to_tab` map and
  stores the latest snapshot only on the owner `TabSession`.
- Raw Usage values are no longer formatted into the trace-level full-notification log. Normalizer
  failures log only schema ID and error class/message, not amount/token values.
- No new transport, COM route, provider branch, dependency, or UI behavior was added.

**Validation**

- RED client test failed because `AppEvent::UsageReported` did not exist.
- RED App test failed because `AppEvent::UsageReported` and `TabSession.usage` did not exist.
- Valid client dispatch: 1 passed, 0 failed.
- Malformed client dispatch: 1 passed, 0 failed.
- Owner-tab state routing: 1 passed, 0 failed.
- Full WTA Rust suite: 1128 passed, 0 failed, 0 warnings.
- No rustfmt differences overlap Step 3 changed lines.

**Committed files**

- `tools/wta/src/protocol/acp/client.rs`
- `tools/wta/src/protocol/acp/mock_agent_tests.rs`
- `tools/wta/src/app.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`

### Step 2 - Standard ACP Usage Normalizer

**RED**

- Added five contract tests before defining any Usage production types or normalizer.
- The focused build failed with 11 missing-symbol errors for `UsageCost`, `UsageError`, and
  `normalize_standard_usage`.

**GREEN**

- Added a provider-neutral `UsageSnapshot` containing context `used` / `size` and optional
  cumulative `UsageCost`.
- Validates non-zero context size, `used <= size`, finite non-negative cost, and a canonical
  three-uppercase-ASCII-letter currency shape.
- Converts the ACP wire `f64` amount to decimal display text once. The text does not recover wire
  precision and is never used for arithmetic or local price conversion.
- Ignores ACP `_meta`; no provider-specific schema or private adapter is introduced.
- Added no dependency, so Component Governance and third-party notices are unchanged.

**Validation**

- RED command: focused build failed with 11 expected missing-symbol errors.
- GREEN focused tests: 5 passed, 0 failed.
- `rustfmt --check` passes for `usage.rs` and the `main.rs` module registration.
- Full WTA Rust suite: 1125 passed, 0 failed.

**Committed files**

- `tools/wta/src/usage.rs`
- `tools/wta/src/main.rs`
- `doc/investigation/acp-price-calc-track.md`
- Current-state update in `doc/investigation/acp-price-calc.md`
