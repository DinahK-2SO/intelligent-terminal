[CmdletBinding()]
param(
    [ValidateSet('claude', 'codex', 'copilot', 'gemini', 'opencode')]
    [string[]]$Provider = @('claude', 'codex', 'copilot', 'gemini', 'opencode'),
    [string]$Cwd = (Get-Location).Path,
    [int]$TimeoutSeconds = 300,
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$question = 'The answer to life, the universe and everything?'
$commands = [ordered]@{
    claude = 'npx -y @agentclientprotocol/claude-agent-acp@0.59.0'
    codex = 'npx -y @agentclientprotocol/codex-acp@1.1.2'
    copilot = 'copilot --acp --stdio'
    gemini = 'gemini --acp'
    opencode = 'opencode acp'
}
$models = @{ opencode = 'opencode/deepseek-v4-flash-free' }
$resultDirectory = Join-Path $PSScriptRoot 'result'
$plan = @($Provider | ForEach-Object {
        [pscustomobject]@{
            provider = $_
            command = $commands[$_]
            model = $models[$_]
            question = $question
            output = Join-Path $resultDirectory "$_.json"
        }
    })
if ($PlanOnly) { return $plan }

function Invoke-AcpCapture {
    param($Entry)

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $env:ComSpec
    foreach ($argument in @('/d', '/s', '/c', $Entry.command)) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $startInfo.WorkingDirectory = [IO.Path]::GetFullPath($Cwd)
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Failed to start $($Entry.provider)." }
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $messages = [Collections.ArrayList]::new()

    function Send-Message($Message) {
        $line = $Message | ConvertTo-Json -Depth 100 -Compress
        $process.StandardInput.WriteLine($line)
        $process.StandardInput.Flush()
    }

    function Read-Response([int]$Id) {
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while ([DateTime]::UtcNow -lt $deadline) {
            $remaining = [Math]::Max(1, [int]($deadline - [DateTime]::UtcNow).TotalSeconds)
            try {
                $line = $process.StandardOutput.ReadLineAsync().WaitAsync(
                    [TimeSpan]::FromSeconds($remaining)).GetAwaiter().GetResult()
            }
            catch [TimeoutException] {
                throw "Timed out waiting for $($Entry.provider) ACP response id=$Id."
            }
            if ($null -eq $line) { throw "$($Entry.provider) exited before ACP response id=$Id." }
            $message = $line | ConvertFrom-Json -Depth 100
            [void]$messages.Add($message)

            $method = $message.PSObject.Properties['method']
            $messageId = $message.PSObject.Properties['id']
            if ($method -and $messageId) {
                Send-Message @{ jsonrpc = '2.0'; id = $messageId.Value; error = @{
                        code = -32601; message = 'Method not supported by capture client'
                    } }
                continue
            }
            if ($messageId -and [int]$messageId.Value -eq $Id) { return $message }
        }
        throw "Timed out waiting for $($Entry.provider) ACP response id=$Id."
    }

    try {
        Send-Message @{ jsonrpc = '2.0'; id = 1; method = 'initialize'; params = @{
                protocolVersion = 1
                clientCapabilities = @{}
                clientInfo = @{ name = 'intelligent-terminal-provider-investigation'; version = '1.0.0' }
            } }
        $initialize = Read-Response 1
        $error = $initialize.PSObject.Properties['error']
        if ($error) { throw "$($Entry.provider) initialize failed: $($error.Value.message)" }

        Send-Message @{ jsonrpc = '2.0'; id = 2; method = 'session/new'; params = @{
                cwd = [IO.Path]::GetFullPath($Cwd); mcpServers = @()
            } }
        $newSession = Read-Response 2
        $error = $newSession.PSObject.Properties['error']
        if ($error) { throw "$($Entry.provider) session/new failed: $($error.Value.message)" }
        $sessionId = [string]$newSession.result.sessionId

        $modelSelection = $null
        $promptId = 3
        if ($Entry.model) {
            Send-Message @{ jsonrpc = '2.0'; id = 3; method = 'session/set_config_option'; params = @{
                    sessionId = $sessionId; configId = 'model'; value = $Entry.model
                } }
            $modelSelection = Read-Response 3
            $error = $modelSelection.PSObject.Properties['error']
            if ($error) { throw "$($Entry.provider) model selection failed: $($error.Value.message)" }
            $promptId = 4
        }

        Send-Message @{ jsonrpc = '2.0'; id = $promptId; method = 'session/prompt'; params = @{
                sessionId = $sessionId
                prompt = @(@{ type = 'text'; text = $question })
            } }
        $promptResponse = Read-Response $promptId
        $error = $promptResponse.PSObject.Properties['error']
        if ($error) { throw "$($Entry.provider) prompt failed: $($error.Value.message)" }

        $updates = @($messages | Where-Object {
                $_.PSObject.Properties['method'] -and $_.method -eq 'session/update'
            } |
                ForEach-Object { $_.params.update })
        $answer = ($updates | Where-Object {
                $_.PSObject.Properties['sessionUpdate'] -and $_.sessionUpdate -eq 'agent_message_chunk'
            } |
                ForEach-Object { [string]$_.content.text }) -join ''
        $result = [ordered]@{
            provider = $Entry.provider
            command = $Entry.command
            model = $Entry.model
            question = $question
            capturedAt = (Get-Date -Format o)
            initialize = $initialize.result
            newSession = $newSession.result
            modelSelection = if ($modelSelection) { $modelSelection.result } else { $null }
            sessionUpdates = $updates
            promptResponse = $promptResponse.result
            answer = $answer
        }
        $json = $result | ConvertTo-Json -Depth 100
        if ($json -match '(?i)authorization|access_token|refresh_token|api_key|client_secret|bearer\s') {
            throw "$($Entry.provider) result contains a credential-like field; refusing to write it."
        }
        $json | Set-Content -LiteralPath $Entry.output -Encoding utf8
        $result
    }
    finally {
        try { $process.StandardInput.Close() } catch {}
        try { if (-not $process.WaitForExit(2000)) { $process.Kill($true) } } catch {}
        try { [void]$stderrTask.GetAwaiter().GetResult() } catch {}
        $process.Dispose()
    }
}

New-Item -ItemType Directory -Path $resultDirectory -Force | Out-Null
$plan | ForEach-Object { Invoke-AcpCapture $_ }