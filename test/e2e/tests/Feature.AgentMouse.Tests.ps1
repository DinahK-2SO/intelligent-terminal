#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }
# PR #506: mouse input crosses WT/ConPTY into WTA's crossterm event reader.

BeforeDiscovery {
    $script:Ready = [bool](
        (Get-AppxPackage | Where-Object { $_.Name -like '*IntelligentTerminal*' }) -and
        (Get-Command copilot -ErrorAction SilentlyContinue) -and
        (Get-Command winapp -ErrorAction SilentlyContinue)
    )
}

Describe 'Feature: agent pane mouse interactions' -Tag 'Feature' -Skip:(-not $script:Ready) {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\ItE2E\ItE2E.psd1') -Force
        $script:app = Start-Terminal -Package (Get-ItTestPackage) -PassFre $true -Settings @{ acpAgent = 'copilot' }
        $script:shellPane = Get-ActivePane -App $script:app
        foreach ($window in @(Get-WtWindows -App $script:app)) {
            foreach ($pane in @(Get-WtPanes -App $script:app -WindowId $window.window_id)) {
                if ($pane.session_id -ne $script:shellPane.session_id) {
                    Close-WtPane -App $script:app -SessionId $pane.session_id
                }
            }
        }
        Set-WtPaneFocus -App $script:app -SessionId $script:shellPane.session_id
        Wait-Until -TimeoutSec 15 -IntervalSec 0.5 -Because 'one isolated WT window for real-agent acceptance' -Condition {
            @(Get-WtWindows -App $script:app).Count -eq 1
        } | Out-Null
        $windowMarker = "ite2e-agent-mouse-$([guid]::NewGuid().ToString('N'))"
        Invoke-RunCommand -App $script:app -SessionId $script:shellPane.session_id `
            -Command "`$host.UI.RawUI.WindowTitle = '$windowMarker'" | Out-Null
        $targetWindow = Wait-Until -TimeoutSec 10 -IntervalSec 0.25 -Because 'the active agent-mouse window HWND' -Condition {
            Get-WtWindowHwnds -App $script:app | Where-Object { $_.title -eq $windowMarker } | Select-Object -First 1
        }
        $script:app.Hwnd = $targetWindow.hwnd
        Invoke-RunCommand -App $script:app -SessionId $script:shellPane.session_id `
            -Command "`$host.UI.RawUI.WindowTitle = 'PowerShell'" | Out-Null
        Invoke-UiElement -App $script:app -Selector 'AgentToggleButton' -TimeoutSec 8 | Out-Null
        Test-UiElementExists -App $script:app -Selector 'AgentLabelText' -TimeoutSec 15 |
            Should -BeTrue -Because 'the dedicated tab agent pane must be visibly open in the resolved target window'
        $script:realAgentPane = Wait-NewAgentPaneSession -App $script:app `
            -OwnerPaneSessionId $script:shellPane.session_id -TimeoutSec 30
        Invoke-WtCli -App $script:app -Arguments @(
            'focus-pane', '-t', $script:realAgentPane.PaneSessionId
        ) | Out-Null
        Wait-AgentReady -App $script:app -PaneSessionId $script:realAgentPane.PaneSessionId -TimeoutSec 60 |
            Should -BeTrue -Because 'the agent pane must be connected before exercising its TUI'

        function Save-RealAgentWindowCandidates {
            param(
                [Parameter(Mandatory)][string]$EvidenceDir,
                [Parameter(Mandatory)][string]$Stage
            )

            Start-Sleep -Milliseconds 500
            $candidateDir = Join-Path $EvidenceDir 'window-candidates'
            New-Item -ItemType Directory -Force -Path $candidateDir | Out-Null
            $originalHwnd = $script:app.Hwnd
            try {
                $windows = @(Get-WtWindowHwnds -App $script:app |
                        Where-Object { [int]$_.pid -eq [int]$script:app.Pid } |
                        Sort-Object hwnd)
                $windows.Count | Should -BeGreaterOrEqual 1 -Because 'the real-agent run must expose at least one WT window'
                foreach ($window in $windows) {
                    $script:app.Hwnd = $window.hwnd
                    Save-UiScreenshot -App $script:app `
                        -Path (Join-Path $candidateDir "real-$Stage-hwnd-$($window.hwnd).png") | Out-Null
                }
            }
            finally {
                $script:app.Hwnd = $originalHwnd
            }
        }

        function Publish-RealAgentCanonicalScreenshots {
            param([Parameter(Mandatory)][string]$EvidenceDir)

            $stages = @('before-prompt-click', 'after-prompt-click', 'after-prompt-enter', 'after-input-focus')
            $candidateDir = Join-Path $EvidenceDir 'window-candidates'
            $screenshots = @(Get-ChildItem -LiteralPath $candidateDir -Filter 'real-*-hwnd-*.png' -File)
            $candidates = @(
                $screenshots |
                    ForEach-Object {
                        if ($_.Name -match '^real-(.+)-hwnd-(\d+)\.png$') {
                            [pscustomobject]@{
                                Stage = $Matches[1]
                                Hwnd = $Matches[2]
                                Path = $_.FullName
                                Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                            }
                        }
                    } |
                    Group-Object Hwnd |
                    Where-Object {
                        $groupStages = @($_.Group.Stage | Sort-Object -Unique)
                        $groupHashes = @($_.Group.Hash | Sort-Object -Unique)
                        $groupStages.Count -eq $stages.Count -and
                            $groupHashes.Count -eq $stages.Count
                    }
            )
            $candidates.Count | Should -Be 1 -Because 'exactly one WT window must visibly reflect all four real-agent interaction states'

            $selected = $candidates[0].Group
            foreach ($stage in $stages) {
                $source = ($selected | Where-Object Stage -eq $stage).Path
                $destination = Join-Path $EvidenceDir "real-$stage.png"
                Copy-Item -LiteralPath $source -Destination $destination -Force

                Add-Type -AssemblyName System.Drawing.Common
                $bitmap = [System.Drawing.Bitmap]::new($destination)
                try {
                    $sampled = 0
                    $nonBlack = 0
                    for ($y = 0; $y -lt $bitmap.Height; $y += 16) {
                        for ($x = 0; $x -lt $bitmap.Width; $x += 16) {
                            $pixel = $bitmap.GetPixel($x, $y)
                            $sampled++
                            if ([Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B)) -ge 24) {
                                $nonBlack++
                            }
                        }
                    }
                    ($nonBlack / $sampled) | Should -BeGreaterThan 0.01 -Because "the $stage screenshot must show recognizable nonblack product UI"
                }
                finally {
                    $bitmap.Dispose()
                }
            }
            Set-Content -LiteralPath (Join-Path $EvidenceDir 'selected-window.txt') `
                -Value "HWND $($candidates[0].Name)" -Encoding utf8NoBOM
        }
    }

    AfterAll {
        if ($script:app) {
            Stop-Terminal -App $script:app
        }
    }

    BeforeEach {
        Clear-AgentInput -App $script:app | Out-Null
        # One Ctrl+C is safe on an empty input (it only arms pane close), and clears any
        # draft or in-flight turn left by an earlier failed case. Typing below disarms it.
        Send-AgentWin32Key -App $script:app -Vk 0x43 -Sc 0x2E -Uc 3 -Modifiers 0x08 | Out-Null
    }

    It 'Mouse wheel scrolls chat without changing the draft' {
        $id = [guid]::NewGuid().ToString('N')
        $topMarker = "MOUSE_SCROLL_TOP_$id"
        $bottomMarker = "MOUSE_SCROLL_BOTTOM_$id"
        $session = Get-AgentPaneSession -App $script:app -PaneSessionId $script:realAgentPane.PaneSessionId
        $viewportLines = @((
            Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 500
        ) -split "`r?`n")
        $visibleRows = [Math]::Max(1, $viewportLines.Count)
        $visibleColumns = [Math]::Max(
            1,
            [int](($viewportLines | ForEach-Object Length | Measure-Object -Maximum).Maximum)
        )
        # Fill more cells than the measured viewport can display, so this remains
        # deterministic across pane positions, window sizes, and display scales.
        $fillerCount = [Math]::Ceiling(($visibleRows * $visibleColumns * 2) / 'SCROLL_FILLER '.Length)
        $longPrompt = "$topMarker $(('SCROLL_FILLER ' * $fillerCount).Trim()) $bottomMarker"
        Send-AgentPrompt -App $script:app -PaneSessionId $session.PaneSessionId -Text $longPrompt | Out-Null
        $submitted = Test-Until -TimeoutSec 10 -IntervalSec 0.2 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            $stillInInput = $text -match ('(?m)^\s*[│║|]\s*>\s*' + [regex]::Escape($topMarker))
            -not $stillInInput -and (
                $text -match [regex]::Escape($topMarker) -or
                $text -match [regex]::Escape($bottomMarker)
            )
        }
        $submitted | Should -BeTrue -Because 'the long prompt must reach the real chat transcript'

        $before = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        $topVisible = $before -match [regex]::Escape($topMarker)
        $bottomVisible = $before -match [regex]::Escape($bottomMarker)
        ($topVisible -xor $bottomVisible) | Should -BeTrue -Because 'the long prompt must overflow the chat viewport with exactly one end visible'
        $scrollKind = if ($topVisible) { 'ScrollDown' } else { 'ScrollUp' }
        $targetMarker = if ($topVisible) { $bottomMarker } else { $topMarker }

        $draft = "MOUSE_SCROLL_DRAFT_$id"
        Send-AgentPrompt -App $script:app -PaneSessionId $session.PaneSessionId -Text $draft -NoSubmit | Out-Null
        Send-AgentMouseEvent -App $script:app -PaneSessionId $session.PaneSessionId -Kind $scrollKind -Count 12 | Out-Null

        $scrolled = Wait-Until -TimeoutSec 8 -IntervalSec 0.25 -Quiet -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            if ($text -match [regex]::Escape($targetMarker)) { $text }
        }
        $scrolled | Should -Not -BeNullOrEmpty -Because 'mouse-wheel events must move the WTA chat viewport to the hidden end'
        $scrolled | Should -Match ('(?m)^\s*[│║|]\s*>\s*' + [regex]::Escape($draft)) -Because 'scrolling chat must not alter the current input draft'

        Send-AgentWin32Key -App $script:app -PaneSessionId $session.PaneSessionId -Vk 0x43 -Sc 0x2E -Uc 3 -Modifiers 0x08 | Out-Null
        Start-Sleep -Milliseconds 500
        Send-AgentWin32Key -App $script:app -PaneSessionId $session.PaneSessionId -Vk 0x43 -Sc 0x2E -Uc 3 -Modifiers 0x08 | Out-Null
    }

    It 'Mouse selection copies text and clears after copy' {
        $marker = "MOUSE_COPY_$([guid]::NewGuid().ToString('N'))"
        $session = Send-AgentPrompt -App $script:app -Text $marker -NoSubmit
        Start-Sleep -Milliseconds 300

        $capture = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 200
        $lines = $capture -split "`r?`n"
        $hits = @(
            for ($row = 0; $row -lt $lines.Count; $row++) {
                $column = $lines[$row].IndexOf($marker)
                if ($column -ge 0) {
                    [pscustomobject]@{ Row = $row; Column = $column }
                }
            }
        )
        $hits.Count | Should -Be 1 -Because 'the unique draft word must map to one deterministic TUI cell range'

        Set-Clipboard -Value 'mouse-copy-sentinel'
        Send-AgentMouseClick -App $script:app -PaneSessionId $session.PaneSessionId `
            -Column $hits[0].Column -Row $hits[0].Row -Count 2 | Out-Null
        Send-AgentWin32Key -App $script:app -PaneSessionId $session.PaneSessionId -Vk 0x43 -Sc 0x2E -Uc 3 -Modifiers 0x08 | Out-Null

        (Get-Clipboard -Raw) | Should -Be $marker -Because 'Ctrl+C must copy the WTA mouse selection through the OS clipboard'
        $copiedPattern = Get-WtaLocalizedTextRegex -Key 'system.selection_copied'
        if (-not $copiedPattern) { $copiedPattern = '(?i)Copied' }
        Assert-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -Pattern $copiedPattern -TimeoutSec 5

        $sentinel = "MOUSE_COPY_CLEARED_$([guid]::NewGuid().ToString('N'))"
        Set-Clipboard -Value $sentinel
        Send-AgentWin32Key -App $script:app -PaneSessionId $session.PaneSessionId -Vk 0x43 -Sc 0x2E -Uc 3 -Modifiers 0x08 | Out-Null
        (Get-Clipboard -Raw) | Should -Be $sentinel -Because 'copy must clear the selection so Ctrl+C cannot replay stale text'
        (Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 30) |
            Should -Not -Match ('(?m)^\s*[│║|]\s*>\s*' + [regex]::Escape($marker)) -Because 'the next Ctrl+C must resume the normal nonempty-draft clear behavior'
    }

    It 'Real agent completed turn supports prompt-row mouse toggle and input focus recovery' -Tag 'RealAgentCompletedTurnMouse' {
        $id = [guid]::NewGuid().ToString('N')
        $lineOne = "REAL_AGENT_MOUSE_FIRST_$id"
        $reply = "REAL_AGENT_MOUSE_ACK_$id"
        $lineTwo = "Reply with exactly $reply and nothing else."
        $replyPattern = [regex]::Escape($reply)
        $readyPattern = Get-WtaLocalizedTextRegex -Key 'input.placeholder.connected'
        if (-not $readyPattern) {
            $readyPattern = '(?i)Ask anything.*for commands'
        }
        $evidenceDir = if ($env:ITE2E_REAL_AGENT_EVIDENCE_DIR) {
            $env:ITE2E_REAL_AGENT_EVIDENCE_DIR
        }
        else {
            Join-Path $PSScriptRoot '..\artifacts\mouse-interactions\real-agent-current'
        }
        New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

        $session = Get-AgentPaneSession -App $script:app
        Send-AgentPrompt -App $script:app -PaneSessionId $session.PaneSessionId -Text $lineOne -NoSubmit | Out-Null
        Send-AgentShiftEnter -App $script:app -PaneSessionId $session.PaneSessionId | Out-Null
        Send-AgentPrompt -App $script:app -PaneSessionId $session.PaneSessionId -Text $lineTwo -NoSubmit | Out-Null
        Send-AgentKey -App $script:app -PaneSessionId $session.PaneSessionId -Key Enter | Out-Null

        $turnCompleted = Test-Until -TimeoutSec 150 -IntervalSec 0.5 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            $text -match $readyPattern -and
                ([regex]::Matches($text, $replyPattern)).Count -ge 2
        }
        $turnCompleted | Should -BeTrue -Because 'the real Copilot agent must complete the unique turn before final mouse acceptance'

        $completedHeaderPattern = '(?m)^\s*\S+\s*>\s*' + [regex]::Escape($lineOne)
        $completedTurnRendered = Test-Until -TimeoutSec 10 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100) -match $completedHeaderPattern
        }
        $completedTurnRendered | Should -BeTrue -Because 'the real turn must paint its completed-turn triangle before hit-testing'

        $before = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        $beforeLines = $before -split "`r?`n"
        $secondRows = @(
            for ($row = 0; $row -lt $beforeLines.Count; $row++) {
                if ($beforeLines[$row].Contains($lineTwo)) {
                    [pscustomobject]@{ Row = $row; Column = $beforeLines[$row].IndexOf($lineTwo) }
                }
            }
        )
        $secondRows.Count | Should -Be 1 -Because 'the real completed turn must visibly preserve its second prompt row'
        Set-Content -LiteralPath (Join-Path $evidenceDir 'real-before-prompt-click.txt') -Value $before -Encoding utf8NoBOM
        Save-RealAgentWindowCandidates -EvidenceDir $evidenceDir -Stage 'before-prompt-click'

        Send-AgentMouseClick -App $script:app -PaneSessionId $session.PaneSessionId `
            -Column ($secondRows[0].Column + 2) -Row $secondRows[0].Row | Out-Null
        $collapsed = Test-Until -TimeoutSec 8 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            ([regex]::Matches($text, $replyPattern)).Count -eq 1 -and
                $text -match [regex]::Escape($lineOne)
        }
        $afterClick = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        Set-Content -LiteralPath (Join-Path $evidenceDir 'real-after-prompt-click.txt') -Value $afterClick -Encoding utf8NoBOM
        Save-RealAgentWindowCandidates -EvidenceDir $evidenceDir -Stage 'after-prompt-click'
        $collapsed | Should -BeTrue -Because 'clicking the second real prompt row must collapse and select its completed turn'

        Send-AgentKey -App $script:app -PaneSessionId $session.PaneSessionId -Key Enter | Out-Null
        $reexpanded = Test-Until -TimeoutSec 8 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            ([regex]::Matches($text, $replyPattern)).Count -ge 2 -and
                $text -match [regex]::Escape($lineTwo)
        }
        $afterEnter = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        Set-Content -LiteralPath (Join-Path $evidenceDir 'real-after-prompt-enter.txt') -Value $afterEnter -Encoding utf8NoBOM
        Save-RealAgentWindowCandidates -EvidenceDir $evidenceDir -Stage 'after-prompt-enter'
        $reexpanded | Should -BeTrue -Because 'Enter must re-expand the real turn selected by mouse'

        Send-AgentMouseClick -App $script:app -PaneSessionId $session.PaneSessionId `
            -Column ($secondRows[0].Column + 2) -Row $secondRows[0].Row | Out-Null
        $collapsedAgain = Test-Until -TimeoutSec 8 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            ([regex]::Matches($text, $replyPattern)).Count -eq 1
        }
        $collapsedAgain | Should -BeTrue

        $collapsedCapture = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        $collapsedLines = $collapsedCapture -split "`r?`n"
        $inputRows = @(
            for ($row = 0; $row -lt $collapsedLines.Count; $row++) {
                if ($collapsedLines[$row] -match $readyPattern) {
                    [pscustomobject]@{ Row = $row }
                }
            }
        )
        $inputRows.Count | Should -Be 1 -Because 'the real connected input dialog must remain visible after collapse'
        Send-AgentMouseClick -App $script:app -PaneSessionId $session.PaneSessionId -Column 8 -Row $inputRows[0].Row | Out-Null

        $draft = "REAL_AGENT_INPUT_DRAFT_$id"
        Send-AgentPrompt -App $script:app -PaneSessionId $session.PaneSessionId -Text $draft -NoSubmit | Out-Null
        $inputFocused = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
            $text -match ('(?m)^.*>\s*' + [regex]::Escape($draft)) -and
                ([regex]::Matches($text, $replyPattern)).Count -eq 1
        }
        $afterInputFocus = Get-AgentPaneText -App $script:app -PaneSessionId $session.PaneSessionId -MaxLines 100
        Set-Content -LiteralPath (Join-Path $evidenceDir 'real-after-input-focus.txt') -Value $afterInputFocus -Encoding utf8NoBOM
        Save-RealAgentWindowCandidates -EvidenceDir $evidenceDir -Stage 'after-input-focus'
        $inputFocused | Should -BeTrue -Because 'clicking the real input dialog must restore draft input after mouse turn selection'
        Publish-RealAgentCanonicalScreenshots -EvidenceDir $evidenceDir
        Clear-AgentInput -App $script:app -PaneSessionId $session.PaneSessionId | Out-Null
    }
}

BeforeDiscovery {
    $script:TriangleClickReady = [bool](
        (Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq 'IntelligentTerminal_rd9vj3e6a2mbr' }) -and
        (Get-Command pwsh -ErrorAction SilentlyContinue) -and
        (Get-Command winapp -ErrorAction SilentlyContinue)
    )
}

Describe 'Feature: completed-turn triangle mouse click' -Tag 'CompletedTurnMouse' -Skip:(-not $script:TriangleClickReady) {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\ItE2E\ItE2E.psd1') -Force
        $fixtureSource = (Resolve-Path (Join-Path $PSScriptRoot '..\fixtures\Mock-AcpChatAgent.ps1')).Path
        $script:fixtureDir = Join-Path $env:TEMP "ItE2E mouse triangle $([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $script:fixtureDir | Out-Null
        $fixture = Join-Path $script:fixtureDir 'Mock ACP Chat Agent.ps1'
        Copy-Item -LiteralPath $fixtureSource -Destination $fixture
        $script:fixtureLog = Join-Path $script:fixtureDir 'fixture output.log'
        $fixtureInvocation = "& '$($fixture.Replace("'", "''"))' -LogPath '$($script:fixtureLog.Replace("'", "''"))'"
        $encodedInvocation = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($fixtureInvocation))
        $command = "pwsh -NoProfile -EncodedCommand $encodedInvocation"
        $evidencePhase = if ($env:ITE2E_MOUSE_EVIDENCE_PHASE -in @('red', 'green', 'extension-red', 'extension-green')) {
            $env:ITE2E_MOUSE_EVIDENCE_PHASE
        }
        else {
            'current'
        }
        $script:evidenceDir = Join-Path $PSScriptRoot "..\artifacts\mouse-interactions\$evidencePhase"
        New-Item -ItemType Directory -Force -Path $script:evidenceDir | Out-Null

        $script:app = Start-Terminal -Package 'Dev' -PassFre $true -Settings @{
            acpAgent = 'custom:chat-fixture'
            acpCustomCommand = $command
        }
        $shell = Get-ActivePane -App $script:app
        foreach ($window in @(Get-WtWindows -App $script:app)) {
            foreach ($pane in @(Get-WtPanes -App $script:app -WindowId $window.window_id)) {
                if ($pane.session_id -ne $shell.session_id) {
                    Close-WtPane -App $script:app -SessionId $pane.session_id
                }
            }
        }
        Set-WtPaneFocus -App $script:app -SessionId $shell.session_id
        Wait-Until -TimeoutSec 15 -IntervalSec 0.5 -Because 'one isolated WT window for deterministic mouse regression' -Condition {
            @(Get-WtWindows -App $script:app).Count -eq 1
        } | Out-Null
        Open-AgentPane -App $script:app | Out-Null
        $script:agentPane = (Wait-NewAgentPaneSession -App $script:app -OwnerPaneSessionId $shell.session_id -TimeoutSec 30).PaneSessionId
        Wait-AgentReady -App $script:app -PaneSessionId $script:agentPane -TimeoutSec 60 |
            Should -BeTrue -Because 'the deterministic ACP fixture must connect before triangle hit-testing'
    }

    AfterAll {
        if ($script:app) {
            Stop-Terminal -App $script:app
        }
        if ($script:fixtureLog -and (Test-Path -LiteralPath $script:fixtureLog)) {
            Copy-Item -LiteralPath $script:fixtureLog -Destination (Join-Path $script:evidenceDir 'fixture.log') -Force
        }
        if ($script:fixtureDir -and (Test-Path -LiteralPath $script:fixtureDir)) {
            Remove-Item -LiteralPath $script:fixtureDir -Recurse -Force
        }
    }

    It 'Clicking the triangle collapses and re-expands a completed turn' {
        $id = [guid]::NewGuid().ToString('N')
        $prompt = "SCROLL_TURN_00_$id"
        $reply = "ACK_$prompt"
        $replyPattern = [regex]::Escape($reply)
        $readyPattern = Get-WtaLocalizedTextRegex -Key 'input.placeholder.connected'
        if (-not $readyPattern) {
            $readyPattern = '(?i)Ask anything.*for commands'
        }

        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $prompt | Out-Null
        $turnCompleted = Test-Until -TimeoutSec 10 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
            $text -match $replyPattern -and $text -match $readyPattern
        }
        $turnCompleted | Should -BeTrue -Because 'the deterministic turn must complete before its collapsed triangle is clicked'

        $fixturePrompts = @(Get-Content -LiteralPath $script:fixtureLog | Where-Object { $_ -match ('\|prompt\|' + [regex]::Escape($prompt)) })
        $fixturePrompts.Count | Should -Be 1 -Because 'the fixture must receive the setup prompt exactly once'

        $before = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'setup-capture.txt') -Value $before -Encoding utf8NoBOM
        $lines = $before -split "`r?`n"
        $completedRowPattern = '>\s*' + [regex]::Escape($prompt)
        $promptRows = @(
            for ($row = 0; $row -lt $lines.Count; $row++) {
                if ($lines[$row] -match $completedRowPattern) {
                    [pscustomobject]@{ Row = $row; Text = $lines[$row] }
                }
            }
        )
        $promptRows.Count | Should -Be 1 -Because 'the completed-turn header must map to one visible row'
        $triangleColumn = $promptRows[0].Text.Length - $promptRows[0].Text.TrimStart().Length
        $triangleColumn | Should -BeGreaterOrEqual 0 -Because 'the first non-space cell of a completed-turn header is its triangle'
        $before | Should -Match $replyPattern -Because 'expanded turn details must start visible'
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'before-click.txt') -Value $before -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'before-click.png') | Out-Null

        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column $triangleColumn -Row $promptRows[0].Row | Out-Null

        $collapsed = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
            $text -notmatch $replyPattern -and $text -match ('>\s*' + [regex]::Escape($prompt))
        }
        $after = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'after-click.txt') -Value $after -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'after-click.png') | Out-Null
        $collapsed | Should -BeTrue -Because 'clicking only the visible triangle must collapse the completed turn'

        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column $triangleColumn -Row $promptRows[0].Row | Out-Null
        $reexpanded = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
            $text -match $replyPattern -and $text -match ('>\s*' + [regex]::Escape($prompt))
        }
        $reexpanded | Should -BeTrue -Because 'clicking the collapsed triangle must re-expand the same turn'
        $afterReexpand = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'after-reexpand.txt') -Value $afterReexpand -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'after-reexpand.png') | Out-Null

        $prefixColumn = $triangleColumn + 2
        $promptColumn = $triangleColumn + 4
        $rowEndColumn = $promptRows[0].Text.IndexOf($prompt) + $prompt.Length + 8
        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column $rowEndColumn -Row $promptRows[0].Row | Out-Null
        $rowEndCollapsed = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) -notmatch $replyPattern
        }
        $rowEndCollapsed | Should -BeTrue -Because 'clicking unused space at the end of a prompt row must collapse the turn'

        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column $prefixColumn -Row $promptRows[0].Row | Out-Null
        $prefixReexpanded = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) -match $replyPattern
        }
        $prefixReexpanded | Should -BeTrue -Because 'clicking the prompt prefix must re-expand the same turn'

        Send-AgentMouseEvent -App $script:app -PaneSessionId $script:agentPane `
            -Kind Down -Column $triangleColumn -Row $promptRows[0].Row | Out-Null
        Send-AgentMouseEvent -App $script:app -PaneSessionId $script:agentPane `
            -Kind Drag -Column $promptColumn -Row $promptRows[0].Row | Out-Null
        Send-AgentMouseEvent -App $script:app -PaneSessionId $script:agentPane `
            -Kind Up -Column $triangleColumn -Row $promptRows[0].Row | Out-Null
        (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) |
            Should -Match $replyPattern -Because 'dragging from the triangle must remain text selection and not collapse the turn'
    }

    It 'Clicking a multiline prompt row selects and collapses its completed turn' -Tag 'CompletedTurnPromptMouse' {
        $id = [guid]::NewGuid().ToString('N')
        $lineOne = "SCROLL_TURN_00_$id"
        $lineTwo = "MOUSE_INPUT_SECOND_$id"
        $reply = "ACK_$lineOne"
        $replyPattern = [regex]::Escape($reply)
        $readyPattern = Get-WtaLocalizedTextRegex -Key 'input.placeholder.connected'
        if (-not $readyPattern) {
            $readyPattern = '(?i)Ask anything.*for commands'
        }

        Send-AgentKey -App $script:app -PaneSessionId $script:agentPane -Key Escape | Out-Null

        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $lineOne -NoSubmit | Out-Null
        Send-AgentShiftEnter -App $script:app -PaneSessionId $script:agentPane | Out-Null
        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $lineTwo -NoSubmit | Out-Null
        Send-AgentKey -App $script:app -PaneSessionId $script:agentPane -Key Enter | Out-Null

        $turnCompleted = Test-Until -TimeoutSec 10 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
            $text -match $replyPattern -and $text -match $readyPattern
        }
        $turnCompleted | Should -BeTrue -Because 'the multiline deterministic turn must complete before prompt hit-testing'

        $fixturePrompts = @(Get-Content -LiteralPath $script:fixtureLog | Where-Object { $_ -match ('\|prompt\|' + [regex]::Escape($lineOne)) })
        $fixturePrompts.Count | Should -Be 1 -Because 'the fixture must receive the multiline prompt exactly once'

        $before = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        $lines = $before -split "`r?`n"
        $firstRows = @(
            for ($row = 0; $row -lt $lines.Count; $row++) {
                if ($lines[$row] -match ('>\s*' + [regex]::Escape($lineOne))) {
                    [pscustomobject]@{ Row = $row; Column = $lines[$row].IndexOf($lineOne) }
                }
            }
        )
        $secondRows = @(
            for ($row = 0; $row -lt $lines.Count; $row++) {
                if ($lines[$row].Contains($lineTwo)) {
                    [pscustomobject]@{ Row = $row; Column = $lines[$row].IndexOf($lineTwo) }
                }
            }
        )
        $firstRows.Count | Should -Be 1 -Because 'the first prompt line must map to one completed-turn row'
        $secondRows.Count | Should -Be 1 -Because 'the second prompt line must map to one completed-turn row'
        $secondRows[0].Row | Should -BeGreaterThan $firstRows[0].Row -Because 'the prompt must remain visibly multiline after completion'
        $before | Should -Match $replyPattern -Because 'expanded details must be visible before prompt click'
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'before-prompt-click.txt') -Value $before -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'before-prompt-click.png') | Out-Null

        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column ($secondRows[0].Column + 2) -Row $secondRows[0].Row | Out-Null

        $collapsed = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) -notmatch $replyPattern
        }
        $after = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'after-prompt-click.txt') -Value $after -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'after-prompt-click.png') | Out-Null
        $collapsed | Should -BeTrue -Because 'clicking the second rendered prompt line must collapse the completed turn'

        Send-AgentKey -App $script:app -PaneSessionId $script:agentPane -Key Enter | Out-Null
        $reexpanded = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) -match $replyPattern
        }
        $afterEnter = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'after-prompt-enter.txt') -Value $afterEnter -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'after-prompt-enter.png') | Out-Null
        $reexpanded | Should -BeTrue -Because 'Enter must re-expand the completed turn selected by its prompt click'

        $afterEnterLines = $afterEnter -split "`r?`n"
        $reexpandedFirstRow = @(
            for ($row = 0; $row -lt $afterEnterLines.Count; $row++) {
                if ($afterEnterLines[$row] -match ('>\s*' + [regex]::Escape($lineOne))) {
                    [pscustomobject]@{ Row = $row; Text = $afterEnterLines[$row] }
                }
            }
        )
        $reexpandedFirstRow.Count | Should -Be 1
        $rowEndColumn = $reexpandedFirstRow[0].Text.IndexOf($lineOne) + $lineOne.Length + 8
        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane `
            -Column $rowEndColumn -Row $reexpandedFirstRow[0].Row | Out-Null
        $collapsedAgain = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            (Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100) -notmatch $replyPattern
        }
        $collapsedAgain | Should -BeTrue -Because 'row-end whitespace must select and collapse the turn before input focus recovery'

        $collapsedCapture = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        $collapsedLines = $collapsedCapture -split "`r?`n"
        $inputRows = @(
            for ($row = 0; $row -lt $collapsedLines.Count; $row++) {
                if ($collapsedLines[$row] -match $readyPattern) {
                    [pscustomobject]@{ Row = $row; Text = $collapsedLines[$row] }
                }
            }
        )
        $inputRows.Count | Should -Be 1 -Because 'the connected input dialog must expose one visible placeholder row'
        Send-AgentMouseClick -App $script:app -PaneSessionId $script:agentPane -Column 8 -Row $inputRows[0].Row | Out-Null

        $draft = "INPUT_FOCUS_DRAFT_$id"
        Send-AgentPrompt -App $script:app -PaneSessionId $script:agentPane -Text $draft -NoSubmit | Out-Null
        $inputFocused = Test-Until -TimeoutSec 5 -IntervalSec 0.25 -Condition {
            $text = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
            $text -match ('(?m)^.*>\s*' + [regex]::Escape($draft)) -and $text -notmatch $replyPattern
        }
        $afterInputFocus = Get-AgentPaneText -App $script:app -PaneSessionId $script:agentPane -MaxLines 100
        Set-Content -LiteralPath (Join-Path $script:evidenceDir 'after-input-focus.txt') -Value $afterInputFocus -Encoding utf8NoBOM
        Save-UiScreenshot -App $script:app -Path (Join-Path $script:evidenceDir 'after-input-focus.png') | Out-Null
        $inputFocused | Should -BeTrue -Because 'clicking the input dialog must clear completed-turn selection and route typing to the current draft'
    }
}
