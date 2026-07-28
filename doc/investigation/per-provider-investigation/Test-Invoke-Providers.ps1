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
$questions = @(
    'The answer to life, the universe and everything?'
    'How can the net amount of entropy of the universe be massively decreased?'
)

if ($plan.Count -ne $expected.Count * $questions.Count) {
    throw "Expected $($expected.Count * $questions.Count) provider turns, got $($plan.Count)."
}

foreach ($provider in $expected.Keys) {
    $entries = @($plan | Where-Object provider -eq $provider | Sort-Object turn)
    if ($entries.Count -ne $questions.Count) { throw "Unexpected $provider turn count." }
    $expectedModel = if ($provider -eq 'opencode') { 'opencode/deepseek-v4-flash-free' } else { $null }
    for ($index = 0; $index -lt $questions.Count; $index++) {
        $entry = $entries[$index]
        if ($entry.command -ne $expected[$provider]) {
            throw "Unexpected $provider command: $($entry.command)"
        }
        if ($entry.turn -ne $index + 1) { throw "Unexpected $provider turn: $($entry.turn)" }
        if ($entry.question -ne $questions[$index]) {
            throw "Unexpected $provider question: $($entry.question)"
        }
        if ($entry.output -ne (Join-Path $PSScriptRoot "result\$provider-$($index + 1).json")) {
            throw "Unexpected $provider output: $($entry.output)"
        }
        if ($entry.model -ne $expectedModel) {
            throw "Unexpected $provider model: $($entry.model)"
        }
    }
}

$cleanupDirectory = Join-Path $env:TEMP "provider-investigation-clean-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $cleanupDirectory -Force | Out-Null
    'stale' | Set-Content -LiteralPath (Join-Path $cleanupDirectory 'summary.md')
    'stale' | Set-Content -LiteralPath (Join-Path $cleanupDirectory 'old.json')
    & $scriptPath -ResultDirectory $cleanupDirectory -CleanOnly
    if (@(Get-ChildItem -LiteralPath $cleanupDirectory -Force).Count -ne 0) {
        throw 'CleanOnly did not empty the result directory.'
    }
}
finally {
    Remove-Item -LiteralPath $cleanupDirectory -Recurse -Force -ErrorAction SilentlyContinue
}

'Per-provider ACP capture contract: PASS'