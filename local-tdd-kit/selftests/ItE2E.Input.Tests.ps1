#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\ItE2E\ItE2E.psd1') -Force

    $script:readyPath = Join-Path $TestDrive 'input-probe-ready.json'
    $script:eventPath = Join-Path $TestDrive 'input-probe-events.jsonl'
    $fixture = (Resolve-Path (Join-Path $PSScriptRoot '..\fixtures\Win32InputProbe.ps1')).Path
    $pwsh = (Get-Process -Id $PID).Path
    $script:probe = Start-Process -FilePath $pwsh -ArgumentList @(
        '-NoLogo',
        '-NoProfile',
        '-Sta',
        '-File', "`"$fixture`"",
        '-ReadyPath', "`"$script:readyPath`"",
        '-EventPath', "`"$script:eventPath`""
    ) -PassThru

    $script:ready = Wait-Until -TimeoutSec 15 -IntervalSec 0.1 -Because 'the input probe window to open' -Condition {
        if (Test-Path -LiteralPath $script:readyPath) {
            Get-Content -LiteralPath $script:readyPath -Raw | ConvertFrom-Json
        }
    }
    $script:app = [pscustomobject]@{
        Pid = [int]$script:ready.pid
        Hwnd = [int64]$script:ready.hwnd
    }

    function Reset-ProbeEvents {
        Set-Content -LiteralPath $script:eventPath -Value '' -Encoding utf8
    }

    function Wait-ProbeEvents {
        param([Parameter(Mandatory)][int]$Count)

        Wait-Until -TimeoutSec 5 -IntervalSec 0.05 -Because "$Count input probe event(s)" -Condition {
            $events = @(Get-Content -LiteralPath $script:eventPath -ErrorAction SilentlyContinue |
                    Where-Object { $_.Trim() } |
                    ForEach-Object { $_ | ConvertFrom-Json })
            if ($events.Count -ge $Count) { $events }
        }
    }
}

AfterAll {
    if ($script:probe -and -not $script:probe.HasExited) {
        Stop-Process -Id $script:probe.Id -Force -ErrorAction SilentlyContinue
        $script:probe.WaitForExit(5000) | Out-Null
    }
}

Describe 'Local TDD Win32 input capabilities' -Tag 'Input' {
    It 'binds the HWND to the process started by the test' {
        $identity = Get-WtWindowIdentity -App $script:app

        $identity.Hwnd | Should -Be $script:ready.hwnd
        $identity.ProcessId | Should -Be $script:probe.Id
        $identity.IsVisible | Should -BeTrue
        $identity.ClientWidth | Should -Be $script:ready.clientWidth
        $identity.ClientHeight | Should -Be $script:ready.clientHeight

        $wrongOwner = [pscustomobject]@{ Pid = $script:probe.Id + 1; Hwnd = $script:ready.hwnd }
        { Get-WtWindowIdentity -App $wrongOwner } | Should -Throw '*belongs to process*'
    }

    It 'sends left and right single clicks at client coordinates' {
        foreach ($button in @('Left', 'Right')) {
            Reset-ProbeEvents
            Invoke-WtWindowMouse -App $script:app -X 120 -Y 90 -Button $button -ClickCount 1 | Out-Null
            $events = @(Wait-ProbeEvents -Count 2)

            @($events | Where-Object type -eq 'mouse-down').Count | Should -Be 1
            @($events | Where-Object type -eq 'mouse-up').Count | Should -Be 1
            @($events | Where-Object type -eq 'mouse-down')[0].button | Should -Be $button
            @($events | Where-Object type -eq 'mouse-down')[0].x | Should -BeIn @(119, 120, 121)
            @($events | Where-Object type -eq 'mouse-down')[0].y | Should -BeIn @(89, 90, 91)
        }
    }

    It 'sends left and right double clicks as two complete click pairs' {
        foreach ($button in @('Left', 'Right')) {
            Reset-ProbeEvents
            Invoke-WtWindowMouse -App $script:app -X 180 -Y 130 -Button $button -ClickCount 2 | Out-Null
            $events = @(Wait-ProbeEvents -Count 4)

            @($events | Where-Object type -eq 'mouse-down').Count | Should -Be 2
            @($events | Where-Object type -eq 'mouse-up').Count | Should -Be 2
            @($events | Where-Object type -eq 'mouse-down' | Where-Object button -eq $button).Count | Should -Be 2
        }
    }

    It 'sends named arrow, Enter, and modified key chords to the target window' {
        Reset-ProbeEvents
        Send-WtWindowKeyChord -App $script:app -Chord @('Up', 'Enter', 'Ctrl+Shift+P') | Out-Null
        $events = @(Wait-ProbeEvents -Count 3)
        $downs = @($events | Where-Object type -eq 'key-down')

        $downs.key | Should -Contain 'Up'
        $downs.key | Should -Contain 'Enter'
        $modified = $downs | Where-Object key -eq 'P' | Select-Object -First 1
        $modified.control | Should -BeTrue
        $modified.shift | Should -BeTrue
    }
}