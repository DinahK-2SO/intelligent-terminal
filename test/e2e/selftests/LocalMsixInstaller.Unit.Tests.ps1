#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

Describe 'Local MSIX installer build script' -Tag Unit {
    BeforeAll {
        $script:repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
        $script:scriptPath = Join-Path $script:repoRoot 'build\scripts\New-LocalMsixInstaller.ps1'
    }

    It 'exists as a tracked build script' {
        $script:scriptPath | Should -Exist
    }

    It 'derives the version and x64 paths without machine-specific installation paths' {
        $plan = & $script:scriptPath -Architecture x64 -PlanOnly

        $plan.Version | Should -Match '^\d+\.\d+\.\d+\.\d+$'
        $plan.Architecture | Should -Be 'x64'
        $plan.RustTarget | Should -Be 'x86_64-pc-windows-msvc'
        $plan.ManifestPath | Should -Be (Join-Path $script:repoRoot 'src\cascadia\CascadiaPackage\Package-Dev.appxmanifest')
        $plan.ExpectedMsix | Should -Match 'CascadiaPackage_[^\\]+_x64_Test\\CascadiaPackage_[^\\]+_x64\.msix$'
        $plan.HostProxyProject | Should -Be (Join-Path $script:repoRoot 'src\host\proxy\Host.Proxy.vcxproj')
        ($plan | ConvertTo-Json -Depth 5) | Should -Not -Match 'C:\\Program Files'
    }

    It 'derives ARM64 paths from the same manifest' {
        $plan = & $script:scriptPath -Architecture ARM64 -PlanOnly

        $plan.Architecture | Should -Be 'ARM64'
        $plan.RustTarget | Should -Be 'aarch64-pc-windows-msvc'
        $plan.DependencyArchitecture | Should -Be 'arm64'
    }
}