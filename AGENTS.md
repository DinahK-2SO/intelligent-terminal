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
- Latest audited `origin/main`: `0c2062bc5837b2ae335f86a00d068828d76af2d5`
- Common ancestor: `e870a3630a785a44cbd22190b5c8808c7084b31f`
- Dev branch/worktree: `dev/dinah/yolo-mode` / `C:\ado\intelligent-terminal-bugfix`
- Dev branch's latest publish-equivalent head is `cab16e161af53daeb4b79230e10d3970166fef59`;
  its latest product-bearing Yolo UX commit is `cab16e161af53daeb4b79230e10d3970166fef59`;
  its latest security-review commit before that is `170d7c6c1bb813c7c6bf86d1359eea856855f268`;
  earlier review/product commits include `3ad490bd9`, `6f128ac0d`, `5f8e3ca12`,
  `5515aee43`, `60a60e2b8` and `95c92565f`;
  keep dev-only orchestration and evidence local and unpushed.
- Publish branch/worktree: `dev/vanzue/yolo-mode` /
  `C:\ado\intelligent-terminal-yolo-publish`
- Publish remote: `origin/dev/vanzue/yolo-mode`; local, remote-tracking and `ls-remote`
  are all at `2f99d2440df96bf597bfed912c039cd2decb7913`. Original branch author Kai (`vanzue`)
  approved using this as the publish branch and directly pushing validated publishable
  commits for the security review process on `2026-08-25`.
- Evidence root: `local-tdd-kit/artifacts/yolo-mode/` (ignored).
- Review evidence directory: to be chosen only for sanitized artifacts intended for review.
- Current publish candidate adds review remediation `e3cec54da`, packaged-E2E observability
  `67367b914`, bootstrap-session reconciliation `c28528a0c`, and post-push review fixes
  `9567d42ad` after the prior main merge, provider-native, permission-contract, locale,
  packaged-E2E and quota-boundary commits, bounded native RPCs in `61200332f`, and latest
  integrated `origin/main` through merge `d99a0e787`. Later review rounds are
  `c99714ec1`, test-fixture correction `8b9d63a40`, and pending-slash gating `c96b1d66d`.
- Out of scope for PR #505: trusted/allowed working directories, a read/search-only
  ToolKind allowlist, per-application/executable policy, provider negotiations, and the
  future available-commands `/command` integration.

## Current Stage

`2026-09-01`: post-convergence UX follow-up is implemented and published from dev
`cab16e161` as publish `2f99d2440`, based on audited `origin/main@0c2062bc5`. The product keeps
`agentPane.yoloMode` as a provider-independent global preference, but exposes the actual current
session state so an enabled preference cannot imply that OpenCode/custom entered Yolo or that
Gemini accepted its provider-owned mode. A fixed agent-header marker now shows localized
pending-on/off, active, off, unavailable and unknown states plus the existing inline `/yolo`
status/error; provider failures expose their detail through tooltip and UI Automation;
known automatic enable rejection must remain interactive, every ACP permission remains explicit,
and disable/unknown outcomes remain fail-closed. Provider switch must clear old UI state before the
new session reports its own result. Deterministic RED first failed because `TabSession` had no
`yolo_status`/`YoloUiStatus`; tests now cover success, known rejection, unknown outcome, lazy first
prompt, generic config supersession, `/new`, reset and provider replacement. Review findings for
stuck pending config, sessions-view visibility, screen-reader semantics, long-label overlap and C++
routing are fixed; independent convergence review found no remaining blocker. Dev focused Yolo
passes `79/79`, permission `48/48`, full source-matched WTA `1938/0/1`, ItE2E selftests `22/22`,
and TerminalApp/LocalTests builds have `0` errors. The focused local TAEF test is environment-blocked
at the shared `TerminalPage` initialization (`0x8000ffff`); the unchanged `TryInitializePage` fails
at the same pre-body line. Dev/publish stable patch IDs match. Exact publish `2f99d2440` is built,
deployed and freshness-verified `18/18`; source fingerprint is
`296A19167ADDDA2DCB15CD31F9C525DEDB43B67D3AF48F70B38DC034896AF643` and WTA SHA-256 is
`C8F65A580084FCF08915506F68616483C45155743F1622F70830AAD18B4E905A`. Publish full WTA passes
`1938/0/1`; zero-token packaged Yolo passes `4/0/1`, skipping only unprovisioned C292. It proves
the acknowledged Copilot header and automatic OpenCode unavailable state while retaining the global
toggle; no model/provider prompt ran. Cleanup leaves no package processes or backup markers. The
guarded ordinary push advanced the publish remote from `292247601` to `2f99d2440`; local,
remote-tracking and `ls-remote` match. Next action: await and triage the automatic Copilot review,
then collect fresh review screenshots if required.

`2026-09-01`: latest `origin/main@0c2062bc5` (#683 intent-based Session MCP redesign) is
merged and pushed to publish as `c9d353000`. Conflicts in `test/e2e/README.md`, `client.rs`, and
the CRLF/LF-conflicted `mock_agent_tests.rs` preserve main's 16-hex dynamic Session MCP names,
intent tools and display/trust rules together with Yolo's explicit permission UI and fail-closed
state. Post-push WTA exposed one incoming test that waited for an automatic permission selection;
`5665c4e45` makes the test choose `allow-once` explicitly. Full WTA passes `1935/0/1`, focused
Yolo `76/76`, permission `48/48`, and Session MCP trust/permission tests pass. Exact product head
`5665c4e45` is built, deployed and freshness-verified with `0` build errors. Package validation
then exposed only E2E oracle/orchestration defects: compact tool output renders `exit 7`, localized
button values include an Enter glyph, and the two-tab routing test confused numeric protocol tab
indices with stable tab GUIDs. Test-only publish commits `c31621817` and `292247601` normalize the
glyph, assert compact output, and select run-local panes by creation/exclusion. Framework selftests
pass `22/22`; affected AgentProtocol/ProposalRouting/Yolo package suites pass `13/0/1`, skipping
only unprovisioned C292. Dev contains the equivalent merge `3694a89b9` and correction commits
`bb03eeea2`, `3ee274b49`, `8ece09638`; product/test trees match publish outside dev-only files.
No model/provider prompt ran. Next action: verify cleanup/current-head checks and triage the
automatic Copilot review triggered by the merge/corrections. Cleanup found no package processes
or backup markers, and local/tracking/remote publish refs match at `292247601`. Automatic Copilot
review `5073794997` reviewed `178/178` files at that exact head and generated no new comments.
The post-merge automated review loop is converged; remaining work is human-owned design/security
signoff, optional complete PR-body metadata, and fresh UI review screenshots.

`2026-09-01`: automatic Copilot review `5070639693` of exact publish head `acdb9f09f`
reviewed `176/176` files and generated no new comments. This closes the automated review loop for
the current head: the latest public PR head, local publish branch, remote-tracking ref and
`ls-remote` all match; exact package build/deploy/freshness, zero-token E2E, full WTA, focused
Yolo/permission suites and independent convergence review are GREEN as recorded below. Remaining
work is human-owned design/security signoff, complete PR-body metadata if desired, and fresh UI
review screenshots; no further product edit is justified by the current Copilot review.

`2026-09-01`: Copilot review `5069907058` of publish `2b9e5b1a7` found one visible and one
suppressed instance of the same valid fail-closed gap: ordinary ACP rejection of a native disable
could release prompt gates without proving the provider left privileged mode. Deterministic REDs
covered slash, generic `/config`, batch reconciliation, lazy first-prompt reconciliation and the
App-side reset window. The seven-path dev follow-up now marks every failed disable restart-required,
propagates typed restart state with config failures, retains tracked and synthetic reconciliation
gates until agent reset, and preserves known-enable best effort plus ordinary config behavior.
Focused Yolo passes `76/76`, permission `48/48`, and full WTA `1917/0/1`; rustfmt/diff checks and
independent convergence review pass. Dev `170d7c6c1` was cherry-picked to publish as `acdb9f09f`;
stable patch IDs match with only pre-existing CRLF/LF normalization in the mock fixture, and publish
full WTA also passes `1917/0/1`. Exact `acdb9f09f` is built, deployed and freshness-verified
`18/18`; source fingerprint is
`FD1AC5B94421463CFACF10572CB0D5910C216C9BBDAD8359803B939D6B869322` and WTA SHA-256 is
`017E1F90BED58324E1E5C918051F52AC370F0EABF98068C3D37C58750659D51C`. Zero-token package E2E
passes `4/0/1`, skipping only unprovisioned C292; cleanup leaves no package processes or backup
markers. No provider/model prompt ran. Next action: guarded push, then await the next automatic
Copilot review. The guarded push advanced the publish remote from `2b9e5b1a7` to `acdb9f09f`;
local, remote-tracking and `ls-remote` match.

`2026-09-01`: all three findings from review `5068959587` completed deterministic
RED-to-GREEN remediation in dev `627041b29`. Current helper Connected sync lacked both Yolo
fields; current `/config` pending state allowed a normal prompt; and fresh privileged-only
Copilot/Gemini capability shapes disabled as a no-op. The fix resends tab-scoped current
default/policy on Connected, carries master-attested native-config metadata into App prompt gates,
serializes and bounds both privileged and nonprivileged native-mode selections, cleans gates on
failure/replacement/reset, and represents unrestorable privileged state explicitly with a
restart-required fail-closed result. Ordinary model/config changes remain ungated and every ACP
permission remains explicit. Focused Yolo passes `72/72`, permission `48/48`, full WTA
`1912/0/1`, and latest TestHost build/focused helper payload test pass with `0` errors and `1/1`.
Independent final review found no actionable blocker. The self-contained commit was cherry-picked
to publish as `2b9e5b1a7`; stable patch IDs match, with only pre-existing CRLF/LF normalization in
one mock fixture. Publish full WTA also passes `1912/0/1`. Exact `2b9e5b1a7` is built, deployed and
freshness-verified `18/18`; source fingerprint is
`EF65C9B275197A3C13C8A06A94B6522EC596748C13C9BFE6E47348CE38CEA291` and WTA SHA-256 is
`5300033283F8662B0E38A36FB98148953B2B83299192D2DEAE567D9A4F49C350`. The zero-token package
suite passes `4/0/1`, with only unprovisioned C292 skipped; cleanup leaves no package processes or
backup markers. No provider/model prompt ran. The guarded ordinary push advanced the publish
remote from `48e9af996` to `2b9e5b1a7`; local, remote-tracking and `ls-remote` match. Next action:
await the automatic Copilot review and triage every new finding.

`2026-08-31`: automatic Copilot review `5068959587` of publish `48e9af996` completed
successfully with two visible and one suppressed finding. All three are valid security/lifecycle
**FIX** items: a helper that connects after the one-shot runtime broadcast must receive current
Yolo default/policy fields; a native mode change initiated through `/config` must gate normal,
manual-autofix and automatic-autofix prompts until acknowledgement; and a fresh session already
at the privileged provider value but lacking a valid restore option must fail closed rather than
be treated as an absent capability. Next action: add deterministic C++/App/provider REDs for all
three findings, record their exact failures, then make the smallest owning-abstraction fixes and
run focused/full validation. No real provider/model prompt is required for this review slice.

`2026-08-31`: Copilot review `5068745670` of `74c775c47` correctly found that the renamed
custom-provider permission package case no longer mapped to a release-checklist ID. Dev
`17092df4c` / publish `48e9af996` maps the exact title `Permission UI works` to existing C069,
keeps C290 as a deterministic supported-provider native-ACK UT claim, and strengthens the package
case to prove both explicit `allow-once` and `reject-once` while global Yolo is enabled. Clean
ItE2E selftests pass `21/21`; the publish-source zero-token suite against the unchanged exact
`74c775c47` product package passes `4/0/1` and generates C069 as `[x]`. The commit changes only
the release checklist and package test, with identical dev/publish blobs and no product input
delta, so no product rebuild was needed. Cleanup found no package processes or backup markers.
No provider/model prompt ran. The guarded ordinary push advanced the publish remote to
`48e9af996`; local, remote-tracking and `ls-remote` match. Next action: wait synchronously for the
automatic review of `48e9af996`, then triage every new finding.

`2026-08-31`: Copilot review `5066808820` of `ef899419e` added two valid findings.
High `discussion_r3894720068` showed that an authoritative `ConfigOptionUpdate` removing or
malforming a native Yolo selector left the prior config channel active. Medium
`discussion_r3894720134` showed that C290's packaged custom-agent fixture proved only the
unsupported-provider baseline, not permission behavior after a supported provider's native ACK.
The first deterministic RED returned stale `SetConfigOption { allow_all, on }` after an empty
Copilot config update. Dev `4463c65fe` / publish candidate `74c775c47` now invalidates a vanished
config channel as uncertain loaded state so disable fails closed, while retaining a separately
advertised Claude/Codex mode channel. A deterministic supported-provider mock starts at `default`,
acknowledges `bypassPermissions`, then proves the permission request remains unresolved until an
explicit `allow-once` response. The custom-provider package case is accurately renamed and no
longer credited as native-active C290 evidence; C290 is now a pure deterministic UT claim.
Current dev GREEN: config updates `7/7`, Yolo `67/67`, permission `48/48`, full WTA `1903/0/1`,
ItE2E selftests `21/21`, rustfmt and diff checks. Publish has the same focused/full totals.
Exact `74c775c47` is built, deployed and freshness-verified `18/18`; source fingerprint is
`EDC8B1FFE9A53B6B9B4DC708F1DA308DA7386B14649B654BD8400EBC5BF3BC7D` and WTA SHA-256 is
`80F3F2741D6AB77C5A959F9E53DBA640AB76311F573C202AD585715A0331348E`. The fresh zero-token
suite passes `4/0/1`, with only unprovisioned C292 skipped; cleanup leaves no package processes or
backup markers. No provider/model prompt ran. The first guarded push attempt was interrupted before
remote mutation; a fresh guard confirmed remote `ef899419e`, and the retry advanced it normally to
`74c775c47`. Local, tracking and `ls-remote` now match. Next action: wait for the automatic review,
then reply and resolve both fixed threads.

`2026-08-31`: the review of publish `0634b8563` reported one visible High and three
suppressed findings. Dev `0e00e54bf` / publish `3aa4e883c` fixes both root causes:
`AgentPaneYoloMode`, `EffectiveAgentPaneYoloMode`, and `IsYoloModePolicyLocked` are appended
after every existing `GlobalAppSettings` member to preserve WinRT ABI ordering, and `/config`
cannot commit a value while a Yolo transaction or reconciliation gates the tab. The fix pair has
the same stable patch ID. Latest `origin/main@afd2beaf2` is merged as dev `96dfcc4ba` and publish
`57ac03117` plus conflict-completion `ef899419e`; their publishable trees are semantically equal
(the only byte difference is one CRLF on an unchanged mock-fixture line). Focused Yolo passes
`64/64`, SettingsModel passes `39/39`, and full WTA passes `1900/0/1`. Exact publish
`ef899419e` is built, deployed, and freshness-verified `18/18` with source fingerprint
`70186975694D9E562538E9571DF9678B374623671D01279420CB43A942F33A07` and WTA SHA-256
`6C2379619CE5F23BAED7B1328DB9670F21BE476B88F02A6BED1F52D5BFEF18A9`. The first
zero-token run passed `3/1/1`; C287 failed before its behavior assertion on a transient 45-second
pane-open UIA timeout. Its exact-package focused rerun passed `1/0/0`, and a fresh complete run
passed `4/0/1`, skipping only unprovisioned C292. Cleanup found no backup markers or surviving
package processes. No real-provider/model prompt was run. The guarded ordinary push advanced
the publish remote from `0634b8563` to `ef899419e`; local, remote-tracking and `ls-remote` match.
Next action: reply/resolve the ABI and removed-CWD review threads, then wait for and triage the next Copilot
review.

`2026-08-31`: automatic Copilot review of Yolo publish `0634b8563` completed successfully but
reported one visible High and three suppressed findings. The visible High and two suppressed
duplicates identify WinRT ABI breakage: `AgentPaneYoloMode`, `EffectiveAgentPaneYoloMode`, and
`IsYoloModePolicyLocked` were inserted before existing `GlobalAppSettings` members despite the
append-only contract. The remaining suppressed finding is also valid: `/config` value commits run
before the Yolo prompt gate and can race a pending provider-native mode/config RPC. Next action:
add deterministic REDs for IDL member ordering and blocked config-picker mutation, then make the
smallest fixes, run focused/full validation, cherry-pick to publish, rebuild exact package, and
request/wait for the next Copilot review. No real-provider/token test is required for this slice.

`2026-08-31`: user directed that all agent/helper working-directory behavior be removed
from PR #505 because correct ACP cwd is a generic fix, not sufficient justification for expanding
the Yolo PR; Gemini still requires separately provisioned trusted-folder state. Yolo dev/publish
now have patch-identical removal commits `685c086ba` / `0634b8563`; the publish net diff has no
CWD path or added CWD token. `0634b8563` is pushed and local, remote-tracking and `ls-remote`
match. Published history was not rewritten, so superseded CWD commits remain visible in the PR
timeline but contribute no Files diff. Standalone branches were created from
latest `origin/main@d59731c9`: `user/DinahK-2SO/agent-pane-cwd-dev@9a5d49999` in
`C:\ado\intelligent-terminal-cwd-dev` and
`user/DinahK-2SO/agent-pane-cwd-publish@7fb113c67` in
`C:\ado\intelligent-terminal-cwd-publish`. The publish branch was migrated without rewriting
history, and the superseded `origin/dev/vanzue/agent-pane-cwd` ref was removed. Their three patch IDs and complete trees match; the
six-path diff contains no Yolo, Gemini or trust behavior. Standalone validation passes full WTA
`1809/0/1`, focused TerminalApp TAEF `3/0/0`, TerminalApp and package builds with zero errors;
local, remote-tracking and `ls-remote` now match at `7fb113c67`. Deployment was deliberately not
forced because the safe deploy helper found the current Dev loose package registered from the
Yolo worktree; switching layouts would require unregistering that package and risking local state.
Yolo validation passes `63/63`, full WTA `1897/0/1`, exact-package
build/deploy/freshness `18/18`, and zero-token E2E `4/0/1` at `0634b8563`. No real-provider test
was run after the split. The standalone dev branch remains local; publish is pushed. Next action:
reply to and resolve the superseded CWD scope comment on PR #505, then open/review the standalone
CWD PR when requested.

`2026-08-31`: current publish, remote-tracking and `ls-remote` are
`c96b1d66d5f1d9f8178cdca652fad1f06f4153d0`; latest audited `origin/main` is
`d59731c99993121a921e93795a108c1c956776b3`. Publish is ahead `51`, behind `5`; dev is ahead
`56`, behind `8`. The latest three review rounds are fixed and pushed: `c99714ec1` gates every
prompt producer across bootstrap, initial-load, `/new`, session attach, policy and error paths;
`8b9d63a40` corrects successful-`/new` test channel lifetime without weakening disconnect
semantics; and `c96b1d66d` includes pending `/yolo` transactions in the same gate, retaining it
through unknown outcomes until agent reset. Focused Yolo tests pass `63/63`; full WTA passes
`1898`, fails `0`, ignores `1`; exact-package freshness passes `18/18`; zero-token Yolo passes
`4`, fails `0`, skips only unprovisioned C292. Real-provider acceptance at exact parent package
`8b9d63a40` passes Copilot, Claude, Codex and OpenCode. Gemini `0.51.0` is externally blocked:
two ACP runs and one direct provider run all timed out without a completed tool effect, while WTA
proved native acknowledgement preceded prompt dispatch. Public PR HTML currently shows no
Copilot review after `c96b1d66d`. Next action: request/wait for that review, then triage any new
findings before merging latest main (which requires complete revalidation).

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
  the remaining old flag, fixture, docs/E2E oracle and UI wording. The provider-native summary
  is now translated in every real WTA locale and independently reviewed for semantics and locked
  tokens; pseudo-localization behavior is preserved.
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
- Current dev branch/head is `dev/dinah/yolo-mode@95c92565f`; its latest publishable product
  commit is `60a60e2b8`. The validated prior publish baseline separately
  merges `origin/main@619377d6` (`2026-08-28`, #680, #678 and #681) as `d99a0e787`.
  Earlier publishable follow-ups are
  `cd2b2e88` (host cwd),
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
- `2026-08-27` quota-boundary correction: every real model/tool prompt moved to
  `local-tdd-kit/Feature.YoloMode.RealUser.Tests.ps1`. Publishable
  `test/e2e/tests/Feature.YoloMode.Tests.ps1` now contains five zero-token cases only; its exact
  deployed-package run passes `4`, fails `0`, and skips the unprovisioned policy case `1`.
  Publishable commit `2d9e06dfe` removes all token-consuming prompts and CI/release mappings.
- Claude local acceptance is pinned through the real Claude CLI and ACP adapter to Agent Maestro's
  Anthropic proxy with `gpt-5.6-sol[1m]`, advertised by GitHub Copilot and tool-capable. A bounded
  direct Claude smoke returned `CLAUDE_MAESTRO_GPT_OK` in `19.23s` without the prior
  `invalid_message_role` failure. The targeted local-only package case then acknowledged native
  Yolo on, issued its first real tool call after `6.334s`, created/read the unique marker, rendered
  the exact `44`-character marker response, acknowledged native Yolo off, and completed in
  `13.932s`. No permission request occurred and Terminal settings/state were restored.
- The first realistic provider run against exact product build `ffe5b13e` completed `3` pass,
  `4` fail, and `2` prerequisite skips; it is retained as local evidence, not a CI result.
  Publish-only test/docs correction `2d9e06dfe` is pushed as publish HEAD `7c215900`; its product
  sources and deployed binaries are unchanged from freshness-verified parent `ffe5b13e`.
- Gemini's remaining `System32` workspace was traced past the helper into ACP `session/new`.
  Deferred per-tab pre-warm, added after the original cwd resolver, runs after the startup-action
  virtual cwd has returned to the AUMID launch directory; the old window-first resolver therefore
  overrode the active control's profile-preseeded workspace. A focused C++ test reproduced RED
  (`expected C:\work`, `actual C:\Windows\System32`) and is GREEN with pane-first resolution plus
  window/profile/home fallbacks. The fix is committed as `70568a323`; latest main merged without
  conflicts as `8f77bc78b` and was cherry-picked to publish as `11c659f60` after publish merge
  `c3205e8f1`.
- Exact publish HEAD `11c659f607` is built, deployed and freshness-verified. Full WTA passes
  `1838/1838`; packaged zero-token Yolo E2E passes `4`, fails `0`, and skips the unprovisioned
  policy case `1`. Local-only exact-package runs pass for Copilot (`67.665s`), Claude through
  Maestro/GitHub Copilot GPT (`59.054s`), Codex (`89.395s`), Gemini (`68.049s`) and the OpenCode
  unsupported-Yolo plus real-chat negative case (`48.318s`). All reports remain ignored.
- One malformed local discovery attempt left Terminal `.e2ebak` files that an execution helper
  later deleted instead of restoring. Recovery evidence proved the pre-test settings had only
  `acpAgent` among the cleaned agent keys, the pre-test runtime used Copilot/Auto with Yolo off,
  and the ACP workspace was `C:\Users\xiaomgao`. The recovered settings remove the test temp cwd,
  restore `acpAgent: copilot`, contain no `ite2e-` path, and pass a fresh zero-token launch with
  Copilot and home cwd. Damaged copies and recovery evidence are retained under the ignored
  `local-tdd-kit/artifacts/yolo-mode/settings-recovery-20260827/` directory.
- Publish local and remote are byte-identical at `11c659f607`; next work is review-evidence
  screenshots/design-security signoff, not another product or provider implementation change.
- `2026-08-27` comprehensive review remediation is committed as `dfb030d3d` and included in
  the validated local publish candidate as `e3cec54da`.
  The public audit covers all `55` visible discussion nodes and `19` suppressed sections, not
  only the latest `2 + 2` review object. Accepted fixes include dynamic long-`USERPROFILE`
  handling, bounded native-session maps and cancellation-safe gates, App-owned Yolo transaction
  IDs that reject stale ACKs after session-ID reuse, zero-token ACP readiness classification,
  two-launch persistence and policy-startup E2E oracles, crash-safe settings restoration,
  corrected Settings lock annotations, native translations for every real WTA locale and spelling.
  Deterministic REDs were captured for generation/gate retention, canceled in-flight cleanup,
  stale reused-ID ACK consumption, absent-config cleanup and the original long environment read.
  Current GREEN: Yolo `38/38`, permissions `47/47`, full WTA `1843/1843`, TerminalApp `197/197`,
  publishable framework selftests `20/20`, dev-kit selftests `16/16`, locale parity `1/1`, and all
  PowerShell/XML/BOM/EOL/lock checks. The commit excludes this file, `local-tdd-kit/`,
  `fetch_agents.md` and `qps.txt`.
- `2026-08-28` exact-package review validation exposed a real C286 gap after the E2E oracle
  scope was repaired: the initial bootstrap session emits `AgentConnected`, while global Yolo
  reconciliation existed only under `SessionAttached` for later `/new`/load sessions. The
  packaged two-launch case reproduced RED despite a persisted `agentPane.yoloMode: true` and a
  connected Copilot session. A deterministic App RED saw no master request (`Empty`). Commit
  `fc5e8fe30` now routes both lifecycle events through `reconcile_session_yolo`; the same test is
  GREEN, Yolo passes `38/38`, and full WTA passes `1843/1843`. The preceding observability/test
  fix is `7fd0cea1b` (publish `67367b914`); the bootstrap fix is publish `c28528a0c`.
  Exact publish `c28528a0c` is built, deployed and freshness-verified. C286 is GREEN, the
  complete zero-token suite passes `4`, fails `0`, and skips only the unprovisioned policy case
  `1`. The policy prerequisite is blocked because HKCU `Software\Policies` was not granted test
  write access; Copilot ACP is ready and HKLM has no override. Local-only real-provider acceptance
  passes Copilot (`58.213s`), Claude through Maestro/GitHub Copilot GPT (`56.260s`), Codex
  (`52.705s`), Gemini (`69.926s`) and OpenCode (`39.083s`). All Terminal settings/state and Gemini
  trust hashes were restored, with zero backup markers, processes or provider temp directories.
- `2026-08-28` post-push review remediation is committed as `12cfe5ce9` and cherry-picked to
  the validated publish candidate as `9567d42ad`. Every
  `system.yolo_blocked_by_policy` value now preserves exact `Yolo` under a line-level lock
  (`89/89`; `55` token corrections), and current Gemini architecture/reproduction docs use
  `--acp`; the sole `--experimental-acp` reference is explicitly historical. Byte/line/BOM/EOL
  validation passes for all locale files, locale parity passes `1/1`, Yolo passes `38/38`, and
  full WTA passes `1843/1843`. Independent focused review found no defects. Exact publish
  `9567d42ad` is built, deployed and freshness-verified with source fingerprint
  `2B98149201B7B4DEC5AEBD80E901FD5FB7DBE85A589DBEC2680831549D87EFF7` and WTA SHA-256
  `F756C68D20C6748B375B23ECAB2BDFAFF15AE265736B44825171D4995D3E325F`. Packaged zero-token
  Yolo passes `4`, fails `0`, and skips only the unprovisioned policy case `1`. Local-only
  real-provider acceptance passes Copilot (`55.055s`), Claude (`58.092s` targeted rerun after
  one transcript-capture miss), Codex (`72.003s`), Gemini (`53.963s`) and OpenCode (`38.668s`).
  Terminal settings/state were restored byte-for-byte with no real backup markers, provider
  processes or disposable workspaces left behind.
- `2026-08-28` the latest High review finding reproduced RED: a provider config RPC held the
  per-session operation gate past a `500ms` test watchdog, so a newer disable could not run.
  The current dev delta bounds both provider-native config-option and mode RPCs at `10s`, checks
  operation currency after successful responses, and releases the gate so newer work is not
  stranded. ACP cancellation is cooperative, so every timeout, including a superseded enable,
  is treated as an unknown provider outcome and restarts the shared master/Agent CLI pool without
  committing stale local state. Fail-closed reconciliation has one overall `10s` deadline and
  stops at its first error; non-fail-closed known errors retain best-effort behavior. Deterministic
  native/App/dispatcher tests cover config and mode timeout, stale compensation, gate cleanup,
  single restart, aggregate deadline and first-error behavior. Yolo passes `47/47`, rustfmt/diff
  checks pass, and full WTA passes `1852/1852` with the source-matched repo `wtcli.exe` first on
  `PATH`. The product/test delta is committed as `4535d41b8` and present in the validated publish
  candidate as `61200332f`; the final main merge and fix were pushed as `d99a0e787`.
- `2026-08-28` the timeout delta is committed on dev as `4535d41b8` and cherry-picked to
  publish as `61200332f`. Latest main `619377d6` was then merged as `d99a0e787`; a whole-file
  mock-test conflict was only LF/CRLF churn plus main's one semantic rename from
  `request_terminal_actions` to `terminal_send`. The resolved split-action visibility test and
  mode-timeout dispatcher test pass `1/1` each. Post-merge focused suites pass: Yolo `47/47`,
  permission `47/47`, proposal `60/60`, terminal action `2/2`; full WTA passes `1875`, fails `0`,
  and ignores one environment-dependent test.
- Exact publish candidate `d99a0e787` is built, deployed and freshness-verified (`18/18`) with
  source fingerprint `EE84806B9DF15F0009CB01CBB5CD8AB3B8F8088E6A935E8B6D7623FAAE9AF43E`
  and WTA SHA-256 `ABA9488BC76927A7EA84896702473A1E786980FC60BCE491700134383380922E`.
  The first zero-token run had one Pester setup-control-flow failure after the permission fixture
  had already completed ACP initialize/session-new; the focused permission rerun passed `1/1`
  and a fresh complete run passed `4`, failed `0`, skipped only the unprovisioned policy case `1`.
  Real-provider acceptance passed Copilot (`55.670s`), Claude (`66.405s`), Codex (`47.292s`) and
  Gemini (`57.303s`) in the first matrix. OpenCode first failed before any Yolo/chat assertion
  because an unnecessary owner-tab VT event probe timed out; the single-tab local-only harness
  now selects the unique current-run pane and the targeted unsupported-Yolo plus real-chat case
  passes (`40.003s`). No provider/test processes, disposable workspaces or backup markers remain;
  Terminal state contains no test fixture paths and Gemini trust contains no test/worktree paths.
  The guarded ordinary push advanced `origin/dev/vanzue/yolo-mode` from `9567d42ad` to
  `d99a0e787`; local HEAD, remote-tracking and `ls-remote` were verified byte-identical.
- `2026-08-28` latest review iteration at publish `d99a0e787` adds two valid findings. A live
  `AllowYoloMode` registry change is not currently observed until settings reload, despite the
  documented hot-enforcement contract; add an AppLogic-owned policy watcher that reuses the
  settings reload/runtime reconciliation path. A second `/yolo` command is currently dropped
  while the first transaction is pending; let the newer transaction replace pending UI state
  and rely on the native coordinator's existing operation supersession. Both are **FIX**.
- The current dev delta watches both HKLM and HKCU policy parent trees, refreshes TerminalApp's
  header-local policy cache, then reuses the dispatcher-backed throttled settings reload so the
  SettingsModel cache and each TerminalPage runtime diff update on the existing path. The watcher
  test observes recursive creation/write under an absent leaf key. The packaged C292 test now
  starts with Yolo allowed/on, changes `AllowYoloMode` to blocked while the session is live, and
  requires native off plus slash rejection. A newer `/yolo` transaction replaces pending UI state;
  stale ACKs cannot consume it. Focused supersession passes `1/1`, Yolo passes `48/48`, policy
  tests pass `38/38`, ItE2E selftests pass `20/20`, TerminalApp builds with `0` errors, and full
  WTA passes `1853/1853`. Product/E2E coverage is committed on dev as `60a60e2b8` and
  cherry-picked to publish as `2f193caed`. The first exact-package zero-token run then reproduced
  a framework RED: all four executable cases failed before their behavior assertions because the
  single-tab suite performed an unnecessary owner-tab VT-event probe. Dev commit `95c92565f`
  (publish `2f1f1cea2`) selects the unique current-run pane already isolated by the harness;
  the same exact package passes `4/0/1` with that test source. WIL automatically rearms registry
  watchers but does not catch client callback exceptions, so dev `43b87e1e8` (publish `3cd4cc7bf`)
  makes the callback `noexcept` and logs any policy reload exception rather than terminating the
  app. Exact publish candidate `3cd4cc7bf` is built, deployed and freshness-verified (`18/18`)
  with source fingerprint `E33E49EBAB4FE318B19850C2651F91D3F1C5380BBF2AA47059140EADF0C48FA4`
  and WTA SHA-256 `DCDA4B85273AC5AC823345FB0FB671318AF1B81ADC808FEB15699779C295EAE6`.
  Final zero-token validation passes permission, persistence and native toggle in the full run;
  OpenCode's first pane-open attempt failed before its assertion and its exact-package targeted
  rerun passes `1/1`. C292 remains the sole prerequisite skip because this machine has not granted
  non-elevated HKCU policy-key writes; its live Allowed-to-Blocked flow is committed for a
  provisioned machine. Final exact-package targeted real-provider acceptance passes Copilot
  (`43.58s`), Claude (`39.26s`), Codex (`41.46s`), Gemini (`49.31s`) and OpenCode (`28.98s`).
  Cleanup finds zero provider/test processes, backup markers, disposable roots or test strings in
  Terminal/Gemini state. The guarded ordinary push advanced the publish remote from `d99a0e787`
  to `3cd4cc7bf`; local HEAD, remote-tracking and `ls-remote` were verified byte-identical.
- `2026-08-28` the next Copilot iteration at `3cd4cc7bf` reported two visible and two suppressed
  findings; all four are valid **FIX** items. The Yolo spec now documents newer-command
  supersession; the publishable suite resolves `Get-ItTestPackage` once and uses that selector for
  discovery and every launch; ACP source cwd is separate from a validated Win32 helper cwd; and
  policy watchers fall back to the deepest existing registry ancestor, then rebind on the UI
  dispatcher as missing segments appear. Deterministic REDs recorded package selector count
  `expected 1, actual 0`, missing `ResolveAgentAndHelperCwds`, and the missing ancestor-aware
  watcher overload. The first exact-package run exposed a second framework RED: the selector set
  in `BeforeDiscovery` was empty in Pester's Run phase (`0` pass, `4` fail, `1` policy skip).
  Each Describe now receives the once-resolved selector through `-ForEach`; the same exact product
  package then passes `4/0/1`. Dev commit `5515aee43` is byte-identical across its nine product
  paths to local publish candidate `ddb13f7f3`. GREEN on both worktrees: ItE2E selftests `21/21`,
  TerminalApp `198/198`, policy/custom tests `39/39`, and TerminalApp build with `0` errors.
  Independent final review found no defects. Exact candidate `ddb13f7f3` is built, deployed and
  freshness-verified `18/18` with source fingerprint
  `35D424A660374BE571C365EE70C55EFF57AC45265BC89FB8DB080508D1D2A163` and WTA SHA-256
  `A3CF5B886CA06E5E9760D62BC8C9BA6BD829F6BC0D1F6E4B355DEDED6BFEC913`.
  Final publish-source zero-token Yolo passes `4`, fails `0`, and skips only unprovisioned C292.
  The guarded ordinary push verified local, remote-tracking and `ls-remote` at `ddb13f7f3`.
- `2026-08-31` review remediation after spelling follow-up `15408b542` is committed on dev as
  `5f8e3ca12` and published as `fa100b87f`. Two visible High findings and two suppressed findings
  are fixed: a live policy block immediately gates prompt entry while native off is pending;
  provider-native privileged `/config` values are policy-checked under the generation-fenced
  per-session operation gate before ACP; a lazy session establishes effective native state before
  its first prompt; and OpenCode packaged coverage uses a zero-token ACP readiness probe with an
  explicit external-prerequisite classification. Deterministic tests cover blocked and queued
  privileged config, lazy success/failure, overlapping reconciliation, session reuse, initial and
  reconnect shared state. No WTA permission option is selected automatically.
- The review of `fa100b87f` produced two valid Medium findings and one valid Low
  scope/documentation finding. Dev `6f128ac0d` / publish `c99714ec1` adds a typed distinction
  between initial-load placeholders and capability-ready sessions, owner-tab routing, tab- and
  session-scoped prompt gates for both enable and disable reconciliation, complete `/new`/load
  error recovery, stale-completion fencing, and coverage for normal, `/fix`, and automatic
  autofix producers. The CWD separation remains in this PR because package/provider validation
  exposed a POSIX path being used as a Win32 helper launch directory; the Yolo spec now records
  its rationale, host/WSL compatibility impact, Win32 API validation, tests and non-goals.
- The first full WTA run after `c99714ec1` exposed three deterministic test-fixture failures:
  successful `/new` tests dropped their receiver, so the newly correct send-failure path preserved
  the old session rather than pretending a replacement succeeded. Dev `3ad490bd9` / publish
  `8b9d63a40` keeps the receiver alive in those tests and adds a disconnected-channel regression;
  neighboring new-session tests pass `10/10` and full WTA passes `1895/0/1`.
- The review of `8b9d63a40` produced one valid High finding: a pending `/yolo off` transaction
  was not part of the unified prompt gate. Dev `5e47d4f48` / publish `c96b1d66d` blocks normal,
  manual-autofix and automatic-autofix prompts until matching slash acknowledgement, preserves the
  gate through unknown provider outcomes until agent reset, and proves runtime updates replace the
  slash gate atomically with a reconciliation gate. Focused Yolo tests pass `63/63`; full WTA
  passes `1898/0/1`. Stable patch IDs match for all three dev/publish commit pairs.

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
| A delayed `/yolo` ACK for a torn-down session can consume a new transaction after the provider reuses the same session ID. | Covered: App-owned transaction IDs flow through the master request and completion event; stale ACK is ignored and the current ACK still commits. |
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
- Any test that submits a real model prompt or consumes provider/token quota is dev-only. Its
  source, orchestration and reports must stay under `local-tdd-kit/` or another ignored/local
  evidence root; never copy it into `test/e2e`, the publish branch or a CI pipeline. Publishable
  packaged coverage may use deterministic mocks and zero-token initialize/session/native-mode
  checks only.
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
- Put zero-token publishable packaged coverage in the existing `test/e2e` ItE2E framework.
  `Feature.YoloMode.Tests.ps1` proves the actual Settings/slash/policy path without issuing a
  model prompt; token-consuming real provider/tool coverage belongs only in
  `local-tdd-kit/Feature.YoloMode.RealUser.Tests.ps1`.
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
- User-visible unsupported-provider status for a globally enabled setting (Settings warning
  currently explains that unsupported providers continue prompting).
- Reviewed translations for the revised WTA `/yolo` summary outside en-US/pseudo locales.
- Fresh review screenshots for the full Settings/status/permission/two-tab matrix.

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
| Current Yolo suite | `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml yolo` | All provider-native and state tests pass | PASS `64/64` at `ef899419e` | Console result, `2026-08-31` |
| Current permission suite | Same command with filter `permission` | All provider, proposal and user-input requests require explicit selection | PASS `47/47` | Console result, `2026-08-26` |
| Full WTA | Fresh `bin/x64/Debug/wtcli` first on PATH; `cargo test --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml` | All product tests pass | PASS `1900`, FAIL `0`, IGNORE `1` at `ef899419e` | Publish console, `2026-08-31` |
| Settings model | Explicit local TAEF runner on `SettingsModel.Unit.Tests.dll /name:*CustomAgentAndPolicyTests*` | All Yolo/policy cases pass | PASS `39/39`; missing-ancestor watcher focused `1/1` on dev and publish | Console result, `2026-08-28` |
| TerminalApp unit tests | Explicit local TAEF runner on `Terminal.App.Unit.Tests.dll` | Agent cwd and neighboring app utilities pass | PASS `198/198`; source/helper cwd split focused `1/1` | Console result, `2026-08-28` |
| Publishable E2E framework selftests | `Invoke-Pester test/e2e/selftests/ItE2E.Unit.Tests.ps1 -Tag Unit` | Log boundaries, backup/restore and suite package routing remain hermetic | PASS `21/21` | Console result, `2026-08-28` |
| Policy/resources | Parse ADMX/ADML XML and assert `AllowYoloMode`; assert both Settings keys in every locale | Exact key parity | PASS: policy references/values valid; XML/BOM/EOL/key parity PASS `16/16` | Console result, `2026-08-25` |
| Explicit build/deploy | Publish ignored `Invoke-BuildDeploy.ps1 -SkipWtaTests -Launch` after full WTA | Build/deploy receipt succeeds | PASS at `ef899419e` | Publish `.local-tdd-kit-run/artifacts/build-receipt.json` |
| Freshness | Publish ignored `Verify-DeploymentFreshness.ps1` | Source, staged, installed and live identities match | PASS `18/18`; WTA SHA-256 `6C237961...18A9` | Same receipt, `2026-08-31` |
| Packaged E2E | `$env:ITE2E_PACKAGE='Dev'; pwsh -File test/e2e/Invoke-ItE2EReport.ps1 -Path test/e2e/tests/Feature.YoloMode.Tests.ps1` | Settings/slash/policy flows pass without model prompts | Fresh complete rerun PASS `4`; FAIL `0`; SKIP `1` unprovisioned C292 policy prerequisite at `ef899419e` | Publish untracked `zero-token-yolo-ef899419e-rerun/` reports |
| Static checks | `cargo fmt --check`; `git -c core.whitespace=cr-at-eol diff --check`; repository diagnostics on touched files | Clean | PASS | Console/editor result, `2026-08-25` |
| Maestro Claude API | Direct Anthropic request + isolated `claude -p` | VS Code LM answers without a Claude account | PASS, exact markers returned | Console result, `2026-08-25` |
| Maestro Claude ACP | `local-tdd-kit/Invoke-MaestroClaudeAcpProbe.ps1` / equivalent isolated production probe | Pinned adapter completes initialize + session/new without touching user config | PASS; 6 models, current `gpt-5.6-luna[1m]`, user config unchanged | Console result, `2026-08-25` |
| Real provider | Exact publish package with Copilot, Claude, Codex and Gemini native paths; OpenCode interactive | Native ACK, real tool effect/response or unsupported negative, and cleanup pass | At `8b9d63a40`: PASS Copilot `48.23s`, Claude `45.23s`, Codex `42.51s`, OpenCode `32.71s`; Gemini external BLOCKED after two ACP timeouts and one direct timeout | Dev ignored `real-user-yolo-8b9d63a40/` plus Gemini diagnostics |

### Exact Publish Identity

- Current local and remote publish HEAD is
  `ef899419ef7d5467e429640ffa12f42e137436bf`.
- Build receipt source fingerprint:
  `70186975694D9E562538E9571DF9678B374623671D01279420CB43A942F33A07`.
- The recipe maps the explicit-target WTA binary, whose source/staged/installed SHA-256 is
  `6C2379619CE5F23BAED7B1328DB9670F21BE476B88F02A6BED1F52D5BFEF18A9`.
- The installed layout is the publish worktree's Debug `AppX`; `WindowsTerminal.exe`,
  `wtcli.exe`, protocol WinMD and `resources.pri` propagation checks all pass, and the
  freshness launch ran from that layout.

Test source may come from a dev-only harness, but the tested application must come from
the exact publish HEAD. Always set `ITE2E_PACKAGE=Dev`; `Auto` is not acceptable evidence.

## Real Integration Acceptance

**Local-only quota boundary:** every workflow in this section submits real model prompts and may
consume paid/provider quota. The harness is manual local-development infrastructure. It must not
be tracked by the publish branch, copied into `test/e2e`, or invoked by CI. CI has no provider
token budget and must use deterministic mocks or zero-token protocol checks instead. The app under
test is still the exact package built from the publish HEAD.

- Required provider A: installed and authenticated Copilot CLI. Current observed CLI
  version is `1.0.81`; record the actual version again at test time.
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

### Simulated Real-User E2E Procedure

This procedure is the acceptance meaning of "simulated real-user E2E" for PR #505. It uses
automation to drive a normal user workflow, but the installed product, ACP server, provider CLI,
model turn and tool effect are real. A handshake-only probe, mock agent or injected completion
state does not satisfy it. Because it deliberately consumes real tokens/quota, both this harness
and its evidence are local-development-only and must never enter the publish branch or CI.

1. **Freeze exact publish identity.** In the clean publish worktree, fetch `origin/main` and the
  publish ref with command-line `git`, require both to be ancestors of local HEAD, and record the
  full SHA. Permit only the untracked local validation kit; no dev-only handoff or evidence files
  may be tracked in publish.
2. **Build and deploy that SHA.** Put the publish worktree's source-built `wtcli.exe` first on
  `PATH`, run the full explicit-target WTA suite, then run the publish worktree's build/deploy
  helper. The receipt must prove source fingerprint, HEAD, recipe source, staged binary,
  installed layout and SHA-256 identities all match. Always set `ITE2E_PACKAGE=Dev`; `Auto` is
  not acceptable evidence.
3. **Record real prerequisites without changing authentication.** Record CLI/adapter version,
  selected model and inference backend. Copilot and Gemini use their real provider accounts;
  Claude and Codex may use their real CLIs/adapters with VS Code LM supplied through Maestro,
  and must be labeled accordingly. Missing login, quota or provider availability is `BLOCKED`,
  never a silent skip or pass. A cold Codex adapter timeout is a product failure, not a prewarm
  pass.
4. **Use a disposable workspace and normal product entry points.** Launch the exact Dev package
  by package AUMID, select the provider through product settings, create/focus a tab rooted at a
  unique temporary directory, open the Agent pane and wait for the rendered connected state.
  Do not invoke internal maps or a test-only product route. For Gemini, pre-existing workspace
  trust is a provider prerequisite. The E2E fixture may back up, temporarily add only its exact
  disposable directory to `trustedFolders.json`, and restore it in `finally`; this is test setup,
  not coverage or implementation of a WTA trust UX.
5. **Exercise the complete Yolo transaction.** Verify default/global state as required, submit
  `/yolo on`, and wait for the provider-native ACP acknowledgement before claiming enabled.
  Submit one bounded normal-cost prompt requiring the provider's shell tool to create a file
  containing a unique marker, read it back and reply with only that marker. Assert the exact file
  content, rendered model response and provider-native operation. Then submit `/yolo off`, wait
  for acknowledgement and prove the captured prior provider mode was restored. Exercise a second
  session where isolation is part of the contract.
6. **Keep independent permission boundaries observable.** While Yolo is on, ordinary ACP
  permission requests must remain pending until the test user explicitly selects an option.
  A `request_terminal_actions` proposal must remain a card until Run/Insert is selected. Never
  let the harness auto-select `AllowOnce` or treat model prose as the authorization oracle.
7. **Classify outcomes strictly.** `PASS` requires a real model turn, requested tool effect,
  unique file marker, expected user-visible response, native enable acknowledgement and restore
  acknowledgement. A model that answers without invoking the required tool, a missing marker,
  wrong target, startup-budget timeout or restore failure is `FAIL`. Provider-owned auth, quota,
  service availability or an unsatisfied trust/admin prerequisite is `BLOCKED`. Initialization
  success alone is never `PASS`.
8. **Clean up and preserve reviewable evidence.** In `finally`, stop only processes launched by
  the run, restore Terminal settings/state and any provider config byte-for-byte, remove the
  disposable workspace, and leave real credentials untouched. Store reports/log extracts under
  the ignored evidence root with publish SHA, package path, hashes, provider/version/model,
  inference payer, cwd, duration and outcome. Do not record secrets, account IDs, unrelated
  prompts or unrelated terminal content.

Current command shape from the dev worktree after the exact publish package is deployed:

```powershell
$env:ITE2E_PACKAGE = 'Dev'
pwsh -NoProfile -File .\test\e2e\Invoke-ItE2EReport.ps1 `
  -Path .\local-tdd-kit\Feature.YoloMode.RealUser.Tests.ps1 `
  -OutDir .\local-tdd-kit\artifacts\yolo-mode\real-user-yolo-<PUBLISH_SHA>
```

- Status: exact publish `11c659f607` is built/deployed/freshness-verified and passes all five
  targeted local-only provider rows. Claude uses the real CLI and pinned ACP adapter with Agent
  Maestro backed by GitHub Copilot `gpt-5.6-sol[1m]`; OpenCode remains unsupported for Yolo and
  passes real chat. Publish/CI owns no model prompt or real-token runner.

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

Current review status: all known comments through the review of `8b9d63a40` are fixed and pushed
in `c96b1d66d`. Public PR HTML currently shows no Copilot review after that commit. Check runs and
annotations were read through public HTTPS or user-provided screenshots only; no GitHub,
GitKraken or `gh` authentication was invoked. REST does not expose authoritative thread-resolution
state anonymously, so the correct online account must reply/resolve pushed fixes.

The `2 formal + 2 suppressed` count applies only to that final review object, not to every
still-visible or unresolved conversation on the PR. Earlier iterations contain additional
review comments that remain relevant until their code or metadata finding is fixed. In
particular, the Files view expands dozens of per-locale comments from the prior review; those
are one repeated root cause but must not be omitted from the review inventory.

### Post-Push Iteration (`c28528a0c`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| Policy-blocked messages do not lock the product term `Yolo`; 55 locale values changed its case or pseudo-localized it | User-provided Copilot screenshot, `tools/wta/locales/en-US.yml:246` | **FIX** | Fixed in the current dev delta: all `89` locale files have exactly one locked, case-sensitive `Yolo`; `55` affected values were corrected while preserving surrounding translations and pseudo-localization. |
| Gemini launch documentation still says `--experimental-acp` after command construction changed to `--acp` | User-provided Copilot screenshot, `src/cascadia/inc/AcpModelUtils.h:77-80` and `doc/specs/acp-1.0-conductor-migration.md:881-883` | **FIX** | Fixed in the current dev delta: current architecture and reproduction paths use `gemini --acp`; the sole remaining `--experimental-acp` mention is explicitly labeled as the historical flag used by the recorded 0.46 study. |

### Latest Iteration (`9567d42ad`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| A hung provider-native Yolo RPC holds the per-session gate indefinitely, so a later policy disable cannot fail closed or restart the agent stack | User-provided Copilot screenshot, `tools/wta/src/protocol/acp/native_yolo.rs:203-207` | **FIX** | Fixed in the current dev delta: both provider mutations have a named `10s` timeout and release their gate on expiration. RED exceeded a `500ms` watchdog; GREEN covers config/mode timeout, newer-disable progress, gate cleanup and `RestartMaster`. |
| Policy fail-closed reconciliation applies the per-session timeout serially, so multiple hung sessions can delay restart for `N * 10s` | Independent focused review of the timeout delta | **FIX** | Fixed in the current dev delta: fail-closed reconciliation has one overall `10s` deadline and stops after its first ordinary error. Real-dispatcher tests prove a hung first disable emits `RuntimeYoloReconcileCompleted(Err)` without attempting every later session; non-fail-closed known errors still continue best effort. |
| Dropping a timed-out ACP request sends only cooperative cancellation, so a provider may apply a late stale mutation after WTA releases the gate | Independent focused review plus `agent-client-protocol 1.3.0` source audit | **FIX** | Fixed in the current dev delta: every native mutation timeout is an unknown remote outcome that requests shared master/Agent CLI replacement, including superseded operations and non-policy enables. Stale transactions do not commit local state; config/mode dispatcher tests and an App test prove restart propagation and exactly one restart event. Yolo passes `47/47`; full WTA passes `1852/1852`. |

### Latest Iteration (`d99a0e787`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| `AllowYoloMode` is cached only during settings load, so a live GPO change does not emit the promised hot `agent_config_changed` update | Copilot `discussion_r3879560480`, `src/cascadia/inc/AgentPolicy.h:148` | **FIX** | Fixed in the current dev delta: AppLogic watches both policy parent trees, refreshes its per-DLL cache, and invokes the existing throttled settings reload/runtime reconciliation path. A deterministic recursive registry test is GREEN; C292 now encodes the live Allowed-to-Blocked transition for exact-package validation. |
| A second `/yolo` command is silently discarded while the first provider RPC is pending | Copilot `discussion_r3879560510`, `tools/wta/src/app.rs:5588-5593` | **FIX** | Fixed in the current dev delta: the pending-map early return is removed, each command allocates a newer transaction, and `/yolo on` then `/yolo off` emits both requests. The focused test proves the stale first ACK is ignored and only the latest off result commits. |

### Latest Iteration (`3cd4cc7bf`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| Yolo spec says a second command is ignored although the implementation supersedes the pending transaction | User-provided Copilot screenshot, `doc/specs/Yolo-mode.md:146-147` | **FIX** | The spec now states that a newer command supersedes the pending update and stale acknowledgements are ignored, matching `newer_slash_yolo_command_supersedes_pending_transaction`. |
| One cwd is used both for source-aware ACP context and Win32 `wta-helper` process launch | User-provided Copilot screenshot, `src/cascadia/TerminalApp/TerminalPage.cpp:3177-3183` | **FIX** | `ResolveAgentAndHelperCwds` keeps a POSIX cwd for a WSL agent while selecting only a validated Windows directory for helper launch; a Host agent also rejects the POSIX source path. RED was the missing resolver; focused and full TerminalApp tests pass. |
| Yolo E2E hardcodes `Dev`, ignoring `ITE2E_PACKAGE=Store` | Suppressed Copilot comment, `test/e2e/tests/Feature.YoloMode.Tests.ps1:15` | **FIX** | The suite resolves `Get-ItTestPackage` once and passes that selector from Discovery to every Describe through Pester `-ForEach`; discovery, config ownership and every launch use it. Static RED found `0` resolver calls where `1` was required. Exact-package RED then caught the initial script-scope handoff (`0/4/1`); the data-bound fix passes selftests `21/21` and exact-package Yolo `4/0/1`. |
| User-policy watcher is absent when `Software\\Policies\\Microsoft` does not exist at startup | Suppressed Copilot comment, `src/cascadia/inc/AgentPolicy.h:100` | **FIX** | The watcher opens the deepest existing ancestor, watches one level until the next segment appears, and rebinds through the AppLogic UI dispatcher before policy reload. The deterministic RED lacked this overload; the progressive ancestor creation/write test and all `39` policy/custom tests pass. |

### Latest Iteration (`15408b542`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| Live `AllowYoloMode=Blocked` changes desired state but permits prompts while native off is pending | Visible Copilot High, `tools/wta/src/app_events.rs` | **FIX** | Published in `fa100b87f`: generation-aware fail-closed reconciliation gates prompt entry immediately and unlocks only after all matching native-off acknowledgements. Failures remain blocked through agent reset. |
| Generic `/config` can submit provider-native privileged values while policy is blocked | Visible Copilot High, `tools/wta/src/protocol/acp/client.rs` | **FIX** | Published in `fa100b87f`: exact provider-native enable values use the same per-session operation gate and generation fence, recheck policy immediately before ACP, and reject stale or blocked writes. Ordinary config remains unchanged. |
| Lazy-session `SessionAttached` allows the first prompt before native reconciliation | Suppressed Copilot finding, `tools/wta/src/app_events.rs` | **FIX** | The ACP client establishes effective native state synchronously before releasing the lazy session's first prompt; failure is fail-closed and requests restart when the provider outcome is unknown. Client ownership suppresses duplicate App RPCs. |
| OpenCode package test gates only on executable presence | Suppressed Copilot finding, `test/e2e/tests/Feature.YoloMode.Tests.ps1` | **FIX** | The suite uses zero-token `Get-AgentAcpStatus -AgentCommand 'opencode acp'` readiness and explicitly classifies not-installed, unauthenticated, timeout and probe failures as external skips. |

### Latest Iteration (`fa100b87f`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| Initial-load `AgentConnected` placeholder reconciles before `session/load` records capability | Copilot Medium, `tools/wta/src/app_events.rs` | **FIX** | Published in `c99714ec1`: a typed capability-readiness field distinguishes placeholders; the stable owner tab stays gated until the real `SessionAttached` records capability and takes over reconciliation. |
| Global-on bootstrap or `/new` can send a first prompt before provider-native enable acknowledgement | Copilot Medium, `tools/wta/src/app.rs` | **FIX** | Published in `c99714ec1`: tab/session reconciliation gates cover enable and disable and all normal, `/fix`, and automatic-autofix producers; `/new`, load, failure, reconnect and stale completion paths are fenced. |
| CWD separation is an independent user-visible compatibility change | Copilot Low, `src/cascadia/TerminalApp/TerminalPage.cpp` | **FIX (documentation; keep code)** | The code is required by prior High review and packaged provider validation: a POSIX source path cannot be a Win32 helper launch directory. `Yolo-mode.md` now documents rationale, host/WSL impact, Win32 filesystem validation, tests and non-goals. |

### Latest Iteration (`8b9d63a40`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| Pending `/yolo off` transactions are absent from the prompt gate | Copilot High, `tools/wta/src/app.rs` | **FIX** | Published in `c96b1d66d`: pending slash transactions gate normal, manual-autofix and automatic-autofix prompts until acknowledgement. Unknown outcomes stay gated until agent reset; runtime reconciliation atomically replaces the slash gate. Focused Yolo passes `63/63`, full WTA `1898/0/1`. |

### Latest Iteration (`11c659f607`)

| Finding | Source | Disposition | Rationale / required evidence |
|---|---|---|---|
| PR title/body still describe Copilot-only native handling plus `AllowOnce` fallback | Formal Copilot comment, `doc/specs/WTA-terminal-action-proposals.md` | **PARTLY FIXED (manual PR metadata)** | Public metadata at `48e9af996` has the reviewed provider-native title and no longer describes generic `AllowOnce`. Its body lists the four native mappings and provider-owned sandbox/file/network effects, but still omits the explicit no-auto-selection, custom-agent, terminal-action confirmation and acknowledgement/lifecycle paragraphs from the reviewed text below. The correct online account must finish this manual-only item. |
| Fixed `MAX_PATH` buffer accepts an oversized `USERPROFILE` result | Formal Copilot comment, `TerminalPage.cpp:3178-3181` | **FIX** | `GetEnvironmentVariableW` returns the required length when the buffer is too small. Add a dynamically sized environment reader and a deterministic >`MAX_PATH` unit test, then use it for the helper fallback cwd. |
| `Yolo setting persists` only reads the value seeded immediately before launch but is mapped to C286's restart/default-session contract | Suppressed Copilot comment, `Feature.YoloMode.Tests.ps1:77` | **FIX** | The two-launch E2E now changes the setting after launch, relaunches without reseeding, and asserts provider-native `enabled=true` while preserving/restoring the original files. That stronger oracle exposed and drove the bootstrap `AgentConnected` reconciliation fix in `fc5e8fe30`. |
| Existing WTA `/yolo` translations were overwritten with English | Earlier formal per-locale comments plus latest suppressed comment; representative `de-DE.yml:235` and `fr-FR.yml:233` | **FIX** | Commit `0e8be3a9` replaced already-localized summaries (for example German, French and Chinese) with one English provider-native sentence across all real locales. This violated the localization instructions. Re-translate the new semantics in every real locale using existing `.resw`/YAML terminology, QA locked tokens, and remove the stale `/yolo` lock because the value contains only `ACP`, `Yolo`, and `/new`. Preserve pseudo-localization behavior. |
| `lookalike` is unrecognized at two locations | GHAS check-spelling run `98509334977`, annotations `72853988321` and `72853988455` | **FIX** | Reword the test name/string to `look-alike` or another recognized term; do not add a dictionary exception for ordinary prose. |
| `session_generations` retains one tombstone per forgotten session | Suppressed Copilot comment in review `5039214710`, `native_yolo.rs:125` | **FIX** | Removing the generation key already fences a reserved operation (`Some(old) != None`) and lets a reused ID receive a fresh generation. Add a bounded-state regression test and remove the key on teardown. |
| Policy E2E checks only slash rejection, not startup global-on suppression | Formal Copilot comment `discussion_r3870421429` | **FIX** | Before sending `/yolo on`, assert the policy-blocked initial session never receives native `enabled=true` and is reconciled off. |
| Live Copilot E2E treats installed-but-unauthenticated as ready | Formal Copilot comment `discussion_r3870054212` | **FIX** | Use the established CLI status probe for session-dependent cases; keep installation-only readiness only where no ACP session is opened. |
| Ten check-spelling annotations report unavailable external dictionaries | Check Spelling run `98507975954` (successful) | **WON'T FIX** | The workflow completed successfully; the annotations are upstream dictionary-download availability warnings and are not caused by repository content. Re-evaluate only if they recur after the substantive push. |
| Optional generated pattern `image: [-\\w./:@]+` | Check Spelling run `98507967759` (successful, one notice) | **WON'T FIX** | This is a generic optional pattern suggestion, not a failing word. Adding a commit-specific pattern file would create unrelated spelling-policy churn. |

### Manual PR Metadata

The public PR metadata no longer describes removed generic `AllowOnce` interception. At
`48e9af996`, its title matches the reviewed title and its body lists the four native mappings plus
provider-owned sandbox/file/network effects. The body still omits the explicit no-auto-selection,
custom-agent, terminal-action confirmation and acknowledgement/lifecycle paragraphs. The correct
online account should replace it with the complete reviewed text below; anonymous APIs cannot edit
it.

Title: `Add provider-native Yolo mode for ACP sessions`

Body:

> ## Summary
>
> Adds a persistent global Yolo default and per-session `/yolo on|off` overrides for ACP
> sessions, gated by the `AllowYoloMode` policy.
>
> WTA invokes only reviewed provider-advertised session capabilities: Copilot `allow_all`,
> Claude `bypassPermissions`, Codex `agent-full-access`, and Gemini `yolo`. OpenCode and custom
> agents remain interactive unless they advertise a supported reversible capability. Provider
> modes may also change sandbox, file, or network access according to the provider contract.
>
> WTA never selects `AllowOnce`, `AllowAlways`, or another ACP permission option for the user.
> Valid permission requests continue through the normal permission UI. Product-owned terminal
> action proposals remain confirmation-gated.
>
> `/yolo` commits only after the provider acknowledges the session update. Runtime setting and
> policy changes reconcile live sessions; session replacement, `/new`, tab cleanup, and restart
> fence stale operations and overrides.
>
> Validation includes provider/lifecycle/race tests, localized Settings and slash-command text,
> exact-package zero-token E2E, and local-only real-provider tool acceptance.
>
> Closes #326

### Complete Thread Audit

The public PR page was expanded manually and audited as `55` inline discussion nodes plus
`19` suppressed-comment sections. Reply/permalink duplicates and per-locale repetitions reduce
to the root causes below; every discussion remains represented by its ID or review group.

| Root cause / thread IDs | Current disposition |
|---|---|
| Silent auto-approval notification design: `r3662232687`, `r3662232714`, `r3662232731` and suppressed review `4793603196` | **SUPERSEDED / DECLINE** — generic permission auto-approval and its dead notification strings were removed. Current Yolo never answers permission requests. |
| Broad or malformed selector discovery: `r3662680891`, `r3759014877`, `r3860103416`, `r3860103457`, `r3870054038`, `r3870054092` and matching suppressed findings | **ALREADY FIXED** — exact built-in identity, ID/category/Select kind, required enable/default values, and duplicate-entry tests are present. |
| Native lifecycle and ordering: `r3758743284`, `r3773626475`, `r3780443288`, `r3811389274`; suppressed reviews `4907511063`, `4914901379` | **ALREADY FIXED** — acknowledged transactions, provider-native-only behavior, load-session discovery, sequencing, runtime reconciliation, teardown cleanup and reused-ID fencing are covered. The remaining generation-map retention item is tracked separately above. |
| Metadata/GPO/Settings resources/spec drift: `r3765534766`, `r3662828737` and repeated suppressed reviews `4907185847` through `4970157754` | **ALREADY FIXED** — merged `_meta.wta`, ADMX/ADML, all SettingsEditor resource sets and corrected spec text are present. Lock-token accuracy is tracked separately. |
| PR metadata mismatch: `r3860103472`, `r3870054128`, `r3870421333`, `r3871506332` | **PARTLY FIXED MANUALLY** — title and provider-native mappings/effects are current; apply the remaining reviewed security/lifecycle paragraphs using the correct online account, with no auth automation. |
| WTA locale translation and stale `/yolo` lock: `r3860103495`, `r3860103523`, `r3870054166`, `r3870421473`, `r3870421515`, `r3870424896`, `r3870424950`, `r3870424998`, `r3870425050`, `r3870425096`; suppressed reviews `5038786971`, `5039214710`, `5040513075` | **FIX** — one root cause across all real locale catalogs; pseudo-locales remain pseudo-localized. |
| SettingsEditor lock comments: `r3860103542` and suppressed review `5027284503` | **FIX** — Header locks only `Yolo`; HelpText locks only `ACP`. |
| Publishable E2E readiness/claims: `r3870054212`, `r3870054244`, `r3870421389`, `r3870421429`; latest suppressed persistence finding | **FIX / PARTLY SUPERSEDED** — real-provider matrix was removed from publish/CI; strengthen the remaining zero-token Copilot persistence, authentication and policy cases. |
| Spelling discussions `r3870037690`, `r3870037712` | **FIX** — reword ordinary prose rather than adding a dictionary exception. |
| Final long-`USERPROFILE` comment `r3871506390` | **FIX** — dynamically sized WIL read plus >`MAX_PATH` unit coverage. |

Post-fix status: all known findings through `8b9d63a40` are fixed, independently reviewed,
validated and pushed. Exact package and zero-token behavior are GREEN at `c96b1d66d`, with only
unprovisioned C292 skipped. Real-provider evidence at parent `8b9d63a40` passes four providers;
Gemini is externally blocked by a reproducible provider hang also seen without WTA. Local,
remote-tracking and `ls-remote` identities are all `c96b1d66d`; next request/wait for a Copilot
review of that exact commit before further product edits.

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
| Publish build receipt | Publish `.local-tdd-kit-run/artifacts/build-receipt.json` | Source/recipe/staged/installed/live identity | `ef899419e`; freshness `18/18` |
| RED unit reports | Not captured | Each race/lifecycle failure | Unverified |
| Packaged E2E report | Publish untracked `.local-tdd-kit-run/artifacts/zero-token-yolo-ef899419e-rerun/` | Zero-token Settings/slash/policy/package-selection workflow | `ef899419e`; PASS `4`, FAIL `0`, C292 skip `1` |
| GREEN screenshots | Not captured | Reviewable UI states | Unverified |
| Real provider receipts | `local-tdd-kit/artifacts/yolo-mode/real-user-yolo-8b9d63a40/` | Native mode/tool/chat outcomes and cleanup | `8b9d63a40`; Copilot, Claude, Codex and OpenCode pass; Gemini first run fails |
| Gemini external-provider diagnosis | `local-tdd-kit/artifacts/yolo-mode/direct-gemini-8b9d63a40/diagnosis.json` | Native ACK precedes prompt; two ACP runs and one direct Gemini run fail to complete | `8b9d63a40`; `BLOCKED_EXTERNAL_PROVIDER`, Gemini `0.51.0` |
| Settings recovery | `local-tdd-kit/artifacts/yolo-mode/settings-recovery-20260827/` | Damaged snapshot, evidence and semantic restoration | Recovered Copilot/home settings; no temp path/backups |

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
- [ ] Latest `origin/main@d59731c9` is audited but not merged; merging it requires complete revalidation.
- [x] GPO templates and SettingsEditor locale parity are complete and structurally validated.
- [ ] Hamza/design/security decisions are recorded for terminology, provider-native scope and command-approval messaging.
- [x] Publishable and dev-only changes remain separated; `AGENTS.md`/`local-tdd-kit` stay dev-only.
- [x] Exact publish HEAD 已 build/deploy，source/deployed hashes 一致。
- [x] Packaged/deployed E2E 对 exact publish binary GREEN。
- [x] 真实外部依赖验收已完成，或明确标记 blocked。
- [ ] UI/渲染/交互的 fresh screenshots 已逐图检查并记录 provenance。
- [x] Review findings 已逐条 triage，accepted fixes 有 RED/GREEN evidence。
- [ ] Evidence inventory 能映射全部 user-visible assertions。
- [x] Publish remote HEAD is pushed and confirmed (`ef899419e`); dev-only evidence remains local.

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
