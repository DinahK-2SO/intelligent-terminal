#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $script:fingerprintScript = (Resolve-Path (Join-Path $PSScriptRoot '..\Get-LocalTddSourceFingerprint.ps1')).Path
    $script:pipelineScript = (Resolve-Path (Join-Path $PSScriptRoot '..\Invoke-LocalTddPipeline.ps1')).Path
    $script:pipelineStatusScript = (Resolve-Path (Join-Path $PSScriptRoot '..\Get-LocalTddPipelineStatus.ps1')).Path
    $script:reportScript = (Resolve-Path (Join-Path $PSScriptRoot '..\Invoke-LocalTddReport.ps1')).Path
}

Describe 'Local TDD source fingerprint' -Tag 'Unit' {
    BeforeEach {
        $script:repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:repo 'src') -Force | Out-Null
        & git -C $script:repo init --quiet
        & git -C $script:repo config user.name 'Local TDD Test'
        & git -C $script:repo config user.email 'local-tdd@example.invalid'
        Set-Content -LiteralPath (Join-Path $script:repo 'src\product.txt') -Value 'baseline' -Encoding utf8
        & git -C $script:repo add src/product.txt
        & git -C $script:repo commit --quiet -m baseline
    }

    It 'is stable for an unchanged source snapshot' {
        $first = & $script:fingerprintScript -RepoRoot $script:repo -SourcePaths src
        $second = & $script:fingerprintScript -RepoRoot $script:repo -SourcePaths src

        $first.Head | Should -Match '^[a-f0-9]{40}$'
        $first.Fingerprint | Should -Match '^[A-F0-9]{64}$'
        $first.Fingerprint | Should -Be $second.Fingerprint
        $first.Dirty | Should -BeFalse
    }

    It 'changes for tracked edits and untracked product inputs' {
        $baseline = & $script:fingerprintScript -RepoRoot $script:repo -SourcePaths src
        Set-Content -LiteralPath (Join-Path $script:repo 'src\product.txt') -Value 'edited' -Encoding utf8
        $edited = & $script:fingerprintScript -RepoRoot $script:repo -SourcePaths src
        Set-Content -LiteralPath (Join-Path $script:repo 'src\new.txt') -Value 'new input' -Encoding utf8
        $untracked = & $script:fingerprintScript -RepoRoot $script:repo -SourcePaths src

        $edited.Fingerprint | Should -Not -Be $baseline.Fingerprint
        $untracked.Fingerprint | Should -Not -Be $edited.Fingerprint
        $edited.Dirty | Should -BeTrue
        $untracked.UntrackedPaths | Should -Contain 'src/new.txt'
    }
}

Describe 'Build-only deployment freshness' -Tag 'Unit' {
    It 'verifies staged artifacts without requiring an installed package' {
        $repo = Join-Path $TestDrive 'build-only-repo'
        New-Item -ItemType Directory -Path (Join-Path $repo 'src') -Force | Out-Null
        & git -C $repo init --quiet
        & git -C $repo config user.name 'Local TDD Test'
        & git -C $repo config user.email 'local-tdd@example.invalid'
        Set-Content -LiteralPath (Join-Path $repo 'src\product.txt') -Value 'baseline' -Encoding utf8
        & git -C $repo add src/product.txt
        & git -C $repo commit --quiet -m baseline

        $cargo = Join-Path $TestDrive 'cargo\wta.exe'
        $appx = Join-Path $TestDrive 'AppX'
        New-Item -ItemType Directory -Path (Split-Path $cargo -Parent), $appx -Force | Out-Null
        Set-Content -LiteralPath $cargo -Value 'same-binary' -Encoding utf8
        Copy-Item -LiteralPath $cargo -Destination (Join-Path $appx 'wta.exe')
        $fingerprint = & $script:fingerprintScript -RepoRoot $repo -SourcePaths src
        $receipt = Join-Path $TestDrive 'build-only-receipt.json'
        @{
            schemaVersion = 1
            gitHead = $fingerprint.Head
            sourceFingerprint = $fingerprint.Fingerprint
            sourcePaths = @('src')
            packageFamily = 'not-installed-for-build-only'
            installVerified = $false
            paths = @{
                cargoWta = $cargo
                stagedWta = Join-Path $appx 'wta.exe'
                appxLayout = $appx
                installedWta = $null
            }
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receipt -Encoding utf8

        $verify = (Resolve-Path (Join-Path $PSScriptRoot '..\Verify-DeploymentFreshness.ps1')).Path
        { & $verify -RepoRoot $repo -ReceiptPath $receipt } | Should -Not -Throw
    }

    It 'rejects a stale non-WTA recipe source in an installed AppX layout' {
        $repo = Join-Path $TestDrive 'installed-recipe-repo'
        New-Item -ItemType Directory -Path (Join-Path $repo 'src') -Force | Out-Null
        & git -C $repo init --quiet
        & git -C $repo config user.name 'Local TDD Test'
        & git -C $repo config user.email 'local-tdd@example.invalid'
        Set-Content -LiteralPath (Join-Path $repo 'src\product.txt') -Value 'baseline' -Encoding utf8
        & git -C $repo add src/product.txt
        & git -C $repo commit --quiet -m baseline

        $appx = Join-Path $TestDrive 'installed-AppX'
        $sources = Join-Path $TestDrive 'recipe-sources'
        New-Item -ItemType Directory -Path $appx, $sources -Force | Out-Null
        $cargo = Join-Path $sources 'wta.exe'
        Set-Content -LiteralPath $cargo -Value 'wta-current' -Encoding utf8
        Copy-Item -LiteralPath $cargo -Destination (Join-Path $appx 'wta.exe')
        foreach ($name in @('WindowsTerminal.exe', 'Microsoft.Terminal.Protocol.winmd', 'resources.pri')) {
            Set-Content -LiteralPath (Join-Path $appx $name) -Value "$name-current" -Encoding utf8
        }
        $sourceWtcli = Join-Path $sources 'wtcli.exe'
        Set-Content -LiteralPath $sourceWtcli -Value 'wtcli-current' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $appx 'wtcli.exe') -Value 'wtcli-stale' -Encoding utf8

        $fingerprint = & $script:fingerprintScript -RepoRoot $repo -SourcePaths src
        $receipt = Join-Path $TestDrive 'installed-recipe-receipt.json'
        @{
            schemaVersion = 1
            gitHead = $fingerprint.Head
            sourceFingerprint = $fingerprint.Fingerprint
            sourcePaths = @('src')
            packageFamily = 'local-tdd-recipe-test'
            installVerified = $true
            paths = @{
                cargoWta = $cargo
                stagedWta = Join-Path $appx 'wta.exe'
                appxLayout = $appx
                installedWta = Join-Path $appx 'wta.exe'
                packageSources = @{ 'wtcli.exe' = $sourceWtcli }
            }
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receipt -Encoding utf8

        $package = [pscustomobject]@{
            PackageFamilyName = 'local-tdd-recipe-test'
            InstallLocation = $appx
        }
        $verify = (Resolve-Path (Join-Path $PSScriptRoot '..\Verify-DeploymentFreshness.ps1')).Path

        { & $verify -RepoRoot $repo -ReceiptPath $receipt -InstalledPackage $package } |
            Should -Throw '*recipe source matches AppX: wtcli.exe*'
    }
}

Describe 'Durable local TDD pipeline state' -Tag 'Unit' {
    BeforeEach {
        $script:repoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
        $script:head = (& git -C $script:repoRoot rev-parse HEAD).Trim()
        $script:caseDir = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:runDir = Join-Path $script:caseDir 'run'
        $script:receipt = Join-Path $script:caseDir 'shared-build-receipt.json'
        $script:buildLog = Join-Path $script:caseDir 'build-invocation.json'
        $script:fakePackageSource = Join-Path $script:caseDir 'recipe-source\fixture.bin'
        $script:fakeAppx = Join-Path $script:caseDir 'AppX'
        New-Item -ItemType Directory -Force -Path $script:caseDir, $script:runDir | Out-Null

        $receiptLiteral = $script:receipt.Replace("'", "''")
        $headLiteral = $script:head.Replace("'", "''")
        $logLiteral = $script:buildLog.Replace("'", "''")
        $repoLiteral = $script:repoRoot.Replace("'", "''")
        $fingerprintLiteral = $script:fingerprintScript.Replace("'", "''")
        $packageSourceLiteral = $script:fakePackageSource.Replace("'", "''")
        $appxLiteral = $script:fakeAppx.Replace("'", "''")
        $script:fakeBuild = Join-Path $script:caseDir 'Fake-Build.ps1'
        @"
[CmdletBinding()]
param(
    [string]`$Configuration,
    [switch]`$SkipWtaTests,
    [switch]`$SkipDeploy,
    [switch]`$ReplaceExistingDevRegistration,
    [switch]`$Launch,
    [string[]]`$SourcePaths
)
@{ Launch = `$Launch.IsPresent; Configuration = `$Configuration } |
    ConvertTo-Json | Set-Content -LiteralPath '$logLiteral' -Encoding utf8
`$effectiveSourcePaths = if (`$SourcePaths) { `$SourcePaths } else { @('local-tdd-kit') }
`$fingerprint = & '$fingerprintLiteral' -RepoRoot '$repoLiteral' -SourcePaths `$effectiveSourcePaths
New-Item -ItemType Directory -Force -Path (Split-Path '$packageSourceLiteral' -Parent), '$appxLiteral' | Out-Null
'fixture artifact' | Set-Content -LiteralPath '$packageSourceLiteral' -Encoding utf8
Copy-Item -LiteralPath '$packageSourceLiteral' -Destination (Join-Path '$appxLiteral' 'fixture.bin')
`$artifactHash = (Get-FileHash -LiteralPath '$packageSourceLiteral' -Algorithm SHA256).Hash
@{
    schemaVersion = 1
    createdUtc = [DateTimeOffset]::UtcNow.ToString('o')
    gitHead = '$headLiteral'
    sourceFingerprint = `$fingerprint.Fingerprint
    sourcePaths = `$effectiveSourcePaths
    installVerified = -not `$SkipDeploy
    hashes = @{
        packageSources = @{ 'fixture.bin' = `$artifactHash }
        appx = @{ 'fixture.bin' = `$artifactHash }
    }
    paths = @{
        packageSources = @{ 'fixture.bin' = '$packageSourceLiteral' }
        appxLayout = '$appxLiteral'
    }
} | ConvertTo-Json | Set-Content -LiteralPath '$receiptLiteral' -Encoding utf8
"@ | Set-Content -LiteralPath $script:fakeBuild -Encoding utf8
    }

    It 'runs build and E2E phases without asking build to launch the UI' {
        @{ gitHead = 'stale'; createdUtc = [DateTimeOffset]::UtcNow.AddHours(-1).ToString('o') } |
            ConvertTo-Json | Set-Content -LiteralPath $script:receipt -Encoding utf8
        $fakeReport = Join-Path $script:caseDir 'Fake-Report.ps1'
        $sharedReceiptLiteral = $script:receipt.Replace("'", "''")
        @"
[CmdletBinding()]
    param([string[]]`$Path, [string[]]`$Tag, [string]`$OutDir)
    New-Item -ItemType Directory -Force -Path `$OutDir | Out-Null
    'fake E2E passed' | Set-Content -LiteralPath (Join-Path `$OutDir 'summary.md') -Encoding utf8
    '<?xml version="1.0"?><test-results total="1" errors="0" failures="0" skipped="0" ignored="0" not-run="0"><test-case name="synthetic" result="Success" success="True" executed="True" /></test-results>' |
        Set-Content -LiteralPath (Join-Path `$OutDir 'results.xml') -Encoding utf8
    'overwritten during E2E' | Set-Content -LiteralPath '$sharedReceiptLiteral' -Encoding utf8
"@ | Set-Content -LiteralPath $fakeReport -Encoding utf8

        $result = & $script:pipelineScript `
            -BuildScript $script:fakeBuild `
            -ReceiptPath $script:receipt `
            -E2ERunner $fakeReport `
            -E2EPath 'synthetic.Tests.ps1' `
            -OutDir $script:runDir

        $result.status | Should -Be 'passed'
        (Get-Content -LiteralPath $script:buildLog -Raw | ConvertFrom-Json).Launch | Should -BeFalse
        $journal = Get-Content -LiteralPath (Join-Path $script:runDir 'pipeline-state.json') -Raw | ConvertFrom-Json
        $journal.status | Should -Be 'passed'
        $journal.phases.name | Should -Be @(
            'preflight',
            'build-deploy-freshness',
            'packaged-e2e',
            'final-source-verification'
        )
        $journal.phases.status | Should -Not -Contain 'running'
        (Test-Path -LiteralPath $journal.e2eReportPath) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $script:runDir 'prior-build-receipt.json')) | Should -BeTrue
        $journal.receiptPath | Should -Be (Join-Path $script:runDir 'build-receipt.json')
        $immutableReceipt = Get-Content -LiteralPath $journal.receiptPath -Raw | ConvertFrom-Json
        $immutableReceipt.gitHead | Should -Be $script:head
        (Get-Content -LiteralPath $script:receipt -Raw) | Should -Match 'overwritten during E2E'
        (Get-Content -LiteralPath $journal.receiptPath -Raw | ConvertFrom-Json).gitHead |
            Should -Be $script:head
        $status = & $script:pipelineStatusScript -JournalPath (Join-Path $script:runDir 'pipeline-state.json') -RequirePassed
        $status.ObservedStatus | Should -Be 'passed'
        @(Get-ChildItem -LiteralPath $script:runDir -Filter '*.tmp').Count | Should -Be 0
    }

    It 'persists a failed phase instead of leaving a stale success' {
        $failingBuild = Join-Path $script:caseDir 'Failing-Build.ps1'
        @'
[CmdletBinding()]
param(
    [string]$Configuration,
    [switch]$SkipWtaTests,
    [switch]$SkipDeploy,
    [switch]$ReplaceExistingDevRegistration,
    [string[]]$SourcePaths
)
throw 'synthetic build failure'
'@ | Set-Content -LiteralPath $failingBuild -Encoding utf8

        { & $script:pipelineScript -BuildScript $failingBuild -ReceiptPath $script:receipt -OutDir $script:runDir } |
            Should -Throw '*synthetic build failure*'

        $journal = Get-Content -LiteralPath (Join-Path $script:runDir 'pipeline-state.json') -Raw | ConvertFrom-Json
        $journal.status | Should -Be 'failed'
        $journal.currentPhase | Should -Be 'build-deploy-freshness'
        $journal.phases[-1].status | Should -Be 'failed'
        $journal.error | Should -Match 'synthetic build failure'
    }

    It 'fails final verification when product source changes during E2E' {
        $sourceProbe = Join-Path $script:repoRoot "local-tdd-kit\pipeline-source-$([guid]::NewGuid().ToString('N')).txt"
        $sourceProbeLiteral = $sourceProbe.Replace("'", "''")
        $fakeReport = Join-Path $script:caseDir 'Mutating-Report.ps1'
        @"
[CmdletBinding()]
param([string[]]`$Path, [string[]]`$Tag, [string]`$OutDir)
New-Item -ItemType Directory -Force -Path `$OutDir | Out-Null
'changed during E2E' | Set-Content -LiteralPath '$sourceProbeLiteral' -Encoding utf8
'fake E2E passed' | Set-Content -LiteralPath (Join-Path `$OutDir 'summary.md') -Encoding utf8
'<?xml version="1.0"?><test-results total="1" errors="0" failures="0" skipped="0" ignored="0" not-run="0"><test-case name="synthetic" result="Success" success="True" executed="True" /></test-results>' |
    Set-Content -LiteralPath (Join-Path `$OutDir 'results.xml') -Encoding utf8
"@ | Set-Content -LiteralPath $fakeReport -Encoding utf8
        'before E2E' | Set-Content -LiteralPath $sourceProbe -Encoding utf8

        try {
            {
                & $script:pipelineScript `
                    -BuildScript $script:fakeBuild `
                    -ReceiptPath $script:receipt `
                    -E2ERunner $fakeReport `
                    -E2EPath 'synthetic.Tests.ps1' `
                    -OutDir $script:runDir
            } | Should -Throw '*Source fingerprint changed after build*'

            $journal = Get-Content -LiteralPath (Join-Path $script:runDir 'pipeline-state.json') -Raw | ConvertFrom-Json
            $journal.status | Should -Be 'failed'
            $journal.currentPhase | Should -Be 'final-source-verification'
            $journal.phases[-1].status | Should -Be 'failed'
        }
        finally {
            Remove-Item -LiteralPath $sourceProbe -Force -ErrorAction SilentlyContinue
        }
    }

    It 'records a child E2E failure and restores the package selector' {
        $fakeReport = Join-Path $script:caseDir 'Failing-Report.ps1'
        @'
[CmdletBinding()]
param([string[]]$Path, [string[]]$Tag, [string]$OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
'fake E2E failed' | Set-Content -LiteralPath (Join-Path $OutDir 'summary.md') -Encoding utf8
exit 7
'@ | Set-Content -LiteralPath $fakeReport -Encoding utf8
        $priorSelector = $env:ITE2E_PACKAGE
        $env:ITE2E_PACKAGE = 'sentinel-before-pipeline'
        try {
            {
                & $script:pipelineScript `
                    -BuildScript $script:fakeBuild `
                    -ReceiptPath $script:receipt `
                    -E2ERunner $fakeReport `
                    -E2EPath 'synthetic.Tests.ps1' `
                    -OutDir $script:runDir
            } | Should -Throw "*E2E runner failed with exit code 7*"

            $env:ITE2E_PACKAGE | Should -Be 'sentinel-before-pipeline'
            $journal = Get-Content -LiteralPath (Join-Path $script:runDir 'pipeline-state.json') -Raw | ConvertFrom-Json
            $journal.status | Should -Be 'failed'
            $journal.currentPhase | Should -Be 'packaged-e2e'
            $journal.phases[-1].exitCode | Should -Be 7
        }
        finally {
            $env:ITE2E_PACKAGE = $priorSelector
        }
    }

    It 'rejects a reused output directory before accepting stale evidence' {
        'stale summary' | Set-Content -LiteralPath (Join-Path $script:runDir 'summary.md') -Encoding utf8

        {
            & $script:pipelineScript `
                -BuildScript $script:fakeBuild `
                -ReceiptPath $script:receipt `
                -OutDir $script:runDir
        } | Should -Throw '*output directory must be new or empty*'

        (Test-Path -LiteralPath (Join-Path $script:runDir 'pipeline-state.json')) | Should -BeFalse
    }

    It 'rejects an E2E runner that reports zero tests' {
        $zeroReport = Join-Path $script:caseDir 'Zero-Report.ps1'
        @'
[CmdletBinding()]
param([string[]]$Path, [string[]]$Tag, [string]$OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
'no tests' | Set-Content -LiteralPath (Join-Path $OutDir 'summary.md') -Encoding utf8
'<?xml version="1.0"?><test-results total="0" errors="0" failures="0" skipped="0" ignored="0" not-run="0" />' |
    Set-Content -LiteralPath (Join-Path $OutDir 'results.xml') -Encoding utf8
'@ | Set-Content -LiteralPath $zeroReport -Encoding utf8

        {
            & $script:pipelineScript `
                -BuildScript $script:fakeBuild `
                -ReceiptPath $script:receipt `
                -E2ERunner $zeroReport `
                -E2EPath 'synthetic.Tests.ps1' `
                -OutDir $script:runDir
        } | Should -Throw '*produced no passing tests*'

        $journal = Get-Content -LiteralPath (Join-Path $script:runDir 'pipeline-state.json') -Raw | ConvertFrom-Json
        $journal.status | Should -Be 'failed'
        $journal.currentPhase | Should -Be 'packaged-e2e'
    }

    It 'rejects an E2E run whose only test is inconclusive' {
        $inconclusiveReport = Join-Path $script:caseDir 'Inconclusive-Report.ps1'
        @'
[CmdletBinding()]
param([string[]]$Path, [string[]]$Tag, [string]$OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
'inconclusive' | Set-Content -LiteralPath (Join-Path $OutDir 'summary.md') -Encoding utf8
'<?xml version="1.0"?><test-results total="1" errors="0" failures="0" skipped="0" ignored="0" not-run="0" inconclusive="1"><test-case name="synthetic" result="Inconclusive" success="False" executed="True" /></test-results>' |
    Set-Content -LiteralPath (Join-Path $OutDir 'results.xml') -Encoding utf8
'@ | Set-Content -LiteralPath $inconclusiveReport -Encoding utf8

        {
            & $script:pipelineScript `
                -BuildScript $script:fakeBuild `
                -ReceiptPath $script:receipt `
                -E2ERunner $inconclusiveReport `
                -E2EPath 'synthetic.Tests.ps1' `
                -OutDir $script:runDir
        } | Should -Throw '*produced no passing tests*'
    }

    It 'rejects mixed passing and inconclusive E2E outcomes' {
        $mixedReport = Join-Path $script:caseDir 'Mixed-Report.ps1'
        @'
[CmdletBinding()]
param([string[]]$Path, [string[]]$Tag, [string]$OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
'mixed' | Set-Content -LiteralPath (Join-Path $OutDir 'summary.md') -Encoding utf8
'<?xml version="1.0"?><test-results total="2"><test-case name="pass" result="Success" success="True" executed="True" /><test-case name="unknown" result="Inconclusive" success="False" executed="True" /></test-results>' |
    Set-Content -LiteralPath (Join-Path $OutDir 'results.xml') -Encoding utf8
'@ | Set-Content -LiteralPath $mixedReport -Encoding utf8

        {
            & $script:pipelineScript `
                -BuildScript $script:fakeBuild `
                -ReceiptPath $script:receipt `
                -E2ERunner $mixedReport `
                -E2EPath 'synthetic.Tests.ps1' `
                -OutDir $script:runDir
        } | Should -Throw '*invalid/inconclusive outcome*'
    }

    It 'makes the report runner fail when filters discover zero tests' {
        $reportDir = Join-Path $script:caseDir 'zero-discovery-report'
        & pwsh -NoProfile -File $script:reportScript `
            -Path (Join-Path $PSScriptRoot 'ItE2E.BuildDeploy.Tests.ps1') `
            -Tag 'DefinitelyNoSuchLocalTddTag' `
            -OutDir $reportDir

        $LASTEXITCODE | Should -Be 1
        Get-Content -LiteralPath (Join-Path $reportDir 'summary.md') -Raw |
            Should -Match 'No tests were discovered'
    }

    It 'classifies an abandoned running journal as interrupted' {
        $journalPath = Join-Path $script:runDir 'pipeline-state.json'
        @{
            schemaVersion = 1
            runId = [guid]::NewGuid().ToString('N')
            status = 'running'
            currentPhase = 'build-deploy-freshness'
            processId = [int]::MaxValue
            processStartUtc = [DateTimeOffset]::UtcNow.ToString('o')
            gitHead = $script:head
            sourceFingerprint = $null
            sourcePaths = @()
            startedUtc = [DateTimeOffset]::UtcNow.ToString('o')
            completedUtc = $null
            lastUpdatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
            receiptPath = $script:receipt
            receiptSha256 = $null
            e2eReportPath = $null
            e2eReportSha256 = $null
            e2eResultsPath = $null
            e2eResultsSha256 = $null
            e2eTotals = $null
            error = $null
            invocation = @{ e2ePaths = @() }
            phases = @(@{
                    name = 'build-deploy-freshness'
                    status = 'running'
                    startedUtc = [DateTimeOffset]::UtcNow.ToString('o')
                    completedUtc = $null
                    exitCode = $null
                    error = $null
                })
        } | ConvertTo-Json | Set-Content -LiteralPath $journalPath -Encoding utf8

        $status = & $script:pipelineStatusScript -JournalPath $journalPath
        $status.DeclaredStatus | Should -Be 'running'
        $status.ObservedStatus | Should -Be 'interrupted'
        $status.ProcessMatches | Should -BeFalse
    }

    It 'invalidates a passed journal when its run-local receipt changes' {
        $result = & $script:pipelineScript `
            -BuildScript $script:fakeBuild `
            -ReceiptPath $script:receipt `
            -OutDir $script:runDir
        $result.status | Should -Be 'passed'
        'tampered receipt' | Set-Content -LiteralPath $result.receiptPath -Encoding utf8

        $status = & $script:pipelineStatusScript -JournalPath (Join-Path $script:runDir 'pipeline-state.json')
        $status.ObservedStatus | Should -Be 'invalid'
        $status.ValidationErrors | Should -Contain 'the run-local receipt hash does not match the journal'
    }

    It 'invalidates a passed journal when a packaged artifact changes' {
        $result = & $script:pipelineScript `
            -BuildScript $script:fakeBuild `
            -ReceiptPath $script:receipt `
            -OutDir $script:runDir
        $result.status | Should -Be 'passed'
        'tampered AppX artifact' | Set-Content -LiteralPath (Join-Path $script:fakeAppx 'fixture.bin') -Encoding utf8

        $status = & $script:pipelineStatusScript -JournalPath (Join-Path $script:runDir 'pipeline-state.json')
        $status.ObservedStatus | Should -Be 'invalid'
        $status.ValidationErrors | Should -Contain 'AppX destination changed after validation: fixture.bin'
        $status.ValidationErrors | Should -Contain 'recipe source no longer matches AppX: fixture.bin'
    }

    It 'invalidates a passed journal when its E2E results change' {
        $fakeReport = Join-Path $script:caseDir 'Passing-Report.ps1'
        @'
[CmdletBinding()]
param([string[]]$Path, [string[]]$Tag, [string]$OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
'passed' | Set-Content -LiteralPath (Join-Path $OutDir 'summary.md') -Encoding utf8
'<?xml version="1.0"?><test-results total="1"><test-case name="synthetic" result="Success" success="True" executed="True" /></test-results>' |
    Set-Content -LiteralPath (Join-Path $OutDir 'results.xml') -Encoding utf8
'@ | Set-Content -LiteralPath $fakeReport -Encoding utf8
        $result = & $script:pipelineScript `
            -BuildScript $script:fakeBuild `
            -ReceiptPath $script:receipt `
            -E2ERunner $fakeReport `
            -E2EPath 'synthetic.Tests.ps1' `
            -OutDir $script:runDir
        $result.status | Should -Be 'passed'
        '<?xml version="1.0"?><test-results total="1"><test-case name="synthetic" result="Failure" success="False" executed="True" /></test-results>' |
            Set-Content -LiteralPath $result.e2eResultsPath -Encoding utf8

        $status = & $script:pipelineStatusScript -JournalPath (Join-Path $script:runDir 'pipeline-state.json')
        $status.ObservedStatus | Should -Be 'invalid'
        $status.ValidationErrors | Should -Contain 'the E2E results hash does not match the journal'
        $status.ValidationErrors | Should -Contain 'the E2E result totals do not match the journal'
    }

    It 'classifies a semantically inconsistent passed journal as invalid' {
        $journalPath = Join-Path $script:runDir 'pipeline-state.json'
        @{
            schemaVersion = 1
            runId = [guid]::NewGuid().ToString('N')
            status = 'passed'
            currentPhase = 'packaged-e2e'
            processId = $PID
            processStartUtc = (Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('o')
            gitHead = $script:head
            sourceFingerprint = $null
            sourcePaths = @()
            startedUtc = [DateTimeOffset]::UtcNow.ToString('o')
            completedUtc = $null
            lastUpdatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
            receiptPath = $null
            receiptSha256 = $null
            e2eReportPath = $null
            e2eReportSha256 = $null
            e2eResultsPath = $null
            e2eResultsSha256 = $null
            e2eTotals = $null
            error = $null
            invocation = @{ e2ePaths = @('expected.Tests.ps1') }
            phases = @(@{
                    name = 'packaged-e2e'
                    status = 'running'
                    startedUtc = [DateTimeOffset]::UtcNow.ToString('o')
                    completedUtc = $null
                    exitCode = $null
                    error = $null
                })
        } | ConvertTo-Json | Set-Content -LiteralPath $journalPath -Encoding utf8

        $status = & $script:pipelineStatusScript -JournalPath $journalPath
        $status.ObservedStatus | Should -Be 'invalid'
        $status.ValidationErrors.Count | Should -BeGreaterThan 0
        $status.ValidationErrors | Should -Contain 'passed phase sequence must be: preflight, build-deploy-freshness, packaged-e2e, final-source-verification'
        { & $script:pipelineStatusScript -JournalPath $journalPath -RequirePassed } |
            Should -Throw "*Pipeline is 'invalid', not passed*"
    }
}