#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }
# LOCAL DEVELOPMENT ONLY. This suite consumes real provider/model quota and must never be
# copied to test/e2e, cherry-picked to the publish branch, or invoked by CI.

BeforeDiscovery {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $repoRoot 'test\e2e\ItE2E\ItE2E.psd1') -Force
    $script:Ready = $false
    try {
        $null = Resolve-ItApp -Package Dev -ErrorAction Stop
        $script:Ready = Test-WinAppAvailable
    }
    catch {
        $script:Ready = $false
    }
}

Describe 'Local-only simulated real-user Yolo acceptance' -Tag 'LocalRealProvider' -Skip:(-not $script:Ready) {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $repoRoot 'test\e2e\ItE2E\ItE2E.psd1') -Force
        $script:providerWorkRoot = Join-Path $env:TEMP ('ite2e-yolo-real-user-' + [guid]::NewGuid().ToString('N'))
        $script:claudeBlocker = $null
        $script:testClaudeMaestroGpt = {
            try {
                $settingsPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.claude\settings.json'
                if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
                    throw 'Claude settings.json is missing'
                }
                $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
                $baseUrl = [string]$settings.env.ANTHROPIC_BASE_URL
                $model = [string]$settings.env.ANTHROPIC_MODEL
                if ($baseUrl -ne 'http://127.0.0.1:23333/api/anthropic') {
                    throw 'Claude is not configured for the local Agent Maestro Anthropic endpoint'
                }
                if ($model -notmatch '^gpt-.+') {
                    throw 'Claude ANTHROPIC_MODEL is not pinned to a GPT model'
                }
                $modelId = $model -replace '\[1m\]$', ''
                $models = Invoke-RestMethod 'http://127.0.0.1:23333/api/v1/lm/chatModels' -TimeoutSec 15
                $matches = @($models | Where-Object {
                    $_.id -eq $modelId -and
                    $_.vendor -in @('copilot', 'copilotcli') -and
                    $_.capabilities.supportsToolCalling
                })
                if ($matches.Count -eq 0) {
                    throw "Agent Maestro does not advertise tool-capable GitHub Copilot model '$modelId'"
                }
                return $true
            }
            catch {
                $script:claudeBlocker = $_.Exception.Message
                return $false
            }
        }
        $script:assertRenderedTranscriptText = {
            param(
                [Parameter(Mandatory)]$App,
                [Parameter(Mandatory)][string]$PaneSessionId,
                [Parameter(Mandatory)][string]$Pattern,
                [int]$MaxPages = 12,
                [int]$TimeoutSec = 90
            )

            $deadline = (Get-Date).AddSeconds($TimeoutSec)
            do {
                for ($page = 0; $page -le $MaxPages; $page++) {
                    if ((Get-AgentPaneText -App $App -MaxLines 60 -PaneSessionId $PaneSessionId) -match $Pattern) {
                        return $true
                    }
                    if ($page -lt $MaxPages) {
                        Send-AgentKey -App $App -Key PageUp -PaneSessionId $PaneSessionId | Out-Null
                    }
                }
                for ($page = 0; $page -lt $MaxPages; $page++) {
                    Send-AgentKey -App $App -Key PageDown -PaneSessionId $PaneSessionId | Out-Null
                }
            } while ((Get-Date) -lt $deadline)
            return $false
        }
        $script:runProviderYolo = {
            param(
                [Parameter(Mandatory)][string]$Agent,
                [int]$TimeoutSec = 240
            )

            if (-not (Get-Command $Agent -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "BLOCKED: $Agent is not installed"
                return
            }

            $providerRoot = Join-Path $script:providerWorkRoot $Agent
            New-Item -ItemType Directory -Path $providerRoot -Force | Out-Null
            $marker = "YOLO_${Agent}_" + [guid]::NewGuid().ToString('N')
            $file = Join-Path $providerRoot 'result.txt'
            $settings = @{
                acpAgent = $Agent
                'agentPane.yoloMode' = $false
            }
            $geminiTrustPath = $null
            $geminiTrustBackup = $null
            $geminiTrustNewMarker = $null
            $app = $null
            try {
                if ($Agent -eq 'gemini') {
                    $geminiTrustPath = $env:GEMINI_CLI_TRUSTED_FOLDERS_PATH
                    if ([string]::IsNullOrWhiteSpace($geminiTrustPath)) {
                        $geminiTrustPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.gemini\trustedFolders.json'
                    }
                    $geminiTrustBackup = "$geminiTrustPath.ite2ebak"
                    $geminiTrustNewMarker = "$geminiTrustPath.ite2enew"
                    if (Test-Path -LiteralPath $geminiTrustBackup) {
                        Copy-Item -LiteralPath $geminiTrustBackup -Destination $geminiTrustPath -Force
                        Remove-Item -LiteralPath $geminiTrustBackup -Force
                    }
                    if (Test-Path -LiteralPath $geminiTrustNewMarker) {
                        Remove-Item -LiteralPath $geminiTrustPath -Force -ErrorAction SilentlyContinue
                        Remove-Item -LiteralPath $geminiTrustNewMarker -Force
                    }
                    New-Item -ItemType Directory -Path (Split-Path -Parent $geminiTrustPath) -Force | Out-Null
                    if (Test-Path -LiteralPath $geminiTrustPath) {
                        Copy-Item -LiteralPath $geminiTrustPath -Destination $geminiTrustBackup -Force
                        $trustedFolders = Get-Content -LiteralPath $geminiTrustPath -Raw | ConvertFrom-Json -AsHashtable
                    }
                    else {
                        New-Item -ItemType File -Path $geminiTrustNewMarker -Force | Out-Null
                        $trustedFolders = [ordered]@{}
                    }
                    $trustedFolders[$providerRoot] = 'TRUST_FOLDER'
                    $trustedFolders | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $geminiTrustPath -Encoding utf8
                }

                # Agent panes pre-warm during tab creation, before a newly opened shell can
                # report its cwd. Start the initial default profile in the disposable workspace
                # so the first helper and ACP session receive the same directory.
                $configApp = Resolve-ItApp -Package Dev
                $config = Get-WtSettingsObject -App $configApp
                if (-not $config.profiles) {
                    throw 'Terminal settings do not contain a profiles object'
                }
                $defaultProfile = [string]$config.defaultProfile
                $targetProfile = @($config.profiles.list | Where-Object {
                    [string]$_.guid -eq $defaultProfile
                } | Select-Object -First 1)
                if ($targetProfile.Count -eq 1) {
                    $targetProfile[0] | Add-Member -NotePropertyName startingDirectory -NotePropertyValue $providerRoot -Force
                }
                else {
                    if (-not $config.profiles.defaults) {
                        $config.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
                    }
                    $config.profiles.defaults | Add-Member -NotePropertyName startingDirectory -NotePropertyValue $providerRoot -Force
                }
                $settings.profiles = $config.profiles

                $app = Start-Terminal -Package Dev -PassFre $true -Settings $settings
                Open-AgentPane -App $app | Out-Null
                Wait-AgentReady -App $app -TimeoutSec $TimeoutSec |
                    Should -BeTrue -Because "$Agent should reach a connected ACP session"
                $shellPane = Get-ActivePane -App $app
                $agentPane = (Wait-NewAgentPaneSession -App $app -OwnerPaneSessionId $shellPane.session_id -TimeoutSec 45).PaneSessionId

                Initialize-LogOffsets -App $app | Out-Null
                Send-AgentPrompt -App $app -PaneSessionId $agentPane -Text '/yolo on' | Out-Null
                Assert-Log -App $app -Name 'wta-main_helper-*.log' `
                    -Pattern 'provider-native Yolo updated for live session.*enabled=true' -TimeoutSec 45

                $prompt = "Use your shell tool to create the exact file `"$file`" containing only `"$marker`". Read it back, then reply with only $marker."
                Send-AgentPrompt -App $app -PaneSessionId $agentPane -Text $prompt | Out-Null
                (Test-Until -TimeoutSec $TimeoutSec -IntervalSec 1 -Condition {
                    (Test-Path -LiteralPath $file) -and
                    ((Get-Content -LiteralPath $file -Raw).Trim() -eq $marker)
                }) | Should -BeTrue -Because "$Agent should complete the real bounded tool task"
                (& $script:assertRenderedTranscriptText -App $app -PaneSessionId $agentPane `
                    -Pattern ([regex]::Escape($marker))) |
                    Should -BeTrue -Because "$Agent should render the exact model response in the chat transcript"

                Initialize-LogOffsets -App $app | Out-Null
                Send-AgentPrompt -App $app -PaneSessionId $agentPane -Text '/yolo off' | Out-Null
                Assert-Log -App $app -Name 'wta-main_helper-*.log' `
                    -Pattern 'provider-native Yolo updated for live session.*enabled=false' -TimeoutSec 45
            }
            finally {
                if ($app) { Stop-Terminal -App $app }
                if ($geminiTrustBackup -and (Test-Path -LiteralPath $geminiTrustBackup)) {
                    Copy-Item -LiteralPath $geminiTrustBackup -Destination $geminiTrustPath -Force
                    Remove-Item -LiteralPath $geminiTrustBackup -Force
                }
                elseif ($geminiTrustNewMarker -and (Test-Path -LiteralPath $geminiTrustNewMarker)) {
                    Remove-Item -LiteralPath $geminiTrustPath -Force -ErrorAction SilentlyContinue
                    Remove-Item -LiteralPath $geminiTrustNewMarker -Force
                }
            }
        }
    }

    AfterAll {
        Remove-Item -LiteralPath $script:providerWorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Copilot completes a real provider-native Yolo tool task' {
        & $script:runProviderYolo -Agent 'copilot'
    }

    It 'Claude ACP with Maestro and GitHub Copilot GPT completes a real Yolo tool task' {
        if (-not (& $script:testClaudeMaestroGpt)) {
            Set-ItResult -Skipped -Because "BLOCKED: $script:claudeBlocker"
            return
        }
        & $script:runProviderYolo -Agent 'claude'
    }

    It 'Codex completes a real provider-native Yolo tool task' {
        & $script:runProviderYolo -Agent 'codex'
    }

    It 'Gemini completes a real provider-native Yolo tool task' {
        & $script:runProviderYolo -Agent 'gemini'
    }

    It 'OpenCode rejects Yolo and remains usable for real chat' {
        if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'BLOCKED: OpenCode is not installed'
            return
        }
        $app = Start-Terminal -Package Dev -PassFre $true -Settings @{ acpAgent = 'opencode' }
        try {
            Open-AgentPane -App $app | Out-Null
            Wait-AgentReady -App $app -TimeoutSec 90 | Should -BeTrue
            $shellPane = Get-ActivePane -App $app
            $agentPane = (Wait-NewAgentPaneSession -App $app -OwnerPaneSessionId $shellPane.session_id -TimeoutSec 30).PaneSessionId
            Send-AgentPrompt -App $app -PaneSessionId $agentPane -Text '/yolo on' | Out-Null
            Assert-AgentPaneText -App $app -PaneSessionId $agentPane `
                -Pattern '(?i)/yolo on: opencode does not support ACP session Yolo mode' -TimeoutSec 30
            Send-AgentPrompt -App $app -PaneSessionId $agentPane -Text 'What is 8 plus 9? Reply with only the number.' | Out-Null
            Assert-AgentPaneText -App $app -PaneSessionId $agentPane -Pattern '\b17\b' -TimeoutSec 150
        }
        finally {
            if ($app) { Stop-Terminal -App $app }
        }
    }
}