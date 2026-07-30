[CmdletBinding()]
param(
    [ValidateSet('x64', 'ARM64')]
    [string]$Architecture = 'x64',

    [switch]$SkipRestore,
    [switch]$SkipWtaBuild,
    [switch]$SkipTerminalBuild,
    [switch]$ForceNewCertificate,
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7 or later is required; current host is $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$manifestPath = Join-Path $repoRoot 'src\cascadia\CascadiaPackage\Package-Dev.appxmanifest'
$packageProject = Join-Path $repoRoot 'src\cascadia\CascadiaPackage\CascadiaPackage.wapproj'
$hostProxyProject = Join-Path $repoRoot 'src\host\proxy\Host.Proxy.vcxproj'
$settingsModelProject = Join-Path $repoRoot 'src\cascadia\TerminalSettingsModel\Microsoft.Terminal.Settings.ModelLib.vcxproj'
$settingsEditorProject = Join-Path $repoRoot 'src\cascadia\TerminalSettingsEditor\Microsoft.Terminal.Settings.Editor.vcxproj'
$wtaManifest = Join-Path $repoRoot 'tools\wta\Cargo.toml'
$buildModule = Join-Path $repoRoot 'tools\OpenConsole.psm1'
$certificateScript = Join-Path $repoRoot 'build\scripts\New-DevSigningCert.ps1'
$assembleScript = Join-Path $repoRoot 'build\scripts\assemble-msix-zip.ps1'
$pfxPath = Join-Path $repoRoot 'cert\IntelligentTerminalDev.pfx'
$cerPath = Join-Path $repoRoot 'artifacts\local-installer\IntelligentTerminalDev.cer'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Package manifest not found: $manifestPath"
}

[xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
$identity = $manifest.Package.Identity
$version = [string]$identity.Version
$publisher = [string]$identity.Publisher
$rustTarget = if ($Architecture -eq 'x64') { 'x86_64-pc-windows-msvc' } else { 'aarch64-pc-windows-msvc' }
$dependencyArchitecture = $Architecture.ToLowerInvariant()
$packageOutputDirectory = Join-Path $repoRoot "src\cascadia\CascadiaPackage\AppPackages\CascadiaPackage_${version}_${Architecture}_Test"
$expectedMsix = Join-Path $packageOutputDirectory "CascadiaPackage_${version}_${Architecture}.msix"
$expectedDependency = Join-Path $packageOutputDirectory "Dependencies\$dependencyArchitecture\Microsoft.UI.Xaml.2.8.appx"
$expectedZip = Join-Path $repoRoot "artifacts\local-installer\intelligent-terminal-${version}-$dependencyArchitecture-msix.zip"

$plan = [pscustomobject]@{
    RepoRoot = $repoRoot
    ManifestPath = $manifestPath
    Version = $version
    Publisher = $publisher
    Architecture = $Architecture
    DependencyArchitecture = $dependencyArchitecture
    RustTarget = $rustTarget
    ExpectedMsix = $expectedMsix
    ExpectedDependency = $expectedDependency
    ExpectedZip = $expectedZip
    HostProxyProject = $hostProxyProject
}

if ($PlanOnly) {
    return $plan
}

function Write-Status {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[local-msix] $Message" -ForegroundColor Cyan
}

function Invoke-NativeStep {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )

    Write-Status $Name
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}

function Get-WindowsSdkRoot {
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'
    )
    foreach ($registryPath in $registryPaths) {
        try {
            $root = Get-ItemPropertyValue -Path $registryPath -Name KitsRoot10 -ErrorAction Stop
            if ($root -and (Test-Path -LiteralPath $root -PathType Container)) {
                return [IO.Path]::GetFullPath($root)
            }
        }
        catch {}
    }
    if ($env:WindowsSdkDir -and (Test-Path -LiteralPath $env:WindowsSdkDir -PathType Container)) {
        return [IO.Path]::GetFullPath($env:WindowsSdkDir)
    }
    throw 'Windows 10/11 SDK not found. Install a Windows SDK with the x64 metadata and signing tools.'
}

function Find-WindowsSdkTool {
    param([Parameter(Mandatory)][string]$Name)

    $sdkRoot = Get-WindowsSdkRoot
    $candidates = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'bin') -Directory -ErrorAction Stop |
        ForEach-Object {
            $versionValue = $null
            if ([version]::TryParse($_.Name, [ref]$versionValue)) {
                $path = Join-Path $_.FullName "x64\$Name"
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    [pscustomobject]@{ Version = $versionValue; Path = $path }
                }
            }
        } |
        Sort-Object Version -Descending
    $tool = $candidates | Select-Object -First 1
    if (-not $tool) {
        throw "$Name was not found under the installed Windows SDK: $sdkRoot"
    }
    $tool.Path
}

function ConvertTo-ShortDirectoryPath {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $short = (cmd.exe /d /c "for %I in (`"$resolved`") do @echo %~sI").Trim()
    if (-not $short) {
        throw "Could not resolve a command-safe path for '$resolved'."
    }
    $short.TrimEnd('\') + '\'
}

function Ensure-SigningCertificate {
    if ($ForceNewCertificate) {
        Remove-Item -LiteralPath $pfxPath, $cerPath -Force -ErrorAction SilentlyContinue
    }

    if ((Test-Path -LiteralPath $pfxPath -PathType Leaf) -and
        -not (Test-Path -LiteralPath $cerPath -PathType Leaf)) {
        Write-Status 'Exporting the public CER from the existing PFX'
        $pfxCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $pfxPath,
            '',
            [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        New-Item -ItemType Directory -Path (Split-Path $cerPath -Parent) -Force | Out-Null
        [IO.File]::WriteAllBytes(
            $cerPath,
            $pfxCertificate.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    }

    if (-not (Test-Path -LiteralPath $pfxPath -PathType Leaf) -and
        (Test-Path -LiteralPath $cerPath -PathType Leaf)) {
        Write-Status 'Discarding an unmatched public CER before generating a new certificate pair'
        Remove-Item -LiteralPath $cerPath -Force
    }

    if (-not (Test-Path -LiteralPath $pfxPath -PathType Leaf)) {
        Write-Status 'Generating a development signing certificate'
        Push-Location $repoRoot
        try {
            & $certificateScript -Subject $publisher
            if ($LASTEXITCODE -ne 0) {
                throw "Certificate generation failed with exit code $LASTEXITCODE."
            }
        }
        finally {
            Pop-Location
        }
    }

    $pfxCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $pfxPath,
        '',
        [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $cerCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($cerPath)
    if ($pfxCertificate.Subject -ne $publisher) {
        throw "Signing certificate subject '$($pfxCertificate.Subject)' does not match manifest publisher '$publisher'."
    }
    if ($pfxCertificate.Thumbprint -ne $cerCertificate.Thumbprint) {
        throw 'The PFX and public CER do not represent the same certificate.'
    }
    if ($pfxCertificate.NotAfter -le (Get-Date)) {
        throw 'The development signing certificate has expired. Use -ForceNewCertificate to create a new pair.'
    }
    $pfxCertificate
}

function Find-XamlDependency {
    $candidate = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'packages') -Directory -Filter 'Microsoft.UI.Xaml.*' -ErrorAction Stop |
        Sort-Object Name -Descending |
        ForEach-Object {
            $path = Join-Path $_.FullName "tools\AppX\$dependencyArchitecture\Release\Microsoft.UI.Xaml.2.8.appx"
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                Get-Item -LiteralPath $path
            }
        } |
        Select-Object -First 1
    if (-not $candidate) {
        throw "The Microsoft.UI.Xaml $dependencyArchitecture dependency was not found under packages. Run NuGet restore first."
    }
    $candidate.FullName
}

$requiredFiles = @(
    $packageProject,
    $hostProxyProject,
    $settingsModelProject,
    $settingsEditorProject,
    $wtaManifest,
    $buildModule,
    $certificateScript,
    $assembleScript
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required repository file not found: $requiredFile"
    }
}

$cargo = Get-Command cargo.exe -ErrorAction SilentlyContinue
if (-not $cargo) {
    $cargo = Get-Command cargo -ErrorAction SilentlyContinue
}
if (-not $cargo) {
    throw 'Cargo was not found on PATH. Install Rust before building the local MSIX installer.'
}

Import-Module $buildModule -Force
Set-MsBuildDevEnvironment
$msbuild = (Get-Command msbuild.exe -ErrorAction Stop).Source
$mdMerge = Find-WindowsSdkTool -Name 'mdmerge.exe'
$signTool = Find-WindowsSdkTool -Name 'signtool.exe'
$mdMergePath = ConvertTo-ShortDirectoryPath -Path (Split-Path $mdMerge -Parent)
if (-not (Test-Path -LiteralPath (Join-Path $mdMergePath 'mdmerge.exe') -PathType Leaf)) {
    throw "The command-safe mdmerge path is invalid: $mdMergePath"
}

Write-Status "Version $version, architecture $Architecture"
Write-Status "MSBuild: $msbuild"
Write-Status "Windows SDK metadata tools: $mdMergePath"

if (-not $SkipRestore) {
    $nuget = Join-Path $repoRoot 'dep\nuget\nuget.exe'
    if (-not (Test-Path -LiteralPath $nuget -PathType Leaf)) {
        throw "NuGet executable not found: $nuget"
    }
    Invoke-NativeStep -Name 'Restoring solution NuGet packages' -FilePath $nuget -ArgumentList @(
        'restore', (Join-Path $repoRoot 'OpenConsole.slnx')
    )
    Invoke-NativeStep -Name 'Restoring dependency packages' -FilePath $nuget -ArgumentList @(
        'restore', (Join-Path $repoRoot 'dep\nuget\packages.config')
    )
}

if (-not $SkipWtaBuild) {
    Invoke-NativeStep -Name 'Building release WTA' -FilePath $cargo.Source -ArgumentList @(
        'build', '--release', '--target', $rustTarget, '--manifest-path', $wtaManifest
    )
}
$wtaPath = Join-Path $repoRoot "tools\wta\target\$rustTarget\release\wta.exe"
if (-not (Test-Path -LiteralPath $wtaPath -PathType Leaf)) {
    throw "Release WTA not found: $wtaPath"
}

$certificate = Ensure-SigningCertificate

if (-not $SkipTerminalBuild) {
    Write-Status 'Cleaning package intermediates'
    Remove-Item -LiteralPath (Join-Path $repoRoot "src\cascadia\CascadiaPackage\obj\$Architecture\Release") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $repoRoot "src\cascadia\CascadiaPackage\bin\$Architecture\Release\AppX") -Recurse -Force -ErrorAction SilentlyContinue

    $encodedExecutablePath = ("$mdMergePath;$env:PATH") -replace ';', '%3B'
    $commonArguments = @(
        "/p:Platform=$Architecture",
        '/p:Configuration=Release',
        '/p:WindowsTerminalBranding=Dev',
        "/p:SolutionDir=$repoRoot\",
        "/p:OpenConsoleDir=$repoRoot\",
        "/p:MdMergePath=$mdMergePath",
        "/p:WindowsSDK_ExecutablePath=$mdMergePath",
        "/p:ExecutablePath=$encodedExecutablePath",
        '/p:AppxPackageSigningEnabled=false',
        '/p:AppxSymbolPackageEnabled=false',
        '/m',
        '/nodeReuse:false',
        '/verbosity:minimal',
        '/nologo'
    )
    $hostProxyArguments = @($hostProxyProject) + $commonArguments
    $settingsModelArguments = @($settingsModelProject) + $commonArguments
    $settingsEditorArguments = @($settingsEditorProject) + $commonArguments
    $packageArguments = @($packageProject) + $commonArguments + @(
        '/p:GenerateAppxPackageOnBuild=true',
        '/p:AppxBundle=Never'
    )
    Invoke-NativeStep -Name 'Building OpenConsoleProxy IDL headers' -FilePath $msbuild -ArgumentList $hostProxyArguments
    Invoke-NativeStep -Name 'Building Settings Model' -FilePath $msbuild -ArgumentList $settingsModelArguments
    Invoke-NativeStep -Name 'Building Settings Editor' -FilePath $msbuild -ArgumentList $settingsEditorArguments
    Invoke-NativeStep -Name 'Building packaged Terminal' -FilePath $msbuild -ArgumentList $packageArguments
}

if (-not (Test-Path -LiteralPath $expectedMsix -PathType Leaf)) {
    throw "Expected MSIX was not produced: $expectedMsix"
}

if (-not (Test-Path -LiteralPath $expectedDependency -PathType Leaf)) {
    Write-Status 'Staging the XAML dependency from restored packages'
    New-Item -ItemType Directory -Path (Split-Path $expectedDependency -Parent) -Force | Out-Null
    Copy-Item -LiteralPath (Find-XamlDependency) -Destination $expectedDependency -Force
}

Invoke-NativeStep -Name 'Signing the MSIX' -FilePath $signTool -ArgumentList @(
    'sign', '/fd', 'SHA256', '/f', $pfxPath, $expectedMsix
)

$signature = Get-AuthenticodeSignature -LiteralPath $expectedMsix
if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) {
    throw 'The signed MSIX does not contain the expected development certificate.'
}

Push-Location $repoRoot
try {
    & $assembleScript -Version $version -Arch $Architecture
    if ($LASTEXITCODE -ne 0) {
        throw "MSIX ZIP assembly failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $expectedZip -PathType Leaf)) {
    throw "Expected installer ZIP was not produced: $expectedZip"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($expectedZip)
try {
    $entryNames = @($archive.Entries.FullName)
    foreach ($requiredEntry in @(
            "CascadiaPackage_${version}_${Architecture}.msix",
            'IntelligentTerminalDev.cer',
            'Install-Msix.ps1',
            'Dependencies/Microsoft.UI.Xaml.2.8.appx')) {
        if ($entryNames -notcontains $requiredEntry) {
            throw "Installer ZIP is missing '$requiredEntry'."
        }
    }
    if ($entryNames -match '\.pfx$') {
        throw 'Installer ZIP must never contain the private PFX.'
    }
}
finally {
    $archive.Dispose()
}

$zip = Get-Item -LiteralPath $expectedZip
Write-Status "Created $($zip.FullName)"
[pscustomobject]@{
    Version = $version
    Architecture = $Architecture
    Msix = $expectedMsix
    Zip = $zip.FullName
    ZipBytes = $zip.Length
    ZipSha256 = (Get-FileHash -LiteralPath $zip.FullName -Algorithm SHA256).Hash
    CertificateThumbprint = $certificate.Thumbprint
}