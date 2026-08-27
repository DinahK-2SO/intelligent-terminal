#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$ModelId = 'gpt-5.6-luna',
    [string]$ProxyBaseUrl = 'http://127.0.0.1:23333',
    [string]$AdapterPackage = '@agentclientprotocol/codex-acp@1.1.13',
    [string]$WtaPath = 'tools/wta/target/x86_64-pc-windows-msvc/debug/wta.exe',
    [int]$AdapterInstallTimeoutSeconds = 600,
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$resolvedWta = (Resolve-Path (Join-Path $repoRoot $WtaPath)).Path
$realCodexRoot = Join-Path $env:USERPROFILE '.codex'
$npmRegistry = (& npm config get registry).Trim()
if (-not [Uri]::IsWellFormedUriString($npmRegistry, [UriKind]::Absolute)) {
    throw "Configured npm registry is not an absolute URL: $npmRegistry"
}

function Get-TreeIdentity([string]$Root) {
    $identity = [ordered]@{}
    if (Test-Path -LiteralPath $Root) {
        foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -Force) {
            $relative = [IO.Path]::GetRelativePath($Root, $file.FullName)
            $identity[$relative] = '{0}|{1}|{2}' -f `
                (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash,
                $file.Length,
                $file.LastWriteTimeUtc.Ticks
        }
    }
    return $identity
}

function Compare-TreeIdentity($Before, $After) {
    @($Before.Keys + $After.Keys | Sort-Object -Unique | Where-Object {
        $Before[$_] -ne $After[$_]
    })
}

function Resolve-CodexNativeExecutable {
    $command = Get-Command codex -ErrorAction Stop | Select-Object -First 1
    if ([IO.Path]::GetExtension($command.Source) -ieq '.exe') {
        return $command.Source
    }

    $packageRoot = Join-Path (Split-Path $command.Source -Parent) 'node_modules\@openai\codex'
    $executable = Get-ChildItem -LiteralPath $packageRoot -Filter codex.exe -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object FullName -Match 'vendor[\\/].*windows.*[\\/]bin[\\/]codex\.exe$' |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $executable) {
        throw "Could not resolve the native Codex executable below $packageRoot"
    }
    return $executable
}

function Invoke-IsolatedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][hashtable]$Environment,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
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

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
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

$before = Get-TreeIdentity $realCodexRoot
$tempRoot = Join-Path $env:TEMP ('ite2e-maestro-codex-' + [guid]::NewGuid().ToString('N'))
$codexHome = Join-Path $tempRoot '.codex'
$adapterRoot = Join-Path $tempRoot 'adapter'

try {
    $openApi = Invoke-RestMethod "$ProxyBaseUrl/openapi.json" -TimeoutSec 15
    if (-not $openApi.paths.PSObject.Properties['/api/openai/v1/responses'].Value.post) {
        throw 'Agent Maestro does not advertise the OpenAI Responses endpoint'
    }

    $modelsResponse = Invoke-RestMethod "$ProxyBaseUrl/api/v1/lm/chatModels" -TimeoutSec 15
    $availableModels = @($modelsResponse | ForEach-Object { $_ })
    $selected = $availableModels | Where-Object id -eq $ModelId | Select-Object -First 1
    if (-not $selected) {
        throw "Maestro model '$ModelId' is unavailable"
    }
    if (-not $selected.capabilities.supportsToolCalling) {
        throw "Maestro model '$ModelId' does not support tool calling"
    }

    $codexExecutable = Resolve-CodexNativeExecutable
    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null

    $nodeExecutable = (Get-Command node -ErrorAction Stop | Select-Object -First 1).Source
    $npmCommand = (Get-Command npm.cmd -ErrorAction Stop | Select-Object -First 1).Source
    $npmCli = Join-Path (Split-Path $npmCommand -Parent) 'node_modules\npm\bin\npm-cli.js'
    if (-not (Test-Path -LiteralPath $npmCli -PathType Leaf)) {
        throw "Could not resolve npm-cli.js beside $npmCommand"
    }
    $installEnvironment = @{
        HOME = $tempRoot
        USERPROFILE = $tempRoot
        NPM_CONFIG_CACHE = (Join-Path $tempRoot 'npm-cache')
        NPM_CONFIG_REGISTRY = $npmRegistry
    }
    $install = Invoke-IsolatedProcess `
        -FilePath $nodeExecutable `
        -ArgumentList @(
            $npmCli, 'install', '--prefix', $adapterRoot, '--ignore-scripts',
            '--no-audit', '--no-fund', '--no-package-lock', '--no-save', $AdapterPackage
        ) `
        -Environment $installEnvironment `
        -TimeoutSeconds $AdapterInstallTimeoutSeconds
    if ($install.ExitCode -ne 0) {
        $tail = ($install.Stderr -split "`r?`n" | Select-Object -Last 12) -join "`n"
        $tail = $tail.Replace($tempRoot, '<TEMP>').Replace($env:USERPROFILE, '<USERPROFILE>')
        throw "Codex ACP adapter install failed with exit code $($install.ExitCode):`n$tail"
    }

    $adapterPackageJson = Join-Path $adapterRoot 'node_modules\@agentclientprotocol\codex-acp\package.json'
    $adapterMetadata = Get-Content -LiteralPath $adapterPackageJson -Raw | ConvertFrom-Json
    if ($adapterMetadata.version -ne '1.1.13') {
        throw "Installed Codex ACP adapter '$($adapterMetadata.version)', expected '1.1.13'"
    }
    $adapterEntry = Join-Path (Split-Path $adapterPackageJson -Parent) 'dist\index.js'
    if (-not (Test-Path -LiteralPath $adapterEntry -PathType Leaf)) {
        throw "Codex ACP adapter entry is missing: $adapterEntry"
    }
    if ($adapterEntry -match '\s') {
        throw "The WTA probe cannot safely parse an adapter path containing whitespace: $adapterEntry"
    }
    $adapterCommand = "node $adapterEntry"

    $config = @"
model = "$ModelId"
model_provider = "agent-maestro"
model_context_window = $($selected.maxInputTokens)

[model_providers.agent-maestro]
name = "Agent Maestro"
base_url = "$ProxyBaseUrl/api/openai/v1"
wire_api = "responses"
"@
    [IO.File]::WriteAllText(
        (Join-Path $codexHome 'config.toml'),
        $config.Replace("`r`n", "`n"),
        [Text.UTF8Encoding]::new($false)
    )

    $environment = @{
        HOME = $tempRoot
        USERPROFILE = $tempRoot
        CODEX_HOME = $codexHome
        CODEX_PATH = $codexExecutable
        NPM_CONFIG_CACHE = (Join-Path $tempRoot 'npm-cache')
        OPENAI_API_KEY = 'local-agent-maestro-probe'
    }

    $probe = Invoke-IsolatedProcess `
        -FilePath $resolvedWta `
        -ArgumentList @('probe-models', '--agent', $adapterCommand) `
        -Environment $environment `
        -TimeoutSeconds $TimeoutSeconds
    if ($probe.ExitCode -ne 0) {
        $tail = ($probe.Stderr -split "`r?`n" | Select-Object -Last 12) -join "`n"
        $tail = $tail.Replace($tempRoot, '<TEMP>').Replace($env:USERPROFILE, '<USERPROFILE>')
        throw "Codex ACP probe failed with exit code $($probe.ExitCode):`n$tail"
    }

    $payload = $probe.Stdout | ConvertFrom-Json
    if ($payload.current_model_id -ne $ModelId) {
        throw "Codex ACP selected '$($payload.current_model_id)', expected '$ModelId'"
    }

    $after = Get-TreeIdentity $realCodexRoot
    $changed = Compare-TreeIdentity $before $after
    if ($changed.Count -ne 0) {
        throw "Isolated probe modified real Codex configuration: $($changed -join ', ')"
    }

    [pscustomobject]@{
        Status = 'PASS'
        Adapter = $AdapterPackage
        Model = $payload.current_model_id
        AvailableModelCount = @($payload.available_models).Count
        AdapterInstallDurationMs = $install.DurationMs
        DurationMs = $probe.DurationMs
        UserCodexConfigUnchanged = $true
    }
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}