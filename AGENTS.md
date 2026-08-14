# Feature/Fix Handoff Template

> TEMPLATE: When instantiating this handoff, replace each `<PLACEHOLDER>` as
> its evidence becomes available. Delete optional sections that do not apply.
> Do not carry details from a previous work item into a new branch. Keep the
> repository reference below the `---` divider unchanged unless its long-lived
> architecture changes.

## Placeholder Checklist

Fill these before implementation begins:

- Identity: `<WORK_ITEM_TITLE>`, `<LAST_SYNCHRONIZED_YYYY-MM-DD>`, `<BASE_SHA>`,
  branch/remote names, and `<ISSUE_OR_PR>`.
- Scope: `<CURRENT_STAGE>`, `<USER_VISIBLE_CONTRACT>`, non-goals, guardrails,
  `<OPEN_FOLLOW_UPS>`, `<REVIEW_EVIDENCE_DIR>`, and any
  `<PUBLISH_SCOPE_EXCEPTION>`.
- Discovery: ownership path, falsifiable hypothesis, discriminating check,
  deterministic reproduction, setup preconditions, RED oracle, and the nearest
  existing test/framework that can be reused.

Fill these as implementation evidence becomes available:

- RED/GREEN results, owning abstraction, state/API changes, invariants,
  performance notes, rejected alternatives, and artifact paths.
- Review decisions with rationale, resolution, and focused validation.

Fill these before publishing or handoff completion:

- Full-suite/build/deployment/E2E results, visual evidence, remaining gaps,
  source/deployed hashes, `<PUBLISHABLE_COMMIT>`, and `<PUBLISH_HEAD>`.
- Replace any remaining inline `<PLACEHOLDER>` or explicitly mark it `N/A`.

> Last synchronized: `<LAST_SYNCHRONIZED_YYYY-MM-DD>`
>
> This dev-only section tracks `<WORK_ITEM_TITLE>`. Product behavior and
> committed tests remain the source of truth.

Branches created from `origin/main@<BASE_SHA>`:

- dev: `<DEV_BRANCH>` -> `<DEV_REMOTE>`
- publish: `<PUBLISH_BRANCH>` -> `<PUBLISH_REMOTE>`
- issue / pull request: `<ISSUE_OR_PR>`

Publish scope excludes this handoff and local-only screenshots, reports, logs,
and experiments unless `<PUBLISH_SCOPE_EXCEPTION>` explicitly says otherwise.

### Commit and worktree discipline

- Publishable changes are committed first on dev as one self-contained commit:
  product code, product/Rust tests, tests that live naturally in the existing
  ItE2E framework, their deterministic fixtures, and release-checklist/ItE2E
  metadata.
- Dev-only changes are committed separately afterward: this `AGENTS.md`
  handoff, progress notes, ignored screenshots/reports/logs, local-only test
  orchestration, and experiments that do not belong to an existing framework.
- The publish worktree must directly cherry-pick the dev publishable commit. Do
  not cherry-pick a mixed commit and then restore dev-only files.
- Current publishable commit: `<PUBLISHABLE_COMMIT>`.
- Current publish head: `<PUBLISH_HEAD>`.
- Excluded work: `<OPEN_FOLLOW_UPS>`.

### E2E Reuse and Test-Framework Modularization

- Reuse or extend existing tests, fixtures, helpers, and E2E frameworks first.
  Record the nearest reusable coverage at `<EXISTING_TEST_SURFACE>` and explain
  why it is sufficient or insufficient for the real user workflow.
- When the existing framework cannot exercise the real user operation, a local
  E2E framework or orchestration layer may be developed to establish RED/GREEN
  evidence. Keep it under `<LOCAL_E2E_FRAMEWORK_PATH>` and design clear module
  boundaries, inputs, outputs, and cleanup so it can become an independent PR.
- Do not include a large new test framework, general-purpose harness rewrite,
  or unrelated infrastructure in the feature/fix publishable commit. Commit
  only tests that fit naturally in an existing framework; track the modular
  framework extraction under `<OPEN_FOLLOW_UPS>` for a separate branch/PR.
- Small deterministic fixtures or helpers may ship with the feature when they
  are narrowly owned by the existing test suite and are required to make the
  regression reliable.

### Public PR review workflow

- For public GitHub PRs, review without authentication by reading these public
  REST endpoints with the webpage fetch tool: `/pulls/<n>`,
  `/issues/<n>/comments`, `/pulls/<n>/reviews`, `/pulls/<n>/comments`,
  `/pulls/<n>/files`, and the HEAD commit's `/check-runs` endpoint.
- Review bodies can contain `<details><summary>Suppressed comments</summary>`;
  treat every suppressed finding as review input and triage it explicitly.
- Do not use `gh`, GitKraken, or another tool that requires GitHub login for a
  public read-only review. Anonymous API/web access cannot reply to or resolve
  threads; report that limitation instead of requesting credentials.
- Every accepted behavior change follows RED -> minimal GREEN -> focused/full
  validation. Before any fix commit is pushed to the PR, run the related live
  E2E from the publish worktree against the exact publish-built and deployed
  binary, and verify source/deployed SHA-256 equality. Set
  `ITE2E_PACKAGE=Dev`; the harness default `Auto` prefers an installed Store
  package and can otherwise validate the wrong binary.

## Current Stage

`<LAST_SYNCHRONIZED_YYYY-MM-DD>`: `<CURRENT_STAGE>`

### User-Visible Contract

`<USER_VISIBLE_CONTRACT>`

List concrete behavior, preserved workflows, edge cases, and explicit
non-goals. Prefer observable outcomes over implementation details.

### Current Ownership Hypothesis

```text
<ENTRY_POINT>
  -> <ROUTING_LAYER>
  -> <OWNING_ABSTRACTION>
  -> <STATE_OR_OUTPUT>
```

- Owning code path: `<OWNERSHIP_PATH>`
- Falsifiable hypothesis: `<CURRENT_HYPOTHESIS>`
- Cheapest discriminating check: `<DISCRIMINATING_CHECK>`

### Reproduction and RED Oracle

Framework / fixture: `<TEST_FRAMEWORK_AND_FIXTURE>`

1. `<REPRO_STEP_1>`
2. `<REPRO_STEP_2>`
3. `<REPRO_STEP_3>`
4. Prove setup preconditions: `<SETUP_PRECONDITIONS>`.
5. Capture ignored evidence at `<ARTIFACT_PATHS>`.

- RED oracle: `<RED_ORACLE>`
- Expected failure location/message: `<EXPECTED_FAILURE>`
- Evidence that setup itself succeeded: `<VALID_SETUP_EVIDENCE>`

### Implementation

`<IMPLEMENTATION_SUMMARY>`

- Owning abstraction: `<OWNING_ABSTRACTION>`
- State or API changes: `<STATE_OR_API_CHANGES>`
- Preserved invariants: `<PRESERVED_INVARIANTS>`
- Performance implications: `<PERFORMANCE_NOTES>`
- Rejected alternatives and rationale: `<REJECTED_ALTERNATIVES>`

### TDD and Validation Evidence

- Focused RED: `<FOCUSED_RED_EVIDENCE>`
- Live / E2E RED: `<LIVE_RED_EVIDENCE>`
- Focused GREEN: `<FOCUSED_GREEN_EVIDENCE>`
- Neighboring tests: `<NEIGHBORING_TEST_RESULTS>`
- Full suite: `<FULL_SUITE_RESULTS>`
- Explicit-target build: `<BUILD_RESULTS>`
- Exact deployed package: `<PACKAGE_SELECTOR_AND_IDENTITY>`
- Source/deployed SHA-256: `<SOURCE_HASH>` / `<DEPLOYED_HASH>`
- Packaged E2E: `<PACKAGED_E2E_RESULTS>`
- Screenshot paths: `<RED_SCREENSHOTS>` / `<GREEN_SCREENSHOTS>`
- Visual inspection: `<VISUAL_EVIDENCE>`
- Remaining test gaps: `<REMAINING_TEST_GAPS>`

For UI or terminal-rendering changes, screenshots are required evidence, not
optional decoration. Capture the failing state and the fixed state from the
real user workflow. Inspect and record that the target state is visible, output
is nonblank, layout is stable, and controls/text do not overlap or clip. Cover
all relevant pane positions, window sizes, themes, or interaction modes named
by `<USER_VISIBLE_CONTRACT>`.

### Review Triage

For every review round, append a short entry using this format:

```text
<REVIEW_DATE> <REVIEW_ID_OR_HEAD_SHA>
- Finding: <PATH_AND_SUMMARY>
- Decision: accept | decline | escalate
- Rationale: <TECHNICAL_REASONING>
- RED: <FAILURE_EVIDENCE_OR_N/A>
- Resolution: <CHANGE_OR_EXPLICIT_DECLINE>
- GREEN: <VALIDATION_EVIDENCE>
- Publish commit: <SHA_OR_N/A>
```

Current review status: `<REVIEW_STATUS>`
Open review items: `<OPEN_REVIEW_ITEMS_OR_NONE>`

### Local-Only Evidence

`<ARTIFACT_PATHS>`

List ignored screenshots, pane captures, fixture logs, test reports, local E2E
frameworks, scripts, wire captures, and provider configurations. State which
artifact proves each user-visible assertion.

- Do not delete local E2E frameworks, scripts, wire captures, provider configs,
  screenshots, reports, or logs merely because they are ignored. Preserve them
  for reproduction, review follow-up, and extraction into a separate PR.
- If a screenshot or other evidence must be committed for review, copy the
  final selected artifact into the designated non-ignored
  `<REVIEW_EVIDENCE_DIR>`. Do not force-add the ignored working artifact.
- If evidence does not need to be committed, keep it in its ignored location
  and record the exact path, command, package/binary identity, validation
  result, and visual conclusion in this handoff.

### Strict TDD workflow

1. Find and reuse the nearest existing test, fixture, helper, and E2E suite.
  Add the smallest focused/live case to that natural surface.
2. Build and deploy the exact baseline before RED so the binary is known.
3. Run only the new case and confirm it fails at the behavioral oracle for the
   expected reason. If it cannot reproduce, stop and report the evidence before
   changing product code.
4. Add the narrowest unit/state/render regression that captures the missing
  behavior and confirm RED.
5. Apply the smallest implementation at the owning abstraction.
6. Rerun the same focused and live/E2E checks for GREEN.
7. Run related tests, the full relevant suite, and required explicit builds.
8. Deploy the exact validated build using the narrowest supported flow, verify
  binary identity when applicable, and rerun the full related E2E suite.
9. Inspect visual evidence for nonblank output, expected state, stable layout,
  no overlap, and no clipping when UI behavior is involved. Record RED/GREEN
  screenshot paths and the inspection result.
10. Commit product/tests/existing-framework E2E/checklist metadata as the dev
  publishable commit. Keep large new local test frameworks modular and out of
  the feature commit; commit this handoff and local-only material separately.
11. Push dev and confirm remote synchronization, then directly cherry-pick the
  publishable commit into the publish worktree.

### Guardrails

- `<WORK_ITEM_GUARDRAIL_1>`
- `<WORK_ITEM_GUARDRAIL_2>`
- `<WORK_ITEM_GUARDRAIL_3>`
- Do not infer user-visible behavior only from internal state; validate the
  actual output or workflow.
- Do not include unrelated fixes discovered during investigation. Record them
  under follow-ups and use a separate branch/PR.
- Do not delete ignored local E2E frameworks, scripts, wire/provider configs,
  screenshots, or logs. Preserve them and record their paths.
- Do not force-add ignored screenshots. Copy review-selected evidence into
  `<REVIEW_EVIDENCE_DIR>` when it must be committed.
- Format only touched files; avoid repository-wide mechanical churn.

### Optional Follow-Ups

- `<FOLLOW_UP_TITLE>`: `<WHY_EXCLUDED>`, `<EVIDENCE>`, `<PROPOSED_NEXT_STEP>`.
- If none: `None`.

---

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
