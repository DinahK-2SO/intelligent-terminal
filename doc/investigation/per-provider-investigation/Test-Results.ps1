Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$plan = @(& (Join-Path $PSScriptRoot 'Invoke-Providers.ps1') -PlanOnly)
$resultDirectory = Join-Path $PSScriptRoot 'result'
if (-not (Test-Path -LiteralPath $resultDirectory -PathType Container)) {
    throw "Missing result directory: $resultDirectory"
}

$files = @(Get-ChildItem -LiteralPath $resultDirectory -File -Filter '*.json')
if ($files.Count -ne $plan.Count) {
    throw "Expected $($plan.Count) JSON results, got $($files.Count)."
}

foreach ($entry in $plan) {
    if (-not (Test-Path -LiteralPath $entry.output -PathType Leaf)) {
        throw "Missing $($entry.provider) result: $($entry.output)"
    }
    $raw = Get-Content -LiteralPath $entry.output -Raw
    if ($raw -match '(?i)authorization|access_token|refresh_token|api_key|client_secret|bearer\s') {
        throw "$($entry.provider) result contains a credential-like field."
    }
    $result = $raw | ConvertFrom-Json -Depth 100
    if ($result.provider -ne $entry.provider) { throw "Provider mismatch in $($entry.output)." }
    if ($result.command -ne $entry.command) { throw "Command mismatch in $($entry.output)." }
    if (-not $result.PSObject.Properties['model'] -or $result.model -ne $entry.model) {
        throw "Model mismatch in $($entry.output)."
    }
    if ($result.question -ne $entry.question) { throw "Question mismatch in $($entry.output)." }
    foreach ($field in 'initialize', 'newSession', 'sessionUpdates', 'promptResponse', 'answer') {
        if (-not $result.PSObject.Properties[$field]) {
            throw "Missing $field in $($entry.output)."
        }
    }
    if ([string]$result.answer -notmatch '(?<!\d)42(?!\d)') {
        throw "$($entry.provider) answer does not contain 42: $($result.answer)"
    }
    if (-not $result.promptResponse.PSObject.Properties['stopReason']) {
        throw "Missing prompt stopReason in $($entry.output)."
    }
}

'Per-provider ACP results: PASS'