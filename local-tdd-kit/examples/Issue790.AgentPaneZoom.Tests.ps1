#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeDiscovery {
    $script:Issue790Ready = [bool](
        (Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq 'IntelligentTerminal_rd9vj3e6a2mbr' }) -and
        (Get-Command pwsh -ErrorAction SilentlyContinue) -and
        (Get-Command winapp -ErrorAction SilentlyContinue)
    )
}

function Get-Issue790TermControlBounds {
    param(
        [Parameter(Mandatory)]$App,
        [switch]$Agent
    )

    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $root = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr][int64]$App.Hwnd)
    $condition = [System.Windows.Automation.PropertyCondition]::new(
        [System.Windows.Automation.AutomationElement]::ClassNameProperty,
        'TermControl')
    $controls = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
    for ($controlIndex = 0; $controlIndex -lt $controls.Count; $controlIndex++) {
        $control = $controls.Item($controlIndex)
        $isAgent = $control.Current.Name -eq 'Agent Pane'
        if ($isAgent -ne $Agent.IsPresent -or $control.Current.IsOffscreen) { continue }
        $rect = $control.Current.BoundingRectangle
        if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
            return [pscustomobject]@{
                ControlName = $control.Current.Name
                Left = [double]$rect.Left
                Top = [double]$rect.Top
                Width = [double]$rect.Width
                Height = [double]$rect.Height
                CenterX = [int][Math]::Round($rect.Left + ($rect.Width / 2))
                CenterY = [int][Math]::Round($rect.Top + ($rect.Height / 2))
            }
        }
    }
    $null
}

function Get-Issue790PaneSize {
    param(
        [Parameter(Mandatory)]$App,
        [Parameter(Mandatory)][string]$SessionId
    )

    Get-WtPanes -App $App |
        Where-Object { "$($_.session_id)".Trim('{}') -eq "$SessionId".Trim('{}') } |
        Select-Object -First 1
}

Describe 'Issue #790: Ctrl+wheel zoom parity' -Tag 'Issue790' -Skip:(-not $script:Issue790Ready) {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\ItE2E\ItE2E.psd1') -Force
        $script:getTermControlBounds = {
            param([Parameter(Mandatory)]$App, [switch]$Agent)

            Add-Type -AssemblyName UIAutomationClient
            Add-Type -AssemblyName UIAutomationTypes
            $root = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr][int64]$App.Hwnd)
            $condition = [System.Windows.Automation.PropertyCondition]::new(
                [System.Windows.Automation.AutomationElement]::ClassNameProperty,
                'TermControl')
            $controls = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
            for ($controlIndex = 0; $controlIndex -lt $controls.Count; $controlIndex++) {
                $control = $controls.Item($controlIndex)
                $isAgent = $control.Current.Name -eq 'Agent Pane'
                if ($isAgent -ne $Agent.IsPresent -or $control.Current.IsOffscreen) { continue }
                $rect = $control.Current.BoundingRectangle
                if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
                    return [pscustomobject]@{
                        ControlName = $control.Current.Name
                        Left = [double]$rect.Left
                        Top = [double]$rect.Top
                        Width = [double]$rect.Width
                        Height = [double]$rect.Height
                        CenterX = [int][Math]::Round($rect.Left + ($rect.Width / 2))
                        CenterY = [int][Math]::Round($rect.Top + ($rect.Height / 2))
                    }
                }
            }
            $null
        }
        $script:getPaneSize = {
            param([Parameter(Mandatory)]$App, [Parameter(Mandatory)][string]$SessionId)

            Get-WtPanes -App $App |
                Where-Object { "$($_.session_id)".Trim('{}') -eq "$SessionId".Trim('{}') } |
                Select-Object -First 1
        }
        $script:getAgentViewport = {
            param([Parameter(Mandatory)]$App, [Parameter(Mandatory)][string]$SessionId)

            $text = Get-AgentPaneText -App $App -PaneSessionId $SessionId -MaxLines 500
            [pscustomobject]@{
                Rows = @(($text -split "`r?`n")).Count
                Text = $text
            }
        }
        $script:evidenceRoot = Join-Path $PSScriptRoot '..\artifacts\issue-790-agent-pane-zoom\baseline-fbe0b12ec'
        $script:screenshotRoot = Join-Path $script:evidenceRoot 'screenshots'
        $script:identityRoot = Join-Path $script:evidenceRoot 'identity'
        New-Item -ItemType Directory -Force -Path $script:screenshotRoot, $script:identityRoot | Out-Null

        $fixture = (Resolve-Path (Join-Path $PSScriptRoot '..\fixtures\Mock-AcpEchoAgent.ps1')).Path
        $invocation = "& '$($fixture.Replace("'", "''"))'"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($invocation))
        $command = "pwsh -NoProfile -EncodedCommand $encoded"
        $script:app = Start-Terminal -Package (Get-ItTestPackage) -PassFre $true -Settings @{
            'experimental.scrollToZoom' = $true
            acpAgent = 'custom:issue-790-echo'
            acpCustomCommand = $command
        }
        $script:shell = Get-ActivePane -App $script:app
        Get-WtWindowIdentity -App $script:app |
            ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath (Join-Path $script:identityRoot 'window.json') -Encoding utf8NoBOM
    }

    AfterAll {
        if ($script:app) { Stop-Terminal -App $script:app }
    }

    It 'Ctrl+wheel zooms an ordinary terminal pane' {
        $marker = "ISSUE790_TERMINAL_$([guid]::NewGuid().ToString('N'))"
        Send-WtInput -App $script:app -SessionId $script:shell.session_id -Text $marker
        $bounds = & $script:getTermControlBounds -App $script:app
        $before = & $script:getPaneSize -App $script:app -SessionId $script:shell.session_id
        $bounds | Should -Not -BeNullOrEmpty -Because 'the ordinary TermControl bounds must be available before input'
        $before | Should -Not -BeNullOrEmpty -Because 'the shell pane size must be queryable before input'
        [pscustomobject]@{ Bounds = $bounds; Pane = $before } | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath (Join-Path $script:identityRoot 'terminal-before.json') -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'terminal-before-ctrl-wheel.png') | Out-Null

        Invoke-WtWindowWheel -App $script:app -ScreenX $bounds.CenterX -ScreenY $bounds.CenterY -Delta 120 -Ctrl | Out-Null
        $after = Wait-Until -TimeoutSec 5 -IntervalSec 0.2 -Quiet -Condition {
            $size = & $script:getPaneSize -App $script:app -SessionId $script:shell.session_id
            if ($size -and $size.size.rows -lt $before.size.rows) { $size }
        }
        $after | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath (Join-Path $script:identityRoot 'terminal-after.json') -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'terminal-after-ctrl-wheel.png') | Out-Null
        $after | Should -Not -BeNullOrEmpty -Because "terminal rows must decrease from $($before.size.rows) after physical Ctrl+wheel"

        Invoke-WtWindowWheel -App $script:app -ScreenX $bounds.CenterX -ScreenY $bounds.CenterY -Delta -120 -Ctrl | Out-Null
        Send-WtKeys -App $script:app -SessionId $script:shell.session_id -Keys @('C-c')
    }

    It 'Plain wheel scrolls agent chat without changing its draft or font size' {
        Open-AgentPane -App $script:app | Out-Null
        $script:agentPane = (Wait-NewAgentPaneSession -App $script:app -OwnerPaneSessionId $script:shell.session_id -TimeoutSec 30).PaneSessionId
        Wait-AgentReady -App $script:app -PaneSessionId $script:agentPane -TimeoutSec 60 |
            Should -BeTrue -Because 'the deterministic local ACP fixture must connect'

        $turns = @()
        foreach ($index in 0..19) {
            $marker = "LOCAL_TDD_PROMPT_$([guid]::NewGuid().ToString('N'))"
            $turns += $marker
            Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $marker | Out-Null
            Assert-AgentPaneText -App $script:app -PaneSessionId $script:agentPane `
                -Pattern ([regex]::Escape("LOCAL_TDD_ECHO:$marker")) -TimeoutSec 10
        }

        $draft = "LOCAL_TDD_PROMPT_$([guid]::NewGuid().ToString('N'))"
        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $draft -NoSubmit | Out-Null
        $bounds = & $script:getTermControlBounds -App $script:app -Agent
        $fontBefore = & $script:getAgentViewport -App $script:app -SessionId $script:agentPane
        $bounds | Should -Not -BeNullOrEmpty
        $fontBefore | Should -Not -BeNullOrEmpty
        $textBefore = $fontBefore.Text
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'agent-before-plain-wheel.png') | Out-Null

        $oldest = $turns[0]
        $delta = if ($textBefore -match [regex]::Escape($oldest)) { -120 } else { 120 }
        Invoke-WtWindowWheel -App $script:app -ScreenX $bounds.CenterX -ScreenY $bounds.CenterY -Delta $delta -Count 24 | Out-Null
        $textAfter = Wait-Until -TimeoutSec 8 -IntervalSec 0.25 -Quiet -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 200
            if ($text -ne $textBefore) { $text }
        }
        $fontAfter = & $script:getAgentViewport -App $script:app -SessionId $script:agentPane
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'agent-after-plain-wheel.png') | Out-Null

        $textAfter | Should -Not -BeNullOrEmpty -Because 'physical plain wheel must move the WTA chat viewport'
        $textAfter | Should -Match ([regex]::Escape($draft)) -Because 'plain wheel must preserve the current draft'
        $fontAfter | Should -Not -BeNullOrEmpty
        $fontAfter.Rows | Should -Be $fontBefore.Rows -Because 'plain wheel must not zoom the agent TermControl'
    }

    It 'Ctrl+wheel zooms the agent pane instead of scrolling chat' {
        $draft = "LOCAL_TDD_PROMPT_$([guid]::NewGuid().ToString('N'))"
        Clear-AgentInput -App $script:app -PaneSessionId $script:agentPane | Out-Null
        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $draft -NoSubmit | Out-Null
        $bounds = & $script:getTermControlBounds -App $script:app -Agent
        $before = & $script:getAgentViewport -App $script:app -SessionId $script:agentPane
        $bounds | Should -Not -BeNullOrEmpty
        $before | Should -Not -BeNullOrEmpty
        [pscustomobject]@{ Bounds = $bounds; Pane = $before } | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath (Join-Path $script:identityRoot 'agent-before.json') -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'agent-before-ctrl-wheel.png') | Out-Null

        Invoke-WtWindowWheel -App $script:app -ScreenX $bounds.CenterX -ScreenY $bounds.CenterY -Delta 120 -Ctrl | Out-Null
        $after = & $script:getAgentViewport -App $script:app -SessionId $script:agentPane
        $after | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath (Join-Path $script:identityRoot 'agent-after.json') -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:screenshotRoot 'agent-after-ctrl-wheel.png') | Out-Null

        $after | Should -Not -BeNullOrEmpty
        $viewportChanged = $after.Text -ne $before.Text
        $after.Rows | Should -BeLessThan $before.Rows -Because "agent rows must decrease from $($before.Rows) after physical Ctrl+wheel; viewportChanged=$viewportChanged"
    }
}
