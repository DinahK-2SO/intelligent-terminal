# Build, Deploy, and Freshness for Local E2E

## The Five Layers

1. **Source**: the current Git `HEAD` plus tracked/untracked product edits.
2. **Product outputs**: source-matched `wtcli.exe`, explicit-target Cargo
   `wta.exe`, and C++/WinRT/XAML binaries.
3. **Package staging**: CascadiaPackage flat outputs and the appx recipe source
   map. The recipe maps explicit-target Cargo WTA to package-root `wta.exe` and
   identifies the exact sources for Terminal, `wtcli`, WinMD and resources. The
   loose `AppX` layout is materialized by deployment, not by every package build.
4. **Installed package**: Dev package family `IntelligentTerminal_rd9vj3e6a2mbr`.
5. **Live processes**: `WindowsTerminal.exe`, packaged `wta.exe`, and packaged `wtcli.exe`
   executing from that exact installed layout.

A successful compiler exit proves only layer 2. A trustworthy E2E run proves all
five layers refer to the same source snapshot.

## Product Project Layers

| Changed surface | Focused validation/build | Must package/deploy? |
|---|---|---|
| WTA Rust | explicit-target `cargo test` then `cargo build` | Yes before full packaged E2E; package must contain matching hash |
| Settings model/IDL | SettingsModel tests/project, generated WinMD | Yes |
| Settings editor XAML/resources | TerminalSettingsEditor | Yes |
| TerminalApp C++ | TerminalApp | Yes |
| Terminal protocol or `wtcli` | owning protocol/CLI project | Yes |
| Windows host/window | WindowsTerminal | Yes |
| Static hook/assets/manifests | CascadiaPackage, clean staging when globs change | Yes |
| Pure local test script | focused Pester | No product build unless behavior under test changed |

Focused builds are the fast discriminating check. `CascadiaPackage` is the final
integration build because it gathers all product outputs into the staged AppX.

## Canonical Local Cycle

```powershell
# Builds/tests WTA first, then CascadiaPackage, deploys Dev, writes a receipt,
# and verifies source/artifact/install hashes.
pwsh -File local-tdd-kit/Invoke-BuildDeploy.ps1

# If Dev is currently registered from another worktree, replacement is explicit.
pwsh -File local-tdd-kit/Invoke-BuildDeploy.ps1 -ReplaceExistingDevRegistration

$env:ITE2E_PACKAGE = 'Dev'
pwsh -File local-tdd-kit/Verify-DeploymentFreshness.ps1
Invoke-Pester local-tdd-kit/selftests -Tag Live
```

For an AI-driven or otherwise interruption-sensitive complete cycle, keep all bounded phases in
one durable process:

```powershell
pwsh -File local-tdd-kit/Invoke-LocalTddPipeline.ps1 `
   -E2EPath test/e2e/tests/<Feature>.Tests.ps1
```

The runner atomically replaces `pipeline-state.json` under a unique ignored artifact directory,
so readers never observe partial JSON. Every phase is recorded as `running`, then `passed` or
`failed`, with timestamps, exit code, exact HEAD, hash-protected run-local receipt snapshot and report paths.
After E2E it recomputes the receipt's complete source fingerprint, not only HEAD. If the process disappears while the journal still says
`running`, `Get-LocalTddPipelineStatus.ps1` reports `interrupted`. A prior build receipt is never
accepted: the shared receipt is moved aside before build, and the new receipt must match the exact
HEAD, current source fingerprint and current build phase.

### Agent/autopilot execution contract

- Build, test, install, package, deploy and E2E are bounded one-shot work. When the available
   terminal tool supports it, an agent must run them through direct synchronous execution with no
   tool timeout, even when they take many minutes. Do not use a short-lived execution subagent or
   async/background mode.
- A tool timeout that returns a terminal ID is a handoff, not completion. The model cannot be
   awakened by process completion after its turn ends. Never say “will continue when complete”
   and end the turn while required work remains.
- Preserve the terminal ID from an unexpected handoff. Do not poll, sleep, or start a duplicate
   command. Continue only safe work that does not depend on the result. On the platform's automatic
   completion notification, retrieve the final output with that ID and classify the phase from its
   real exit code before proceeding.
- Treat the handed-off terminal as exclusively owned until its final completion. Do not send a new
   command through a default persistent shell that may reuse it: some runners interrupt the active
   batch with Ctrl+C and expose a `Terminate batch job` prompt. Use read-only tools or a separately
   isolated terminal while waiting. If this prompt appears accidentally, answer `N` and preserve
   the original workflow.
- A handed-off build does not authorize deploy, freshness verification, or tests that consume its
   output. Those dependent phases remain blocked until final output proves a zero exit. Evidence
   review, nearby reads, and documentation may continue while the build runs.
- If background execution is unavoidable, launch the durable pipeline rather than one phase. The
   machine can then finish every remaining phase and journal the outcome only while its process
   survives; host/VS Code cancellation is classified as `interrupted`. A later user/platform turn
   is still required before the model can interpret any outcome.
- Do not bundle expensive phases inside a wrapper that itself has a short wait limit. Either use
   the durable pipeline or execute each phase synchronously and inspect its result before the next.

### Foreground activation and visible flicker

`Invoke-BuildDeploy.ps1 -Launch` starts the Dev package through Explorer. Windows may activate the
new Terminal window, visibly flash or move focus away from VS Code. This does not terminate
`Code.exe`, but it can disrupt foreground-sensitive UI/input tests. Build/deploy without `-Launch`
by default; launch only immediately before a test that needs a live window. The durable pipeline
never passes `-Launch` and lets its E2E suite own launch, PID/HWND and cleanup.

The generated receipt is `local-tdd-kit/artifacts/build-receipt.json` and is ignored.
It records source fingerprint, HEAD, configuration, exact paths and SHA-256 hashes.
Pass `-SourcePaths` to conservatively extend the fingerprint for issue-specific
inputs outside the built-in product/package roots.

For any `-SkipDeploy` run, the receipt proves source, Cargo output and package
staging only (`installVerified=false`). Installed-package and live-process gates
apply only after a Debug deployment. The script always rebuilds CascadiaPackage;
it never certifies reused Terminal staging as fresh.

## Freshness Gates

Before accepting E2E evidence, require all of these:

1. The current source fingerprint equals the build receipt.
2. Current-source `wtcli.exe` is built first and placed before aliases/packages
   on `PATH` while WTA integration tests run.
3. Cargo explicit-target `wta.exe` exists.
4. Cargo, package-output and installed `wta.exe` SHA-256 hashes are identical,
   and the recipe maps package-root `wta.exe` to the explicit-target Cargo path.
5. The installed Dev package `InstallLocation` is this worktree's AppX directory.
6. Every recipe source (`WindowsTerminal.exe`, `wtcli.exe`, protocol WinMD,
   `resources.pri`, and WTA) hashes to the corresponding AppX destination; installed layout
   checks then confirm the registered package points at that exact AppX.
7. Running Terminal/WTA process paths are under that same install location.
8. E2E explicitly selects `Dev`; `Auto` is not acceptable for local-package proof.

## Problems Encountered and Guardrails

### `cargo test` did not refresh the product binary

Cargo test builds test targets. It is not evidence that the package-ready
`wta.exe` was rebuilt. Always run:

```powershell
cargo build --target x86_64-pc-windows-msvc --manifest-path tools/wta/Cargo.toml
```

### WTA tests picked up an old `wtcli.exe`

Hook/integration tests execute `wtcli` from `PATH`. A WindowsApps alias or older
installed package can lack commands present in the current source, causing false
failures such as “arguments were not expected: agent-hook”. Build the focused
`src/tools/wtcli` project first, require its `--help` to advertise the expected
command, and prepend only that output directory while running WTA tests.

### MSBuild silently selected stale WTA

`CascadiaPackage.wapproj` chooses the first existing binary in this order:

1. explicit target + matching profile
2. host target + matching profile
3. explicit target + fallback profile
4. host target + fallback profile

Therefore a stale explicit-target binary wins over a newly built host-target
binary. Always use the explicit target and matching Debug/Release profile.

### New C++ flag with old packaged WTA

Terminal can start a helper with a newly added argument while a stale WTA does
not recognize it; the helper exits immediately. Build WTA first, package second,
then compare hashes before deployment.

### Package staging used `PreserveNewest`

Incremental packaging can leave a stale file when timestamp ordering is
unexpected. Hash comparison is authoritative. If staging differs from Cargo,
remove the staged file or clean the package output and rebuild; never deploy and
hope.

### E2E accidentally selected the Store package

`Auto` prefers Store when both Store and Dev resolve. Store and Dev also have
independent settings/state. Set `ITE2E_PACKAGE=Dev` for local build validation.

### Dev registration pointed at another worktree

Loose Dev packages retain their AppX `InstallLocation`. Building one worktree
does not update a package registered from another. The deployment script refuses
this mismatch unless replacement is explicit and preserves application data.

### Live processes locked package files

Stop only processes whose executable paths are under the exact Dev
`InstallLocation`. Never kill every `WindowsTerminal.exe` or `wta.exe` by name;
that can destroy unrelated sessions or Store instances.

First enumerate and record the exact path and PID. Stop only those explicit PIDs,
then repeat the path-based inventory and require zero remaining processes. Do not
pass unresolved variables, wildcards or process names to a destructive cleanup
command.

### Deployment failed with `resources.pri` mapping error `0x800704C8`

This can be a transient user-mapped-section lock left while the previous Dev
package process is exiting. Inspect Restart Manager or enumerate exact package
process paths before retrying. If no persistent owner remains, retry the same
deployment once; if an owner remains, record its PID/path and stop it only when it
belongs to this test's exact package. Never use `Remove-AppxPackage` to work around
the lock because package removal can destroy LocalState.

### A nonbehavioral source edit invalidated the receipt

The source fingerprint hashes bytes under `SourcePaths`, not compiler semantics.
A code-comment-only edit therefore makes the old receipt stale even when the
runtime behavior is unchanged. Rebuild and run freshness verification from the new
HEAD before claiming an exact-head receipt. Behavioral E2E may reuse the direct
parent only when the diff is demonstrably nonbehavioral and the report explicitly
identifies both the tested parent and the new freshness-only HEAD.

### Full solution failures hid the focused result

The full solution can fail for unrelated SDK/.NET/reference-pack prerequisites.
Use the smallest owning project for RED/GREEN, then build CascadiaPackage for the
packaged acceptance gate. Record unrelated full-build blockers separately.

### Generated WinRT/XAML artifacts were stale or raced

Settings model changes must regenerate their WinMD before consumers; Settings
editor XAML must produce generated headers/XBF before TerminalApp consumes them.
For release installers, use the repository wrappers that prebuild these layers
and clean shared outputs. Do not run x64 and ARM64 release packaging in parallel.

### Deployment began before build completion

Wait for a real zero exit code. A still-running or backgrounded build is not a
successful build, and deploying its previous recipe simply re-registers old code.

### The agent stopped after a background handoff

This is an orchestration failure, not a build result. In observed tool versions, short execution
helpers stopped waiting at about two minutes while leaving the command alive; that duration is
implementation-dependent, not a stable contract. If the agent then ends its turn, the
completion event cannot start another turn. Re-run the bounded workflow synchronously with no
tool timeout, or inspect the durable pipeline journal in the next available turn. If a terminal ID
was returned, retain it, do not poll or sleep, and use the platform's automatic completion
notification to retrieve the final output once. Continue independent evidence or documentation
work while waiting, but never deploy old output or start a dependent phase. Do not claim success
from an old receipt and do not end the task solely because one required validation is still running.

### Logs came from an old process/version

After launch, verify process paths and use the current package-version log
directory. Capture process IDs at test start; do not infer ownership from a
global filename alone.

## Manual Inspection Commands

```powershell
$pkg = Get-AppxPackage | Where-Object PackageFamilyName -eq 'IntelligentTerminal_rd9vj3e6a2mbr'
$pkg | Select-Object PackageFullName, InstallLocation, Version

$cargo = 'tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe'
$staged = 'src/cascadia/CascadiaPackage/bin/x64/Debug/AppX/wta.exe'
$installed = Join-Path $pkg.InstallLocation 'wta.exe'
Get-FileHash $cargo, $staged, $installed -Algorithm SHA256

Get-Process WindowsTerminal,wta -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, Path
```