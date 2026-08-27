#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $script:fingerprintScript = (Resolve-Path (Join-Path $PSScriptRoot '..\Get-LocalTddSourceFingerprint.ps1')).Path
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
}