# Agent Pane Select-All TDD Handoff

> This dev-only handoff governs the `Ctrl+A` agent-pane select-all feature. Product behavior,
> committed tests, exact package identity, and reproducible evidence are the sources of truth.

## Feature Metadata

- Feature: Agent-pane rendered-frame select-all
- Summary: Bind plain `Ctrl+A` inside WTA to select the current rendered frame through the existing WTA-owned `TextSelection` path.
- User-visible goal: A user can press `Ctrl+A`, then `Ctrl+C` or right-click, to copy all currently rendered agent-pane text without holding Shift or invoking TerminalControl scrollback selection.
- Base: `0c2062bc5837b2ae335f86a00d068828d76af2d5`
- Dev branch: `user/DinahK-2SO/agent-pane-select-all` -> `Dinah`
- Publish branch: `user/DinahK-2SO/agent-pane-select-all-publish` -> `origin`
- Dev worktree: `C:\ado\intelligent-terminal`
- Publish worktree: `C:\ado\intelligent-terminal-agent-pane-select-all-publish`
- Issue / pull request: none yet
- Evidence root: `local-tdd-kit/artifacts/agent-pane-select-all`
- Current publishable commit: none
- Current publish head: `0c2062bc5837b2ae335f86a00d068828d76af2d5`
- Dev-only preparation commits:
  - `a0c9ad5be1c7226f4dd8ab74e9cdd41fbb378723` — latest local TDD framework snapshot
  - `1aac986d479abc744ba5cc4cad6e72683e1030ea` — latest AGENTS template snapshot
- Out of scope: TerminalControl/native scrollback `SelectAll`, virtualized off-screen chat history, changing `Ctrl+Shift+A`, changing mouse drag/right-click/default paste, or introducing a real-agent token-consuming publish test.

## Current Stage

`2026-09-01`: Ownership and contract are fixed. The first exact baseline pipeline exposed and then repaired a dev-only AppX recipe path-decoding incompatibility. Next step is a fresh baseline pipeline retry, followed by unit and packaged RED. No product implementation has been made.

Preparation validation:

- Latest `origin/main`, local main, and publish head are all `0c2062bc5`.
- Dev TDD-kit began as the exact `Dinah/user/DinahK-2SO/local-tdd-kit` tree at `20cb3fa1c`; a later dev-only compatibility extension decodes URI-escaped AppX recipe source paths such as `%28x86%29`.
- This handoff began from the exact `Dinah/user/DinahK-2SO/AGENTS_md` blob at `d4d824278`.
- Local TDD bootstrap passed.
- Core/durable pipeline selftests after the compatibility extension: 35 passed, 0 failed.
- Win32 input selftests: window/PID identity passed; three physical-input cases are blocked because this VS Code automation host cannot acquire foreground. Do not classify that precondition as a product failure or as GREEN.

## Autopilot Rules

- Run every bounded build, test, deploy, package, format, and script synchronously without a tool timeout. Continue in the same turn after a zero exit code.
- A terminal ID, timeout, or background handoff is not completion. Use the durable local pipeline journal for long workflows, but do not treat it as a mechanism that can wake an ended turn.
- Before each expensive phase, persist `running`; after it, persist `passed` or `failed`, exit code, HEAD, timestamps, and artifacts. Distinguish `running`, `interrupted`, `failed`, and `passed`.
- Build/deploy does not launch UI. Packaged E2E owns launch and exact package selection.
- Once an action is promised, start the corresponding command in the same response.

Canonical bounded pipeline:

```powershell
pwsh -File local-tdd-kit/Invoke-LocalTddPipeline.ps1 `
    -E2EPath test/e2e/tests/Feature.AgentSelectAll.Tests.ps1
```

## User-Visible Contract

- With the agent pane focused, plain `Ctrl+A` selects every cell in the current WTA rendered frame.
- Selection uses the same `TextSelection` state, extraction, reverse-video overlay, `Ctrl+C` copy, right-click Copy, copied confirmation, and clear-after-copy behavior as mouse selection.
- `Ctrl+A` never enters `a`, clears the prompt draft, closes the pane, submits a prompt, or requests Default Paste.
- The next `Ctrl+C` copies selected frame text and clears the selection. A later `Ctrl+C` resumes existing draft-cancel behavior and cannot replay stale selected text.
- Any other ordinary key continues to clear WTA text selection before normal handling.
- Wide glyphs are selected/extracted once, trailing cell padding is not copied, and empty buffers do not create a copyable selection.
- Selection is limited to the current rendered WTA frame; off-screen virtual chat history and native Terminal scrollback are not included.

## Preserved Invariants

- Plain drag, double-click word, triple-click line, `Ctrl+C`, and right-click Copy behavior remain unchanged.
- Right-click with no WTA text selection still requests owner-scoped Default Paste exactly once.
- Existing `Ctrl+Shift+A` continues to invoke generic TerminalControl `SelectAll`.
- WTA mouse capture, completed-turn click navigation, prompt editing, and input focus are unchanged.
- No protocol, C++, XAML, settings schema, localization, provider, authentication, or model changes.

## Guardrails

- Implement through existing WTA `TextSelection`; do not add a parallel clipboard or selection path.
- Do not use a test-only product route or assert only internal state when clipboard/rendered behavior is the contract.
- The publishable E2E must use a deterministic local ACP fixture and zero model tokens.
- Real Copilot/Claude/Codex/Gemini/OpenCode prompts, `Assert-AI`, `Invoke-AgentJudge`, and `Get-AgentCliStatus` probes remain local/dev-only and must not enter the publish diff.
- Preserve unrelated user changes and only format touched Rust files.

## Ownership Hypothesis

```text
physical or injected Ctrl+A
  -> WT/ConPTY win32-input sequence
  -> crossterm Event::Key
  -> AppEvent::Key
  -> TextSelection::select_all over latest frame snapshot
  -> snapshot_and_render reverse-video overlay
  -> existing Ctrl+C/right-click copy_text_selection
  -> OS clipboard + selection-copied confirmation
```

- Owning code path: `tools/wta/src/app_events.rs`, `tools/wta/src/text_selection.rs`
- Owning abstraction: `TextSelection`
- Falsifiable hypothesis: `Ctrl+A` currently reaches `AppEvent::Key`, but there is no select-all branch and no `TextSelection::select_all`; the event clears selection and falls through as a no-op.
- Cheapest discriminating check: seed a frame, send `Ctrl+A`, and assert selected text equals every rendered row with trailing padding trimmed. Current code cannot satisfy that assertion.
- Nearest unit tests: `tools/wta/src/text_selection.rs` selection extraction/render tests and `tools/wta/src/app_tests.rs` right-click copy/clear tests.
- Nearest packaged suite: new deterministic `test/e2e/tests/Feature.AgentSelectAll.Tests.ps1`, using `test/e2e/fixtures/Mock-AcpChatAgent.ps1` and existing ItE2E input/clipboard primitives.

If baseline does not fail at this exact oracle, stop product editing and update the hypothesis.

## Commit And Worktree Discipline

- Dev-only preparation and evidence stay on the dev branch. The TDD kit, this handoff, raw logs, screenshots, reports, and any token-consuming acceptance harness never enter publish.
- Product code, owning unit tests, deterministic zero-token packaged E2E, and release-checklist metadata form one self-contained publishable commit on dev.
- The clean publish worktree receives only that publishable commit via direct cherry-pick.
- Never cherry-pick mixed commits and restore files afterward. Never force-add ignored evidence.
- Do not create extra branches, rewrite pushed history, or use destructive Git commands.
- Push dev and verify its remote head before pushing the exact validated publish head.

## Test Reuse And Framework Boundaries

- Extend `TextSelection` tests rather than creating a second selection model.
- Add a focused App key-routing test proving `Ctrl+A` owns the key and later `Ctrl+C` uses the existing copy path.
- Add one deterministic packaged suite only when it proves WT/ConPTY key delivery, frame selection, OS clipboard output, and stale-selection clearing beyond unit coverage.
- Do not use a real provider. A local fixture is sufficient because model semantics are not under test.
- Update the release checklist with one independently releasable C-ID/title, and validate report mapping from exact packaged E2E results.

## Reproduction And RED Oracle

### Baseline Identity

- Source commit: dev preparation HEAD `1aac986d479abc744ba5cc4cad6e72683e1030ea`, whose product sources match base `0c2062bc5837b2ae335f86a00d068828d76af2d5`
- Build command: `pwsh -File local-tdd-kit/Invoke-LocalTddPipeline.ps1`
- Package: `IntelligentTerminal_rd9vj3e6a2mbr`, x64 Debug loose package
- Deploy: `local-tdd-kit/Invoke-BuildDeploy.ps1` through the durable pipeline
- Relevant binaries: explicit-target Cargo `wta.exe`, package staging/installed `wta.exe`, source-matched `wtcli.exe`, `WindowsTerminal.exe`, protocol WinMD, and `resources.pri`
- Source/deployed hashes: pending baseline pipeline receipt

### Baseline Reproduction

1. Build/deploy the exact baseline and verify source/staged/installed hashes.
2. Launch Dev with a deterministic local ACP fixture and unique visible draft marker.
3. Put a clipboard sentinel in place, inject `Ctrl+A` then `Ctrl+C` through WT/ConPTY.
4. Capture pane text, clipboard, logs, report, and RED screenshot.
5. Prove setup is healthy before asserting the selection failure.

- RED oracle: clipboard remains the sentinel or lacks the visible marker because `Ctrl+A` did not create a WTA selection; `Ctrl+C` instead follows ordinary draft-cancel behavior.
- Expected failure: unit selection assertion fails and packaged clipboard assertion reports that the selected rendered frame marker was not copied.
- GREEN oracle: clipboard contains the unique visible marker plus frame text, selection is visibly highlighted before copy, and a second `Ctrl+C` cannot replay stale selected text.
- RED artifacts: `local-tdd-kit/artifacts/agent-pane-select-all/red/`

## Strict TDD Workflow

1. Build/deploy exact baseline and record receipt, package path, sizes, and SHA-256.
2. Add the smallest `TextSelection` and key-routing tests; run them and require expected RED.
3. Add packaged deterministic E2E; run against baseline and require clipboard RED.
4. Implement only `TextSelection::select_all` and the `Ctrl+A` key intercept supported by evidence.
5. Immediately rerun focused tests; repair only the same ownership slice if needed.
6. Run neighboring selection/copy/right-click/mouse tests and full WTA.
7. Run `cargo fmt --check`, PowerShell parser, whitespace checks, and editor diagnostics.
8. Build/hot-refresh/package as required and run packaged E2E against explicit Dev.
9. Capture fresh GREEN screenshots and inspect every image.
10. Commit one publishable product/test/checklist commit and a separate dev-only handoff update.
11. Cherry-pick only the publishable commit into the clean publish worktree.
12. From exact publish HEAD, run full WTA, build/deploy/freshness, packaged E2E, hash equality, and fresh visual evidence.
13. Audit changed E2E files for real-agent/token patterns before publish push.
14. Push dev, then publish, and verify both remote heads.

## Commands

- Focused unit: `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml select_all`
- Neighboring unit: `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml text_selection`
- Full WTA: `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml`
- Explicit WTA build: `cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml`
- Durable pipeline: `pwsh -File local-tdd-kit/Invoke-LocalTddPipeline.ps1 -E2EPath test/e2e/tests/Feature.AgentSelectAll.Tests.ps1`
- Package selector: `ITE2E_PACKAGE=Dev`

## Validation Matrix

| Layer | Expected | Current result | Evidence |
| --- | --- | --- | --- |
| Framework bootstrap | Required tools/module available | Passed | Console output |
| Framework core/pipeline | Hermetic selftests pass | 35 passed | Console output |
| Framework physical input | Interactive foreground available | Blocked: 1 passed, 3 foreground failures | Console output |
| Initial baseline build/deploy | Recipe sources resolve | Failed on URI-escaped `Program Files %28x86%29`; framework RED | Failed pipeline journal |
| Exact baseline build/deploy retry | Fresh package and matching hashes | Pending | Pipeline journal/receipt |
| Focused RED | Fails because select-all is absent | Pending | Focused output |
| Packaged RED | Clipboard marker absent | Pending | RED report/screenshot |
| Focused GREEN | Selected full-frame text | Pending | Focused output |
| Neighboring tests | No selection/copy regression | Pending | Test output |
| Full WTA | All required tests pass | Pending | Test output |
| Dev packaged E2E | Clipboard/stale-selection contract passes | Pending | NUnit/report/screenshots |
| Exact publish | Source/installed hashes and E2E pass | Pending | Publish receipt/report |

## Implementation Record

- Behavioral change: pending RED
- State/API changes: pending RED
- Preserved invariants: listed above
- Performance implications: expected O(1) selection-state setup plus existing O(frame cells) overlay and extraction; verify after implementation
- Security/privacy implications: clipboard receives only user-visible rendered text after explicit `Ctrl+A` + copy; no new data source or network path
- Rejected alternatives:
  - Generic TerminalControl `SelectAll`: wrong ownership and includes native scrollback instead of WTA current frame.
  - Virtualized-history selection: substantially larger semantic/lifecycle scope.
  - Parallel selection model: duplicates existing drag/copy/right-click state and risks divergence.

## Visual Evidence

- Required matrix: baseline before `Ctrl+A`, baseline after `Ctrl+A`, GREEN after `Ctrl+A`, after `Ctrl+C` confirmation, and post-copy stale-selection control.
- Provenance: exact HEAD, package path, source/staged/installed hashes, fixture, and capture command.
- Inspection: nonempty real product UI, whole intended frame visibly selected, no overlap/clipping, no mock window, and no stale highlight after copy.
- Latest evidence directory: `local-tdd-kit/artifacts/agent-pane-select-all/`

## Review Triage

- Current status: no review yet
- Open items: baseline identity, RED, implementation, full/exact publish validation
- Every future finding must record decision, rationale, RED/GREEN evidence, and publish commit.

## Local-Only Evidence Inventory

| Artifact | Path | Proves | Identity |
| --- | --- | --- | --- |
| Baseline receipt/journal | `local-tdd-kit/artifacts/agent-pane-select-all/red/` | Exact RED package | Pending |
| Focused test output | same root | Ownership RED/GREEN | Pending |
| Packaged report | same root | WT/ConPTY/clipboard contract | Pending |
| RED/GREEN screenshots | same root | User-visible selection | Pending |

## Completion Checklist

- [x] Feature metadata, ownership, scope, branch policy, and commands are concrete.
- [x] Latest TDD kit and AGENTS source snapshots are on dev only.
- [x] Publish branch is clean at exact latest main.
- [ ] Exact baseline build/deploy is fresh and RED at the expected oracle.
- [ ] Focused regression is RED then GREEN.
- [ ] Neighboring/full/static validation passes.
- [ ] Publishable and dev-only commit boundaries are clean.
- [ ] Exact publish binary hashes match and packaged E2E is GREEN.
- [ ] Fresh screenshots are inspected and recorded.
- [ ] Changed publish E2E is deterministic and zero-token.
- [ ] Dev and publish remote heads are pushed and verified.

## Optional Follow-Ups

- Consider full virtualized-chat-history selection as a separate feature with its own semantics.
- Consider whether native TerminalControl `Ctrl+A` should remain configurable independently; do not alter it in this feature.
