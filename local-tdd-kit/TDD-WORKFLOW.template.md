# Local TDD Workflow Template

## Fill These Before Starting / 开始前必须替换

- `<ISSUE_ID_AND_LINK>`: issue and regression reference
- `<USER_VISIBLE_CONTRACT>`: behavior that must remain true
- `<BASE_REF_AND_HASH>`: clean base used for the work
- `<DEV_BRANCH>`, `<PUBLISH_BRANCH>`, `<REMOTES>`, `<WORKTREES>`
- `<OWNING_CODE_PATH>`: code that directly computes or mutates the behavior
- `<CHEAP_DISCRIMINATING_CHECK>`: smallest check that can falsify the hypothesis
- `<RED_TEST_NAME>` and `<FOCUSED_TEST_COMMAND>`
- `<BUILD_SURFACES>`: WTA, SettingsModel, SettingsEditor, TerminalApp, protocol, package
- `<LIVE_E2E_CASES>` and `<PACKAGE_SELECTOR>` (normally `Dev`)
- `<LOCAL_ARTIFACT_DIR>` and `<SENSITIVE_DATA_RULES>`
- `<DEFINITION_OF_DONE>`

Remove instructions that do not apply. Add issue-specific invariants, failure
signatures, environment prerequisites and exact acceptance oracles. Do not leave
angle-bracket placeholders in an active workflow.

## Task Contract

- Issue: `<ISSUE_ID_AND_LINK>`
- User-visible contract: `<USER_VISIBLE_CONTRACT>`
- Regression signature: `<EXACT_OLD_FAILURE>`
- Negative control: `<SIMILAR_INPUT_THAT_MUST_NOT_TRIGGER>`
- Owning code path: `<OWNING_CODE_PATH>`
- Integration boundary: `<PROCESS_PROTOCOL_UI_OR_PERSISTENCE_BOUNDARY>`
- Oracle priority: protocol/event, persisted state, structured log, rendered UI,
  then model output only when model output is itself under test.

## Branch and Scope

- Base: `<BASE_REF_AND_HASH>`
- Dev branch/worktree: `<DEV_BRANCH>` / `<DEV_WORKTREE>`
- Publish branch/worktree: `<PUBLISH_BRANCH>` / `<PUBLISH_WORKTREE>`
- Remote policy: `<REMOTES_AND_PUSH_POLICY>`
- Product commits contain product behavior and durable tests only.
- Local tracking, orchestration, captures and credentials do not enter publish commits.
- Never revert unrelated user changes in a dirty worktree.

## Baseline

1. Cherry-pick the local TDD kit commit.
2. Run `local-tdd-kit\install-tools.cmd` and `bootstrap.ps1 -Check`.
3. Record `git status`, base hash, installed package identity and tool versions.
4. Run the nearest existing test before edits: `<BASELINE_COMMAND>`.
5. If live behavior is involved, verify package freshness before trusting it.

## Strict RED/GREEN Loop

For every behavior change:

1. Add or modify the smallest test in the existing framework.
2. Run `<FOCUSED_TEST_COMMAND>` and require RED for `<EXPECTED_RED_REASON>`.
3. Make the smallest grounded product edit.
4. Immediately rerun the same focused command; do not widen scope first.
5. If it fails locally, repair the same slice and rerun.
6. Run the nearest module/project suite.
7. Build/deploy only the affected layers, then run freshness verification.
8. Run `<LIVE_E2E_CASES>` against explicit `<PACKAGE_SELECTOR>`.
9. Record test totals, build result, receipt hash and artifact paths.
10. Commit/push according to the branch policy before starting the next RED step.

## Build and Deploy

- Changed layers: `<BUILD_SURFACES>`
- Focused build commands: `<FOCUSED_BUILD_COMMANDS>`
- Package command: `<PACKAGE_BUILD_COMMAND>`
- Deployment command: `<DEPLOY_COMMAND>`
- Freshness command:
  `pwsh -File local-tdd-kit/Verify-DeploymentFreshness.ps1`
- Require explicit-target WTA and Cargo/AppX/installed SHA-256 equality.
- Require installed Dev layout and live process paths to belong to this worktree.
- Set `ITE2E_PACKAGE=Dev`; a skipped test is not GREEN.
- For bounded build/test/deploy/E2E work, use direct synchronous terminal execution with no tool
  timeout. Never leave a required phase in the background and end the agent turn.
- If a runner unexpectedly returns a terminal ID, record it; do not poll, sleep, or duplicate the
  command. Continue only independent safe work, then retrieve final output from the platform's
  automatic completion notification. Do not start deploy or another dependent phase until the
  real exit code is zero.
- Do not reuse the persistent shell that owns a handed-off terminal ID. A second command can
  interrupt the active batch with Ctrl+C; use read-only tools or a separately isolated terminal.
- Prefer `Invoke-LocalTddPipeline.ps1 -E2EPath <LIVE_E2E_CASES>` for an interruption-sensitive
  exact-package cycle. Record its `pipeline-state.json` path and require final status `passed`.
- Keep build/deploy non-launching. `-Launch` can steal foreground focus and visibly flash; let the
  E2E harness launch and bind the exact PID/HWND only when UI interaction starts.
- Keep an explicit active-task ledger while automation runs. A status request, explanation, or other
  non-conflicting interleaved question does not complete the workflow: answer it briefly, then resume
  the next incomplete action in the same response and issue an actual tool call. Do not send a final
  answer while required phases, checklist items, or terminal/journal states remain incomplete unless
  the user explicitly pauses or redirects the work.
- Treat missing or truncated command output as `unknown`, never as pass. If a persistent terminal ID
  exists, keep it exclusive and consume only its automatic completion result. Otherwise inspect the
  process identity and durable journal/receipt/report first. Rerun only a cheap, idempotent check with
  synchronous no-timeout execution and filtered output; do not duplicate an expensive build merely
  because an execution helper lost its summary.

## Local Evidence and Security

- Evidence root: `<LOCAL_ARTIFACT_DIR>`
- Keep raw logs, screenshots, wire captures and provider configs ignored.
- Never commit credentials, tokens, account identifiers, prompts, local paths,
  isolated provider homes or unredacted session data.
- Copy only intentionally selected, sanitized evidence to a tracked review folder.
- Do not delete ignored local evidence merely because it is absent from Git status.

## Review Hygiene

- Verify each review comment against the owning code path before accepting it.
- Fix valid findings; explain declined findings with concrete behavior evidence.
- Keep the publish diff limited to current product behavior.
- Preserve historical reasoning in dev-only tracking, not stale product comments/tests.
- Check `git diff --check`, line endings, generated files and exact dirty paths.

## Definition of Done

- [ ] `<USER_VISIBLE_CONTRACT>` is satisfied.
- [ ] Active task ledger is empty; no interleaved question ended the workflow early.
- [ ] Focused RED failed for the expected reason.
- [ ] Focused GREEN and relevant suites pass.
- [ ] Build receipt matches the current source fingerprint.
- [ ] Durable pipeline journal is `passed`; no required terminal or phase remains `running`.
- [ ] Product, staged package and installed hashes match.
- [ ] Live E2E targets the intended Dev package and process/window identity.
- [ ] Negative controls and existing behavior pass.
- [ ] Every skip is explained as an external prerequisite, not a product failure.
- [ ] Logs/telemetry contain no prohibited sensitive data.
- [ ] Product/dev-only branch scope is correct.
- [ ] Commits are pushed and remote synchronization is verified.
- [ ] Tracking is self-contained enough for another machine/engineer to continue.