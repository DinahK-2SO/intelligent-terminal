Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'Invoke-Providers.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Missing capture script: $scriptPath"
}

$plan = @(& $scriptPath -PlanOnly)
$expected = [ordered]@{
    claude = 'npx -y @agentclientprotocol/claude-agent-acp@0.59.0'
    codex = 'npx -y @agentclientprotocol/codex-acp@1.1.2'
    copilot = 'copilot --acp --stdio'
    gemini = 'gemini --acp'
    opencode = 'opencode acp'
}

if ($plan.Count -ne $expected.Count) {
    throw "Expected $($expected.Count) providers, got $($plan.Count)."
}

foreach ($provider in $expected.Keys) {
    $entry = $plan | Where-Object provider -eq $provider
    if (-not $entry) { throw "Missing provider plan: $provider" }
    if ($entry.command -ne $expected[$provider]) {
        throw "Unexpected $provider command: $($entry.command)"
    }
    if ($entry.question -ne 'The answer to life, the universe and everything?') {
        throw "Unexpected $provider question: $($entry.question)"
    }
    if ($entry.output -ne (Join-Path $PSScriptRoot "result\$provider.json")) {
        throw "Unexpected $provider output: $($entry.output)"
    }
    $expectedModel = if ($provider -eq 'opencode') { 'opencode/deepseek-v4-flash-free' } else { $null }
    if ($entry.model -ne $expectedModel) {
        throw "Unexpected $provider model: $($entry.model)"
    }
}

'Per-provider ACP capture contract: PASS'