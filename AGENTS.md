# Yolo Mode PR #505 开发与交接

> 本节是 PR #505 的 dev-only 工作记录。它记录 investigation、TDD 计划、review
> evidence 和本地验收，不进入 publish branch。产品行为、提交到 publish branch 的测试和
> exact package evidence 才是最终事实来源。

## 文档维护规则

1. 每次开始工作先更新 `Current Stage`、branch/head、最新 `origin/main` 和下一条命令。
2. 所有产品修改先构造可复现 RED，再修改 owning abstraction；首次实现 edit 后立即跑同一 focused check。
3. 本地 orchestration、raw logs、screenshots、provider homes 和凭据只放在 ignored evidence root。
4. `AGENTS.md` 与 `local-tdd-kit/` 是 dev-only；不得 cherry-pick 到 PR #505 的 publish branch。
5. UI、安全边界或真实 provider 行为发生变化时，必须重新 build/deploy exact publish HEAD 并取得 fresh evidence。

## Feature Metadata

- Feature: Yolo mode / provider-native ACP session modes
- Summary: persistent global default, per-ACP-session `/yolo on|off`, reviewed native
  modes for Copilot, Claude, Codex and Gemini, and `AllowYoloMode` policy gating.
- User-visible goal: provide an explicit, reversible way to let a trusted agent continue
  through its own tool permission requests, without bypassing the product-owned terminal
  action card, and produce a reviewable package for Hamza's design/security review.
- Pull request: https://github.com/microsoft/intelligent-terminal/pull/505
- Related issue: https://github.com/microsoft/intelligent-terminal/issues/326
- Original PR head / takeover baseline: `3adc45bc69941cad108ca9799df78a1d42c95de8`
- Latest audited `origin/main`: `adffd21eff63b131788e560f38090616c20182a4`
- Common ancestor: `e870a3630a785a44cbd22190b5c8808c7084b31f`
- Dev branch/worktree: `dev/dinah/yolo-mode` / `C:\ado\intelligent-terminal-bugfix`
- Dev branch is locally merged at `2fdfb4ad8ce41a5c1067937a529b3236cdcf5564`;
  keep dev-only orchestration and evidence local and unpushed.
- Publish branch/worktree: `dev/vanzue/yolo-mode` /
  `C:\ado\intelligent-terminal-yolo-publish`
- Publish remote: `origin/dev/vanzue/yolo-mode`; remote and local are both at
  `0e8be3a9815a3fba8339f045ecb9eeae8e321fcb`. Original branch author Kai (`vanzue`)
  approved using this as the publish branch and directly pushing validated publishable
  commits for the security review process on `2026-08-25`.
- Evidence root: `local-tdd-kit/artifacts/yolo-mode/` (ignored; not created yet).
- Review evidence directory: to be chosen only for sanitized artifacts intended for review.
- Current takeover commits: cloud metadata fix `8b24342c`, pre-format main merge
  `c264cb5a`, WTA format `13d2cb39`, main-tip merge `4c37da5b`, and provider-native
  Yolo `7c8a6822`, permission-contract cleanup `ce0be5f5`, and locale wording cleanup
  `0e8be3a9`. Both remotes contain the same publishable HEAD.
- Out of scope for PR #505: trusted/allowed working directories, a read/search-only
  ToolKind allowlist, per-application/executable policy, provider negotiations, and the
  future available-commands `/command` integration.

## Current Stage

`2026-08-25` product decision: WTA is an ACP UI for Yolo mode. Remove every generic
provider-permission `AllowOnce` auto-selection and invoke only provider-advertised ACP
session capabilities. Target native support is Copilot, Claude, Codex and Gemini;
OpenCode and custom agents remain interactive unless their ACP server later advertises
an explicitly supported capability. Provider-defined mode semantics are accepted as the
provider contract and must be represented accurately in UI/security review.

`2026-08-25`: `origin/main@73cf3510d` is merged; dev is ahead 22 and behind 0 before the
uncommitted provider-native slice. The merge preserved incoming session-close,
crash/reconnect, hot model settings and format changes. The cloud-catalog metadata fix is
committed at `8b24342c`.

Provider-native-only TDD is GREEN. WTA no longer selects any ACP permission option for the
user, including proposal/session-MCP requests; validated requests go through the normal
permission UI. `native_yolo.rs` discovers and applies Copilot `allow_all`, Claude
`bypassPermissions`, Codex `agent-full-access`, and Gemini `yolo`, restores each session's
captured value, rejects OpenCode/custom enable, serializes per-session writes, supersedes
stale desired operations and fences reused session IDs. Yolo tests pass `29/29`; native
coordinator tests pass `12/12`; explicit-permission tests pass `3/3`. Full WTA passes
`1725/1725` with a freshly built main-tip `wtcli.exe` first on PATH.
- Existing PR reviews and current code were audited. Several findings remain open below.
- Installed/provider package surfaces were inspected without starting ACP servers or
  changing authentication. Temporary package/source copies were removed afterward.
- Dev-only TDD kit bootstrap passed; hermetic Unit selftests passed `16/16`. Win32
  Input selftests passed identity `1/4`, while three input cases were blocked because
  this tool session had no foreground HWND and the safety guard correctly sent no input.
- Provider semantics were audited separately below. WTA invokes the provider's advertised
  ACP mode as one contract and does not independently configure sandbox settings. Codex and
  Gemini modes bundle broader access semantics; Settings/spec text now states this explicitly.
- Product changes currently include provider-native capability discovery/RPC coordination,
  permission UI behavior, lifecycle/race fixes, Gemini `--acp`, GPO templates, all 16
  SettingsEditor locale resources, and updated specs. The follow-up product delta is
  committed, byte-identical in the dev and publish histories, and pushed to both remotes;
  it has not been rebuilt into a package or presented as review evidence.
- `2026-08-26` follow-up security audit found one production constructor of an ACP
  `Selected` permission outcome, reached only through the permission-card responder in
  explicit key handling. The obsolete generic-approval host/helper flag was renamed to
  `--yolo-mode`; stale silent-permission E2E/spec language was removed; and
  deterministic tests prove Yolo plus `AllowOnce`/`AllowAlways` offers remain pending.
  Permission tests pass `47/47`, locale parity passes, Yolo tests pass `25/25`, full WTA
  passes `1723/1723`, and the focused TerminalApp build passes. The final explicit-target
  `wta.exe` hash is `F4F9468DD4E86A7CEDEE33549DB75F021C3D437E14E8FEF87FA5FF0F21AB0299`.
  These follow-up changes are not represented by the earlier `7c8a682` package receipt.
- Provenance audit separates inherited main behavior from PR-only behavior. Main introduced
  canonical-proposal `AllowOnce` selection in `b934584c0` / #484 (`2026-08-05`), terminal-
  action MCP selection in `69f5685f2` / #559 (`2026-08-07`), and user-input MCP selection in
  `8539ac61a` / #606 (`2026-08-12`); main design/E2E text came from #367, #559 and #586.
  The PR-only generic Yolo interception began in `c7821c649` and `8fbeefaf2` on `2026-07-28`.
  Commit `7c8a682` removed every production auto-selection path, and the current delta removes
  the remaining old flag, fixture, docs/E2E oracle and UI wording. All 85 real WTA locales use
  the reviewed en-US provider-native summary until native-language translations are reviewed.
- Maestro-backed Claude testing is now locally viable without a Claude account: the live
  proxy, direct Claude CLI, and repo-pinned ACP adapter handshake all passed under an
  isolated temporary home. This remains dev-only evidence and is not a publish dependency.
- `2026-08-26` final-E2E decision: acceptance must exercise normal user-cost model turns,
  not stop at zero-token handshakes. Use the exact deployed publish package and one bounded,
  realistic chat/tool workflow per provider. Copilot, Gemini and OpenCode use their current
  real provider credentials. Claude and Codex may use Agent Maestro as the model backend,
  but evidence must label this accurately: the real CLI and pinned ACP adapter run, while
  VS Code LM supplies inference, so vendor-account authentication/billing is not covered.
- Current fixture readiness: Claude `0.65.0` is cached and the isolated Maestro ACP probe
  passes in about five seconds without changing real Claude config. The Codex fixture installs
  exact adapter `1.1.13` into a temporary root through the configured package-feed proxy, then
  completes ACP initialize/session-new in about nine seconds with seven models and leaves real
  Codex config unchanged. Cold adapter installation exceeded 180 seconds on one attempt, while
  production gives npx adapters 60 seconds to initialize; the final package matrix must include
  a true empty-cache Codex first run and must not prewarm it before claiming that case passes.
- `2026-08-26` exact publish HEAD `0e8be3a9` is built, deployed and freshness-verified. The
  packaged core Yolo suite is green (`5` pass, `0` fail, `1` policy skip); live Copilot and
  OpenCode checks pass; and the warm-cache Codex/Maestro provider-native tool workflow passes.
  The cold Codex adapter path remains a real 60-second startup-budget failure.
- Packaged Gemini `0.51.0` advertises `yolo` but correctly rejects it as untrusted. A no-prompt
  PEB diagnostic proved the deployed master and both helpers run with cwd
  `C:\Windows\System32`, including a tab created with an explicit disposable `-d` workspace.
  The root cause was that C++ forwarded `--agent-source-cwd` only for WSL and Rust discarded a
  reported host cwd. Publishable commit `cd2b2e88` now preserves the host workspace through
  Terminal, helper and ACP `session/new`; Gemini still owns and enforces the trust decision.
- `2026-08-27` product decision: do not add a WTA-owned Gemini trusted-folder prompt, mutate
  `~/.gemini/trustedFolders.json`, or bypass trust with `GEMINI_CLI_TRUST_WORKSPACE`. Gemini
  keeps its provider-owned untrusted-workspace rejection. The current slice is refactoring only:
  split each built-in provider's native Yolo contract into its own module while preserving the
  common session coordinator, ACP behavior and exact user-visible errors.
- Current branch/head is `dev/dinah/yolo-mode@2fdfb4ad`, merged with `origin/main@adffd21e`
  (`2026-08-27`, #672) and behind by zero. Publishable follow-ups are `cd2b2e88` (host cwd),
  `d5dcade6` (provider modules), `28731c1a` (packaged E2E/release coverage), `e1f479dc`
  (merged completion contract), and `d129e508` (behavioral provider adapters). Each known
  provider now owns capability discovery plus enable/disable transition planning; the common
  coordinator owns only session state, restore persistence, sequencing, lifecycle fencing and
  ACP transport execution. Cross-channel config/mode updates preserve the user's restore target,
  and generic config responses refresh provider state. Gemini trust behavior and every existing
  user-visible error are unchanged. Focused native Yolo tests pass `20/20`, Yolo tests pass
  `33/33`, permission tests pass `47/47`, full WTA passes `1812/1812` with source-matched
  `wtcli.exe`, and the explicit-target product build passes.
- The dev merge preserved main's ACP slash-command metadata/completion architecture and longer
  Autofix card waits while retaining explicit provider permission selection, Yolo mode updates,
  popup completion and session cleanup. Focused post-merge tests pass: slash commands `63/63`,
  native Yolo `14/14`, and permission `47/47`.
- The newest main merge additionally preserves #672 tool-call presentation; its focused tests
  pass `37/37` alongside native Yolo `20/20` and Yolo `33/33`.
- Next command is a dev-only handoff commit. Then merge `origin/main@adffd21e` into publish,
  cherry-pick only `d129e508`, and rebuild/deploy/test the exact publish HEAD before pushing.

## Scope And Contract

### User-Visible Contract

- `agentPane.yoloMode` defaults to `false`, persists in settings, and acts as the
  default for every session without an explicit override.
- `/yolo`, `/yolo on`, and `/yolo off` target only the current ACP `session_id`.
  The command commits state and prints `● /yolo on` or `○ /yolo off` only after
  the provider-native operation, when required, acknowledges success.
- Global off plus `/yolo on`, and global on plus `/yolo off`, must both work.
  `/new`, session replacement, tab reset/close, and `/restart` must not leak an
  override or pending operation into a later session, including reused IDs.
- `AllowYoloMode=0` must disable both entry points at startup and at runtime,
  clear overrides, disable any provider-native mode, and restart the agent stack
  if native disable cannot be confirmed.
- WTA never selects `AllowOnce`, `AllowAlways`, or another ACP permission option for the
  user. Ordinary provider, proposal-MCP and user-input-MCP permission requests use the
  normal permission UI after product-owned validation.
- Yolo invokes only an exact provider-advertised ACP session capability for a reviewed
  canonical provider. WTA accepts the provider's mode as one contract; it does not split
  permission and sandbox effects or add independent CLI flags/configuration.
- The explicit slash status, errors and Settings warning are the user-visible state
  surfaces. Unsupported providers continue prompting normally.
- `/yolo` before a session exists is currently a silent no-op. This is documented
  current behavior, not a desired invariant; design review should decide whether
  to queue intent or report that no session exists.
- The product-owned `request_terminal_actions` path still stages a recommendation
  card and requires the user's confirmation before mutating a terminal pane.

### Preserved Invariants

- Master-attested canonical agent identity, not a helper-supplied command or a
  lookalike config option, decides whether a provider-native mapping is allowed.
- Proposal-MCP and legacy canonical proposal permissions are validated before entering
  the normal permission UI; stale or non-canonical proposals remain cancelled.
- Tab/window/session routing, model picker metadata, cloud catalogs, session close,
  crash recovery and agent switching must continue to work when identity metadata
  or Yolo state is added.
- Existing non-Yolo permission prompts, settings migration and custom ACP commands
  remain compatible.
- Tool effects are provider-defined. WTA does not claim `ToolKind` or
  `session/request_permission` as a complete Yolo authorization boundary.

### Guardrails

- Do not market `ToolKind` as an authorization boundary. Current Yolo behavior can
  approve read, search, edit, delete, execute, fetch and unknown tools alike.
- Do not treat provider CLI flags as equivalent to a reversible ACP session API.
  Each native mapping needs an exact identity, advertised capability, enable value,
  restore value, lifecycle contract and negative tests.
- Do not describe provider modes as permission-equivalent when they bundle sandbox/access
  policy. Record and display the bundled behavior; do not silently narrow or expand it.
- Do not treat prompt instructions as a security boundary. An Agent CLI inherits a
  user-context execution environment and may reach the existing COM surface directly.
- Do not add trusted directories or read/search-only policy to this already large PR.
- Do not use test-only product paths or model prose as the oracle for permission,
  routing or policy behavior.
- Only format touched files after the incoming `main` format commit is integrated.

### Security Boundary To Review

There are two distinct command paths:

1. Agent-owned tools run inside the Agent CLI. Yolo may suppress or auto-answer
   their ACP permission requests. A provider may also execute tools without asking.
2. `request_terminal_actions` proposes mutations to user-owned terminal panes. The
   normal WTA path validates the session and requires a recommendation-card action.

The second statement is not a complete sandbox guarantee. `doc/security-model.md`
records that the runtime `aiIntegration.confirmation.*` settings are not generally
enforced on COM operations, and an in-pane/user-context process that can activate
`IProtocolServer` and learn a pane GUID can call methods such as `SendInput` directly.
An Agent that is allowed to run arbitrary commands could therefore bypass the proposal
UX by invoking `wtcli`/COM itself. Security review must evaluate this explicitly so the
UI does not imply that every command affecting a terminal will necessarily be shown for
approval. The system prompt's instruction to use `request_terminal_actions` is defense
in depth, not authorization.

### Product And Security Decisions Needed

- **Decided `2026-08-25`:** no generic WTA permission interception. Yolo invokes only
  reviewed provider-native ACP session capabilities; every permission option requires an
  explicit user selection.
- Security review must confirm that Settings/spec copy accurately describes provider-owned
  effects without suggesting a terminal-wide authorization boundary.
- Decide whether the global setting is truly app-wide, as implemented, or was intended
  to be per executable/profile/application.
- Revisit the term `Yolo` with Hamza before release; code/schema migration implications
  are small now and grow after public release.
- Track the future available-commands `/command` overlap as a separate product decision.
- Treat trusted directories and read/search-only permissions as a separate authorization
  design. It needs path/cwd provenance, tool taxonomy, unknown-tool fail-closed behavior,
  persistence/removal UX and shell/network escape analysis.

## Provider Capability Snapshot

Static/package inspection was refreshed on `2026-08-25` against the exact pinned Claude
and Codex adapters plus installed Gemini. The implementation maps only exact canonical
provider identities and capability shapes; it captures each session's restore value.

| Provider | Audited surface | Native ACP/session capability | Current PR path / conclusion |
|---|---|---|---|
| Copilot | Installed CLI `1.0.80`; PR contains a captured schema >= 1.1 response | `configOptions`: `allow_all`, category `permissions`, Select `on/off` | Native path is implemented. Fresh live wire verification is still required. |
| Claude | Repo pin `claude-agent-acp@0.65.0`; npm latest `0.69.0` | `configOptions` and legacy `modes` expose `bypassPermissions`; adapter policy/root rules remain authoritative | Implemented with captured restore value; live enable/disable acceptance pending. |
| Codex | Repo pin `codex-acp@1.1.13`; npm latest `1.4.0` | `configOptions` and legacy `modes` expose `agent-full-access`, mapping to `approvalPolicy=never` plus `dangerFullAccess` | Implemented as the provider's complete advertised contract; UI/security text discloses bundled access semantics. |
| Gemini | Installed CLI `0.51.0` | `modes` exposes `yolo` alongside `default`, `autoEdit`, and optional `plan`; privileged modes are trust/policy gated | Implemented through `session/set_mode`; launch updated to `gemini --acp`; live acceptance pending. |
| OpenCode | Installed/source tag `1.18.3` at `127bdb30784d508cc556c71a0f32b508a3061517` | No reviewed reversible ACP session Yolo capability | Unsupported for Yolo; ordinary permission UI remains. CLI `run --auto` is not used. |

The static package audit did not authenticate, start ACP servers, install or update
providers. The later Maestro acceptance below started the pinned Claude adapter with an
isolated local configuration, but did not use or modify a formal Claude account.

### Maestro-Backed Claude Fixture (Dev Only)

Agent Maestro `2.11.1` is installed in VS Code and exposes an Anthropic-compatible proxy
at `http://127.0.0.1:23333/api/anthropic`. It is not a fake Claude ACP server: the test
still runs real Claude Code and the real repo-pinned `claude-agent-acp@0.65.0`; Maestro
replaces only the model backend with a model available through VS Code LM.

Verified on `2026-08-25`:

- `/openapi.json` returned HTTP 200 and `/api/v1/lm/chatModels` reported 37 models.
- A direct Anthropic-compatible request using `gpt-5.6-luna` returned the exact expected
  marker `MAESTRO_ANTHROPIC_OK`.
- Claude Code `2.1.210` under an isolated home returned `MAESTRO_CLAUDE_CLI_OK` with no
  formal Claude account.
- The current explicit-target `wta.exe` ran production `probe-models` against
  `npx -y @agentclientprotocol/claude-agent-acp@0.65.0`; ACP `initialize` plus
  `session/new` succeeded in about 34 seconds and reported six models with
  `current_model_id=gpt-5.6-luna[1m]`.
- SHA-256, length and mtime checks proved the real user `~/.claude/settings.json`,
  `~/.claude/config.json`, and `~/.claude.json` were unchanged; temporary files were removed.

Usage rules:

- Use `local-tdd-kit/Invoke-MaestroClaudeAcpProbe.ps1`; it creates a temporary HOME,
  `USERPROFILE`, `CLAUDE_CONFIG_DIR`, onboarding state, dummy token and npm cache, then
  deletes them in `finally`.
- Never invoke Maestro's one-click `Configure Claude Code Settings` for this test. Even
  workspace mode also writes user-level `~/.claude/config.json` and `~/.claude.json`.
- Query the live model list and pass an available model explicitly. The local fixture uses
  Maestro's `[1m]` suffix rule for models whose advertised context is in the 1M band.
- Maestro, its configuration, npm cache, logs, receipts and probe scripts are dev-only.
  They must stay under `local-tdd-kit` or ignored local storage and must never be copied,
  committed, or cherry-picked into the publish branch.
- Use deterministic in-process/mock ACP transports for RED/GREEN unit tests. Use Maestro
  only for live Claude adapter acceptance because model behavior is not deterministic and
  requires a running VS Code extension plus an available VS Code LM entitlement.
- If Maestro API authentication is enabled, mark the fixture blocked; never collect or
  route its secret through the test script or this document.

### Provider Mode Semantics For Security Review

WTA does not independently configure provider sandboxes. It does invoke each advertised
mode as one provider-defined contract, which for Codex and Gemini can include sandbox,
path, or network effects. This table records those effects for review.

| Provider | Effective/default sandbox observed | Native-mode interaction | Escape concern / required negative test |
|---|---|---|---|
| Copilot `1.0.80` | Experimental MXC command sandbox is disabled by default; organization/user settings may enable it | `allow_all` controls tool/path/URL permissions; no evidence that it changes sandbox configuration | With sandbox enabled, test `allowBypass=false` and `true`; prove native `allow_all` cannot silently defeat an enforced no-bypass policy |
| Claude adapter `0.65.0` / SDK `0.3.220` | Adapter does not force sandbox on or off; effective sandbox is inherited from Claude user/managed settings | `bypassPermissions` changes `permissionMode`, not sandbox settings | Remaining callbacks can carry `sandboxOverride`, `safetyCheck`, or `workingDir`; explicit `permissions.ask` is preserved, but test that managed deny/no-unsandbox policy cannot be auto-approved |
| Codex adapter `1.1.13` | Default `agent` preset uses `workspaceWrite` with network off; `read-only` is stricter | `agent-full-access` bundles `approvalPolicy=never` with `dangerFullAccess` | Mapped as the provider's complete advertised contract; test outside-workspace write, network and exact restore behavior. |
| Gemini `0.51.0` | WTA does not pass `--sandbox`; user/admin settings may still enable Gemini sandbox | `yolo` changes approval policy and may refresh provider-managed sandbox settings | Mapped as the provider's complete advertised contract; test trust/admin gates, network/write scope and exact restore behavior. |
| OpenCode `1.18.3` | No separate provider sandbox was identified in the audited ACP path | ACP `mode` selects an agent persona, not permission policy | No reviewed native Yolo capability; remains interactive with no WTA fallback. |

Sandbox investigation TODOs:

- Capture effective sandbox state from the exact packaged provider process; do not infer it
  only from WTA launch arguments.
- For every native mapping, capture the provider-defined permission/sandbox/access state
  before enable, while enabled, and after restoring the exact prior mode.
- Exercise sandbox-escape permission requests with provider sandbox enabled and require
  managed deny/no-bypass policy to remain authoritative.
- Keep these tests separate from permission-UI tests so a GREEN interaction test cannot
  hide a provider mode regression.

## Ownership Hypothesis

```text
settings.json / Settings UI / AllowYoloMode / /yolo
  -> GlobalAppSettings + TerminalPage agent_config_changed/helper args
  -> helper YoloState + App pending transaction
  -> native_yolo provider contract + sequenced ACP session mutation
  -> permission card/status/native provider behavior/restart evidence
```

- Settings/policy owner: `GlobalAppSettings::EffectiveAgentPaneYoloMode()` and
  `AgentPolicy::Snapshot`.
- Host propagation owner: `TerminalPage` helper arguments and
  `agent_config_changed` payload.
- Runtime state owner: `tools/wta/src/app_contracts/yolo.rs::YoloState`.
- Slash transaction owner: `App::cmd_yolo`, `App::apply_runtime_yolo_config`, and
  `App::complete_yolo_change`.
- Native provider owner: `protocol/acp/native_yolo.rs` for provider contracts,
  per-session restore values, sequencing/generation and RPC execution.
- Permission owner: `WtaClient::request_permission`; all valid choices come from the UI
  responder, never from Yolo state.
- Cross-process identity/routing owner: `master::session_to_helper` and
  master-attested `resolved_agent_id`.

| Hypothesis | Cheapest discriminating check |
|---|---|
| A runtime setting/GPO update can race an in-flight `/yolo` acknowledgement and leave local effective state different from provider state. | Covered: pending ACK cancellation plus receive-order operation tokens/latest-desired supersession. |
| `session/new` native enable can finish after a runtime disable that saw no attached session, leaving native mode on. | Covered: client only discovers; `SessionAttached` is the sole apply owner and uses latest state. |
| `drop_tab_session` and `reset_tab_session_for` leak override/pending/native entries. | Covered: App cleanup plus native generation fencing tests. |
| A supported provider omits its contract. | New session off is safe no-op; enable errors; loaded on/off remains fail-closed because prior native state is unknown. |
| Injecting `resolved_agent_id` after cloud catalog metadata replaces `_meta.wta` and drops the model catalog. | Build an initialize response with a ready cloud catalog, add identity/proposal metadata, and assert all fields survive one merged namespace. |

Do not start product edits until the selected hypothesis has a deterministic RED test and
the exact pre-fix failure has been recorded.

## Commit And Worktree Discipline

- `C:\ado\intelligent-terminal-bugfix` is the dev worktree. Its `AGENTS.md` and
  `local-tdd-kit/` changes remain dev-only and currently uncommitted.
- `C:\ado\intelligent-terminal-yolo-publish` is the clean publish worktree on the
  exact PR source branch. Do not develop or collect raw evidence there.
- Product code, durable unit/E2E tests, policy templates, localized product resources
  and product documentation form self-contained publishable commits on dev.
- Dev-only tracking/framework/evidence form separate commits only when explicitly
  requested. Never create a mixed commit and later restore files out of it.
- Main is merged on dev. Before publishing, update the clean publish branch to the same
  main ancestry and cherry-pick only publishable product commits.
- Kai confirmed `origin/dev/vanzue/yolo-mode` as the publish target and authorized direct
  pushes for security review. Do not push until exact publish validation succeeds; never
  rewrite inherited history.
- Never force-add ignored evidence. Copy only selected, sanitized review artifacts to
  a deliberately chosen tracked directory.

## Test Reuse And Framework Boundaries

- Reuse `tools/wta/src/slash_command_tests.rs`,
  `tools/wta/src/protocol/acp/mock_agent_tests.rs`,
  `tools/wta/src/protocol/acp/native_yolo.rs`, and
  `src/cascadia/UnitTests_SettingsModel/CustomAgentAndPolicyTests.cpp` first.
- Extend the existing mock ACP transport with controllable RPC barriers for race tests;
  do not add sleeps or a test-only product route.
- Put publishable packaged coverage in the existing `test/e2e` ItE2E framework. A
  planned `Feature.YoloMode.Tests.ps1` must prove the actual Settings/slash/policy path,
  not merely inspect a Rust map.
- Use `local-tdd-kit/` only for local orchestration, receipts, fixtures and raw evidence.
  It is not part of the PR.
- Deterministic mocks prove ordering and failure handling. They do not replace final
  live Copilot ACP validation or Hamza's design/security review.
- Maestro-backed Claude acceptance is an allowed dev-only live check, not a deterministic
  replacement for mock ACP RED/GREEN tests and not a publishable test dependency.

## Reproduction And RED Oracle

### Baseline Identity

- Source commit: `3adc45bc69941cad108ca9799df78a1d42c95de8` in the clean publish worktree.
- Baseline WTA command:
  `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml yolo`
- Full WTA command:
  `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml`
- Settings test command after the test host is built:
  `cmd /c "tools\razzle.cmd && runut SettingsModel.Unit.Tests.dll /name:*CustomAgentAndPolicyTests*"`
- Build/deploy command: `pwsh -File local-tdd-kit/Invoke-BuildDeploy.ps1`
- Package selector: Dev / `IntelligentTerminal_rd9vj3e6a2mbr`.
- Relevant binaries: explicit-target `tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe`,
  staged/installed `wta.exe`, `WindowsTerminal.exe`, `wtcli.exe`, protocol WinMD and
  `resources.pri` as recorded by the build receipt.
- Source/deployed hashes: not captured yet. Do not infer freshness from an old package.

### Reproduction

1. 在 clean publish worktree build/deploy exact `3adc45bc`，记录 receipt、package path、
  binary size/SHA-256 和 live process paths。
2. 先运行已有 Yolo tests，证明 takeover 前 baseline 没有环境性失败。
3. 分别新增最小 race/lifecycle/native-state test，并要求在对应 oracle 上 RED：
  - delayed slash ACK plus runtime update leaves last native write unequal to effective state;
  - delayed session-start native on plus runtime/policy off has no compensating off/restart;
  - tab reset/close leaves override or pending state that activates on reused session ID;
  - WTA auto-selects provider/proposal/session-MCP `AllowOnce` without user input;
  - initialize identity injection drops existing cloud catalog metadata.
4. 对可部署性建立静态 RED：ADMX/ADML 缺少 `AllowYoloMode`；15 个非 en-US
  SettingsEditor resource sets 缺少两个 `AIAgents_YoloMode` keys。
5. 从 Settings UI 和 agent-pane slash command 走真实入口；不要直接修改内部 map 冒充 E2E。
6. 若 exact baseline 没有在预期 oracle 上失败，停止该 fix，记录被证伪的 hypothesis。

Unit-level RED/GREEN evidence above is captured. Exact packaged baseline/live provider
evidence remains outstanding.

## Strict TDD Workflow

1. 在 publish baseline 运行已有 focused tests、build/deploy 和 smoke flow。
2. Dev 已合入 `origin/main@73cf3510d` 并完成 focused post-merge revalidation。
3. Deterministic RED 已覆盖 metadata、permission auto-selection、teardown cleanup、
  runtime/slash race、attach race、operation supersession 与 generation fencing。
4. 在最近 owner 做最小实现；首次 substantive edit 后立即重跑同一个 test filter。
5. focused GREEN 后运行全部 Yolo tests、全 WTA suite、SettingsModel tests 和相关
  TerminalApp tests。
6. ADMX/ADML 与 SettingsEditor locale parity 已补齐并通过 XML/BOM/EOL/reference validation。
7. 在现有 `test/e2e` 添加 durable packaged case；local TDD kit 只负责 orchestration
  和 evidence capture。
8. build WTA explicit target，再 build/deploy CascadiaPackage；运行 freshness verifier。
9. 使用 mock/fixture 验证 provider-independent paths；用真实 Copilot、Claude、Codex、
  Gemini验证广告能力、enable/restore与实际权限/sandbox/access效果；OpenCode保持交互。
10. 从 exact publish HEAD 重建/部署，重跑 E2E、provider matrix 和 fresh screenshots。
11. publish worktree 只接收 main merge与自包含 product commits，不接收本文件或
  `local-tdd-kit/`。

## Implementation Snapshot

- Persistent setting: `agentPane.yoloMode`, default `false`, with a policy-aware
  effective accessor and Settings UI toggle.
- Host propagation: helper startup flags plus hot `agent_config_changed` updates.
- State model: global default + policy block + `HashMap<session_id, bool>` explicit
  overrides + pending slash-command transactions.
- Native path: master-attested provider identity plus exact per-provider contracts in
  `protocol/acp/native_yolo.rs`. Copilot/Claude/Codex use advertised config options when
  present; Claude/Codex may use legacy modes as fallback; Gemini uses `session/set_mode`.
- Permission path: every valid ACP permission request uses the interactive UI. WTA never
  auto-selects a permission option. Invalid/stale product-owned proposals remain cancelled.
- Policy failure handling: runtime block clears local overrides and requests an agent
  stack restart if native disable reconciliation fails.
- Takeover slice 1 (`8b24342c`): `initialize_response_for_agent` composes cloud catalog,
  resolved identity and proposal capability into one `WtaMeta`, then injects the namespace
  once. The adjacent regression test proves all three survive in the same response.
- Takeover slice 2 was superseded by the product decision. The generic permission-selection
  module was removed and replaced by provider-native discovery, restore values, operation
  sequencing and lifecycle generations in `native_yolo.rs`.
- Main is merged through `73cf3510d`; the provider-native slice builds on incoming physical
  session close, fail-closed crash recovery, live model switching and repository formatting.

### Existing Coverage

- `app_contracts/yolo.rs`: override precedence and policy-block clearing.
- `slash_command_tests.rs`: on/off/bare command, delayed commit, failure retention,
  global override, runtime update, session replacement, and completion candidates.
- `protocol/acp/mock_agent_tests.rs` and `client.rs`: global/session Yolo state never
  auto-answers provider, proposal or user-input permission requests.
- `protocol/acp/native_yolo.rs`: exact four-provider discovery, OpenCode/custom rejection,
  config/mode RPC routing, restore values, session isolation, operation supersession,
  serialization and teardown generation fencing.
- `app_tests.rs` / `slash_command_tests.rs`: tab close/reset cleanup, runtime/slash race,
  attach compensation, delayed commit and policy fail-closed behavior.
- `CustomAgentAndPolicyTests.cpp`: JSON default/round-trip, effective policy block,
  and policy-lock state.

### Missing Coverage

- Fail-closed restart observed through the actual dispatch/reconnect boundary.
- Packaged Settings/slash/policy E2E and live provider acceptance.
- User-visible unsupported-provider status for a globally enabled setting (Settings warning
  currently explains that unsupported providers continue prompting).
- Reviewed translations for the revised WTA `/yolo` summary outside en-US/pseudo locales.

## Validation Matrix

| Layer | Command / Method | Expected | Result | Evidence |
|---|---|---|---|---|
| Dev kit prerequisites | `pwsh -File local-tdd-kit/bootstrap.ps1 -Check` | Required local tools available | PASS (`pwsh 7.6.5`, Pester `6.1.0`) | Console result, `2026-08-24` |
| Dev kit Unit selftests | `Invoke-Pester local-tdd-kit/selftests/ItE2E.Unit.Tests.ps1 -Tag Unit` | All pass | PASS `16/16` | Console result, `2026-08-24` |
| Dev kit Input selftests | `Invoke-Pester local-tdd-kit/selftests/ItE2E.Input.Tests.ps1 -Tag Input` | All pass on unlocked interactive desktop | BLOCKED: `1/4` passed; 3 could not acquire foreground HWND, and no input was sent | Console result, `2026-08-24` |
| Existing focused WTA | `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml yolo` | Existing Yolo tests pass | PASS `13/13` on clean publish baseline `3adc45bc` | Console result, `2026-08-25` |
| Cloud metadata RED | `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml initialize_response_preserves_ready_cloud_catalog_with_identity_and_proposal_meta` | Ready catalog is lost before the fix | RED as expected: actual `0`, expected `1` | Console result, `2026-08-25` |
| Cloud metadata GREEN | Same focused test | Catalog, identity and proposal metadata all survive | PASS `1/1` | Console result, `2026-08-25` |
| Neighboring metadata/Yolo | Same command with filters `cloud_catalog`, then `yolo` | No regression | PASS `3/3`; PASS `13/13` | Console result, `2026-08-25` |
| No permission auto-selection RED/GREEN | Filter `request_permission_yolo_still_prompts_for_provider_permission`, then `permission_requires_user_selection` | Provider, proposal and user-input permission requests require user choice | RED: no `PermissionRequest`; GREEN `3/3` special paths plus `3/3` Yolo paths | Console result, `2026-08-25` |
| Native provider coordinator | Filter `native_yolo::tests` | Four reviewed contracts, restore/isolation, sequencing and generation fencing | PASS `12/12` | Console result, `2026-08-25` |
| Lifecycle/race RED/GREEN | Filters `drops_yolo_override_and_pending_change`, `runtime_change_cancels_stale_pending_yolo_ack`, `session_attach_reconciles_latest_yolo_state` | No stale override/pending/native write survives lifecycle changes | RED at each intended oracle; GREEN `2/2`, `1/1`, `1/1` | Console result, `2026-08-25` |
| Current Yolo suite | `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml yolo` | All provider-native and state tests pass | PASS `25/25` | Console result, `2026-08-26` |
| Current permission suite | Same command with filter `permission` | All provider, proposal and user-input requests require explicit selection | PASS `47/47` | Console result, `2026-08-26` |
| Full WTA | Fresh `bin/x64/Debug/wtcli` first on PATH; `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml` | All product tests pass | PASS `1723/1723` | Console result, `2026-08-26` |
| Settings model | Explicit local TAEF runner on `SettingsModel.Unit.Tests.dll /name:*CustomAgentAndPolicyTests*` | All Yolo/policy cases pass | PASS `37/37` | Console result, `2026-08-25` |
| TerminalApp agent registry | Explicit local TAEF runner on `Terminal.App.Unit.Tests.dll /name:*AcpModelUtilsTests*` | Gemini and provider command mapping pass | PASS `13/13` | Console result, `2026-08-25` |
| Policy/resources | Parse ADMX/ADML XML and assert `AllowYoloMode`; assert both Settings keys in every locale | Exact key parity | PASS: policy references/values valid; XML/BOM/EOL/key parity PASS `16/16` | Console result, `2026-08-25` |
| Explicit build/deploy | `pwsh -File local-tdd-kit/Invoke-BuildDeploy.ps1` | Build/deploy receipt succeeds | Not run | None |
| Freshness | `pwsh -File local-tdd-kit/Verify-DeploymentFreshness.ps1` | Source, staged, installed and live identities match | Not run | None |
| Packaged E2E | `$env:ITE2E_PACKAGE='Dev'; pwsh -File test/e2e/Invoke-ItE2EReport.ps1 -Path test/e2e/tests/Feature.YoloMode.Tests.ps1` | Settings/slash/policy flows pass | Suite not authored | None |
| Static checks | `cargo fmt --check`; `git -c core.whitespace=cr-at-eol diff --check`; repository diagnostics on touched files | Clean | PASS | Console/editor result, `2026-08-25` |
| Maestro Claude API | Direct Anthropic request + isolated `claude -p` | VS Code LM answers without a Claude account | PASS, exact markers returned | Console result, `2026-08-25` |
| Maestro Claude ACP | `local-tdd-kit/Invoke-MaestroClaudeAcpProbe.ps1` / equivalent isolated production probe | Pinned adapter completes initialize + session/new without touching user config | PASS; 6 models, current `gpt-5.6-luna[1m]`, user config unchanged | Console result, `2026-08-25` |
| Real provider | Exact publish package with Copilot, Claude, Codex and Gemini native paths; OpenCode interactive | User workflow and wire/log oracle pass | Not run | None |

### Exact Publish Identity

- Current local and remote publish branch HEAD:
  `0e8be3a9815a3fba8339f045ecb9eeae8e321fcb`.
- The exact `7c8a682` Debug package staging build and recipe freshness checks passed;
  receipt: `local-tdd-kit/artifacts/yolo-mode/publish-build-receipt.json`.
- It was deliberately not deployed because another worktree owns the active Dev package.
- Identity conclusion: `7c8a682` source/staging is verified, install/live is unverified,
  and current publish HEAD `0e8be3a9` requires a fresh build receipt.

Test source may come from a dev-only harness, but the tested application must come from
the exact publish HEAD. Always set `ITE2E_PACKAGE=Dev`; `Auto` is not acceptable evidence.

## Real Integration Acceptance

- Required provider A: installed and authenticated Copilot CLI. Current observed CLI
  version is `1.0.80`; record the actual version again at test time.
- Required providers B-D: Claude, Codex and Gemini exercising their reviewed native ACP
  modes. OpenCode remains the unsupported negative case and must continue prompting.
- Development fixture: Maestro supplies a VS Code LM backend to the real Claude CLI and
  pinned ACP adapter without a Claude account. It supports live adapter acceptance but is
  not deterministic RED/GREEN evidence and is not part of the publish branch.
- Final provider acceptance intentionally consumes model quota comparable to a bounded normal
  user workflow. A catalog/initialize/session-new probe is prerequisite evidence only and does
  not complete the provider row. Record which backend paid for inference: vendor account for
  Copilot/Gemini/OpenCode, VS Code LM through Maestro for Claude/Codex.
- Workflow: launch the exact Dev package; select the provider through normal product
  settings; create two sessions; verify default off, global on, per-session opt-out,
  `/new`, tab close/reset, runtime setting change and policy block; then run a bounded safe
  read/write/execute task in a disposable directory and verify the real model response and
  provider-native mode behavior. Capture ACP/native operations and product-owned status
  without recording secrets or unrelated prompt content.
- Native oracle: each supported provider advertises the exact reviewed capability; WTA
  targets the exact session, restores the captured value, and does not change siblings.
- Permission oracle: provider, proposal-MCP and user-input-MCP requests remain pending
  until an explicit user selection, including `AllowOnce` and `AllowAlways`-only offers.
- Terminal-action oracle: a valid `request_terminal_actions` proposal still renders a
  card and does not mutate the target pane until the user chooses Run/Insert.
- Direct-COM caveat: separately demonstrate/document that the above card is a workflow
  property, not a security boundary against arbitrary same-user Agent commands.
- Status: not run. If authentication or provider availability blocks the matrix, mark it
  blocked rather than complete or skipped.

## Visual Evidence

Required fresh screenshots from the exact publish package:

- Settings toggle off, on, and disabled by policy, including complete warning text.
- `/yolo on`, `/yolo off`, and native failure message in the owning tab.
- Two-tab isolation showing one session opted in and the other opted out.
- Normal permission card while Yolo is enabled and whenever a provider requests permission.
- Terminal action recommendation card still awaiting user action while Yolo is on.
- Non-English and pseudo-locale Settings views after locale parity is added.

Every capture must record publish commit, package path, source/deployed hashes, HWND,
dimensions and capture command. Inspect each image for correct target window, nonblank
content, clipping/overlap and stale package UI. Latest evidence directory: none yet.

## Review Triage

Current review status: takeover triage completed against public review/comment data
through `2026-08-19` and source at `3adc45bc`. No new review was requested. REST data
does not expose authoritative thread-resolution state, so "open" below means the current
code still exhibits the finding or lacks the requested coverage.

### Open P0

1. **Cloud model metadata regression**
  ([review](https://github.com/microsoft/intelligent-terminal/pull/505#discussion_r3765534766)).
  `initialize_response_for_agent` injects cloud catalog metadata and then calls
  `inject_wta_meta` again for identity/proposal fields. The helper replaces the entire
  `_meta.wta` object, so a ready catalog can be dropped. **Dev status:** deterministic
  RED captured and focused/full WTA GREEN after a single-injection fix; committed as
  `8b24342c`, not yet copied to publish.
2. **Fallback-only Copilot cannot reliably turn off**
  ([review](https://github.com/microsoft/intelligent-terminal/pull/505#discussion_r3773626475)).
  `copilot_requires_native_disable()` represents agent identity, not whether native on
  was applied to this session. A Copilot session with no verified selector can turn on
  through fallback, then `/yolo off` errors. Track per-session native state or otherwise
  distinguish fallback-only sessions. **Superseded:** generic fallback was removed. A new
  session without a capability can safely remain off; loaded sessions still fail closed.
3. **Session creation versus runtime disable race**
  ([review](https://github.com/microsoft/intelligent-terminal/pull/505#discussion_r3780443288)).
  `maybe_apply_native_allow_all` checks effective state before an awaited enable and
  emits `SessionAttached` afterward. A disable in that window can miss the session.
  **Dev status:** client startup writes were removed; `SessionAttached` is the sole apply
  owner and reconciles the latest effective state.
4. **Runtime reconcile versus in-flight slash command race.** Reconciliation derives a
  target from committed state while `pending_yolo_changes` is separate; reordered native
  writes and the later slash ACK can leave local and provider state different.
  **Dev status:** runtime changes cancel pending ACK bookkeeping; receive-order operation
  tokens, per-session async gates and latest-desired supersession make the final RPC match
  the latest state.
5. **Incomplete teardown cleanup**
  ([review](https://github.com/microsoft/intelligent-terminal/pull/505#discussion_r3811389274)).
  `drop_tab_session` and `reset_tab_session_for` clear routing/model state but not the
  Yolo override or pending transaction. Incoming main closes the physical ACP session;
  it does not know about or clear PR-specific Yolo state. **Dev status:** both paths now
  clear App state and ACP capability generations fence late responses/reused IDs.
6. **Undeployable policy surface.** Runtime reads `AllowYoloMode`, but
  `policies/IntelligentTerminal.admx` and `policies/en-US/IntelligentTerminal.adml`
  expose no such policy. **Dev status:** ADMX/ADML added and XML/reference/value validation
  passes.
7. **Security review required.** Product decided there is no fallback: WTA is an ACP UI for
  reviewed provider-native modes. Settings/spec copy identifies provider-defined permission,
  sandbox, file and network effects. Direct-COM residual risk still requires security review.

### Open P1

1. Settings Editor Yolo resources now have parity across all 16 current locale/pseudo-locale
  sets with XML/BOM/EOL validation. Native-language review remains desirable.
2. Provider support was re-audited and implemented for Claude/Codex/Gemini; Gemini now uses
  `--acp`. Exact packaged live acceptance remains outstanding.
3. The 20 incoming `main` commits are merged through `73cf3510d`. Particular overlap:
  physical session close (#637), crash fail-closed (#649), helper cleanup (#647), hot
  agent/model switching (#655), detected Claude/Codex executables (#644), and cargo fmt
  (#658). Focused lifecycle/model/Yolo tests pass after manual semantic merge.
4. The duplicated `and` and obsolete fallback sections were removed from the spec.
5. Decide the `/yolo`-before-session UX instead of leaving a silent race by accident.

### Previously Addressed On The PR

- Removed dead auto-approved chat notification plumbing after confirming silent ordinary
  auto-approval was the product decision.
- Tightened Copilot native discovery to exact ID/category/Select/on+off and master-attested
  canonical identity.
- Changed generic fallback from persistent `AllowAlways` to reversible `AllowOnce` only.
- Added `/yolo on|off`, explicit status, pending acknowledgement and failed-disable state
  retention.
- Added load-session selector rediscovery and session-replacement cleanup.

Every accepted follow-up must append its RED evidence, fix commit, GREEN command/result,
and publish commit here. Public PR data may be read unauthenticated; do not invoke account
authentication tooling or request credentials for review triage.

## Local-Only Evidence Inventory

Evidence root: `local-tdd-kit/artifacts/yolo-mode/` (planned, ignored).

| Artifact | Path | Proves | Commit/package identity |
|---|---|---|---|
| Branch/worktree audit | This handoff | Dev/publish refs and clean publish isolation | `3adc45bc` |
| Public review/source audit | This handoff | Open and previously addressed findings | `3adc45bc` |
| Provider static capability audit | This handoff | Current mode contracts and adapter version drift | `2026-08-24`; no package tested |
| Maestro Claude API/CLI smoke | Console result | Anthropic proxy and real Claude CLI work without Claude account | `2026-08-25`; dev-only, isolated home |
| Maestro pinned-adapter ACP probe | Console result | Production WTA reached initialize + session/new through `claude-agent-acp@0.65.0` | `2026-08-25`; dev-only, no publish package |
| Dev kit prerequisite/unit checks | Console result | Bootstrap and hermetic framework core are usable | `2026-08-24`; no product package |
| Dev kit input blocker | Console result | Safety guard refused input without a foreground HWND | `2026-08-24`; `1/4` passed, 3 blocked |
| Publish staging receipt | `local-tdd-kit/artifacts/yolo-mode/publish-build-receipt.json` | `7c8a682` source/recipe/staged identity; no install | `7c8a682`; superseded by current uncommitted delta |
| RED unit reports | Not captured | Each race/lifecycle failure | Unverified |
| Packaged E2E report | Not captured | Real Settings/slash/policy workflow | Unverified |
| GREEN screenshots | Not captured | Reviewable UI states | Unverified |
| Real provider wire/log evidence | Not captured | Provider-native behavior and interactive permissions | Unverified |

Temporary npm package extractions and the OpenCode source clone used for static inspection
were removed. Future ignored screenshots, logs, reports, provider homes and wire captures
must be inventoried here without credentials, tokens, account IDs, prompt text or unrelated
terminal content.

## Completion Checklist

- [x] Dev and publish branches/worktrees are isolated at the takeover baseline.
- [x] PR/current-main identities and semantic-overlap risks are recorded.
- [x] Current implementation, public review findings and provider capability surfaces are audited.
- [x] Dev-only bootstrap and hermetic Unit selftests pass; foreground Input suite blocker is recorded.
- [x] Exact baseline existing Yolo tests pass (`13/13` at `3adc45bc`).
- [x] First cloud-metadata regression completed RED -> focused GREEN -> full WTA GREEN.
- [x] Provider-native-only permission, capability, lifecycle and race slices completed RED -> GREEN.
- [ ] Exact baseline 已 build/deploy，并在预期 behavioral oracle 上 RED。
- [x] Focused regression 先 RED 后 GREEN。
- [x] Neighboring tests、full relevant suite、focused C++ builds/tests 和 static analysis 已完成。
- [x] Current `origin/main@73cf3510d` is merged and focused post-merge behavior is revalidated.
- [x] GPO templates and SettingsEditor locale parity are complete and structurally validated.
- [ ] Hamza/design/security decisions are recorded for terminology, provider-native scope and command-approval messaging.
- [x] Publishable and dev-only changes remain separated; `AGENTS.md`/`local-tdd-kit` stay dev-only.
- [ ] Exact publish HEAD 已 build/deploy，source/deployed hashes 一致。
- [ ] Packaged/deployed E2E 对 exact publish binary GREEN。
- [ ] 真实外部依赖验收已完成，或明确标记 blocked。
- [ ] UI/渲染/交互的 fresh screenshots 已逐图检查并记录 provenance。
- [ ] Review findings 已逐条 triage，accepted fixes 有 RED/GREEN evidence。
- [ ] Evidence inventory 能映射全部 user-visible assertions。
- [x] Dev 与 publish remote heads 已 push 并确认 (`0e8be3a9`)。

## Optional Follow-Ups

- Design and implement trusted/allowed working directories as a separate feature.
- Design a provider-independent read/search allowlist with unknown-tool fail-closed behavior.
- Reconcile Yolo naming and UX with the future available-commands `/command` feature.
- Consider a separate provider-native permission-mode PR after contracts, restore semantics
  and sandbox differences are reviewed.
- Address the broader COM authorization and runtime confirmation roadmap in
  `doc/security-model.md`; do not silently broaden PR #505 to solve it.


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
- **Session MCP** exposes `request_terminal_actions` and `request_user_input`.
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
