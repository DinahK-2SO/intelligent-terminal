#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$ModelId = 'gpt-5.6-luna',
    [string]$ProxyBaseUrl = 'http://127.0.0.1:23333',
    [string]$AdapterCommand = 'npx -y @agentclientprotocol/claude-agent-acp@0.65.0',
    [string]$WtaPath = 'tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe',
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$resolvedWta = (Resolve-Path (Join-Path $repoRoot $WtaPath)).Path
$realClaudeFiles = @(
    (Join-Path $env:USERPROFILE '.claude/settings.json'),
    (Join-Path $env:USERPROFILE '.claude/config.json'),
    (Join-Path $env:USERPROFILE '.claude.json')
)

function Get-FileIdentity([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return 'absent'
    }
    $item = Get-Item -LiteralPath $Path
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    return "$hash|$($item.Length)|$($item.LastWriteTimeUtc.Ticks)"
}

function Invoke-IsolatedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][hashtable]$Environment,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $ArgumentList) {
        $startInfo.ArgumentList.Add($argument)
    }
    foreach ($entry in $Environment.GetEnumerator()) {
        $startInfo.Environment[$entry.Key] = [string]$entry.Value
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "$FilePath exceeded $TimeoutSeconds seconds and was killed"
    }
    $stopwatch.Stop()

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        DurationMs = $stopwatch.ElapsedMilliseconds
        Stdout = $stdoutTask.Result.Trim()
        Stderr = $stderrTask.Result.Trim()
    }
}

function Resolve-CachedClaudeAdapterCommand {
    $npmCache = (& npm config get cache).Trim()
    $npxRoot = Join-Path $npmCache '_npx'
    if (-not (Test-Path -LiteralPath $npxRoot -PathType Container)) {
        return $null
    }

    foreach ($directory in Get-ChildItem -LiteralPath $npxRoot -Directory) {
        $packageRoot = Join-Path $directory.FullName 'node_modules\@agentclientprotocol\claude-agent-acp'
        $packageJson = Join-Path $packageRoot 'package.json'
        if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) {
            continue
        }
        $metadata = Get-Content -LiteralPath $packageJson -Raw | ConvertFrom-Json
        if ($metadata.version -ne '0.65.0') {
            continue
        }
        $entry = Join-Path $packageRoot 'dist\index.js'
        if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) {
            throw "Cached Claude ACP adapter entry is missing: $entry"
        }
        if ($entry -match '\s') {
            throw "The WTA probe cannot safely parse an adapter path containing whitespace: $entry"
        }
        return "node $entry"
    }
    return $null
}

function Resolve-ClaudeNativeExecutable {
    $command = Get-Command claude -ErrorAction Stop | Select-Object -First 1
    $root = Split-Path $command.Source -Parent
    $candidates = @(
        (Join-Path $root 'claude.exe'),
        (Join-Path $root 'node_modules\@anthropic-ai\claude-code\bin\claude.exe'),
        (Join-Path $root 'node_modules\@anthropic-ai\claude-agent-sdk-win32-x64\claude.exe'),
        (Join-Path $root 'node_modules\@anthropic-ai\claude-code\node_modules\@anthropic-ai\claude-agent-sdk-win32-x64\claude.exe')
    )
    $resolved = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if (-not $resolved) {
        throw "Could not resolve the native Claude executable below $root"
    }
    return $resolved
}

$before = @{}
foreach ($path in $realClaudeFiles) {
    $before[$path] = Get-FileIdentity $path
}

$tempRoot = Join-Path $env:TEMP ('ite2e-maestro-claude-' + [guid]::NewGuid().ToString('N'))
$claudeDir = Join-Path $tempRoot '.claude'

try {
    $modelsResponse = Invoke-RestMethod "$ProxyBaseUrl/api/v1/lm/chatModels" -TimeoutSec 15
    $availableModels = @($modelsResponse | ForEach-Object { $_ })
    $selected = $availableModels | Where-Object id -eq $ModelId | Select-Object -First 1
    if (-not $selected) {
        throw "Maestro model '$ModelId' is unavailable"
    }
    if (-not $selected.capabilities.supportsToolCalling) {
        throw "Maestro model '$ModelId' does not support tool calling"
    }

    $claudeModel = if (
        $ModelId.EndsWith('[1m]') -or
        -not $selected.maxInputTokens -or
        $selected.maxInputTokens -le 800000 -or
        $selected.maxInputTokens -ge 1500000
    ) {
        $ModelId
    } else {
        "$ModelId[1m]"
    }

    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $tempRoot '.claude.json'),
        '{"hasCompletedOnboarding":true}'
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $claudeDir 'config.json'),
        '{"primaryApiKey":"Agent Maestro"}'
    )

    $environment = @{
        HOME = $tempRoot
        USERPROFILE = $tempRoot
        CLAUDE_CONFIG_DIR = $claudeDir
        CLAUDE_CODE_EXECUTABLE = Resolve-ClaudeNativeExecutable
        NPM_CONFIG_CACHE = (Join-Path $tempRoot 'npm-cache')
        ANTHROPIC_BASE_URL = "$ProxyBaseUrl/api/anthropic"
        ANTHROPIC_AUTH_TOKEN = 'Powered by Agent Maestro'
        ANTHROPIC_MODEL = $claudeModel
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = [string]$selected.maxInputTokens
        CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = '85'
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'
        CLAUDE_CODE_ATTRIBUTION_HEADER = '0'
    }

    $effectiveAdapterCommand = Resolve-CachedClaudeAdapterCommand
    if (-not $effectiveAdapterCommand) {
        $effectiveAdapterCommand = $AdapterCommand
    }

    $probe = Invoke-IsolatedProcess `
        -FilePath $resolvedWta `
        -ArgumentList @('probe-models', '--agent', $effectiveAdapterCommand) `
        -Environment $environment `
        -TimeoutSeconds $TimeoutSeconds
    if ($probe.ExitCode -ne 0) {
        $tail = ($probe.Stderr -split "`r?`n" | Select-Object -Last 12) -join "`n"
        throw "Claude ACP probe failed with exit code $($probe.ExitCode):`n$tail"
    }

    $payload = $probe.Stdout | ConvertFrom-Json
    if ($payload.current_model_id -ne $claudeModel) {
        throw "Claude ACP selected '$($payload.current_model_id)', expected '$claudeModel'"
    }

    $after = @{}
    foreach ($path in $realClaudeFiles) {
        $after[$path] = Get-FileIdentity $path
    }
    $changed = @($realClaudeFiles | Where-Object { $before[$_] -ne $after[$_] })
    if ($changed.Count -ne 0) {
        throw "Isolated probe modified real Claude configuration: $($changed -join ', ')"
    }

    [pscustomobject]@{
        Status = 'PASS'
        Adapter = $AdapterCommand
        Model = $payload.current_model_id
        AvailableModelCount = @($payload.available_models).Count
        DurationMs = $probe.DurationMs
        UserClaudeConfigUnchanged = $true
    }
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}