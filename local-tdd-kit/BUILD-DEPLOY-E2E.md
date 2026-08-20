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
6. Staged and installed `WindowsTerminal.exe`, `wtcli.exe`, protocol WinMD and
   `resources.pri` hashes match.
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