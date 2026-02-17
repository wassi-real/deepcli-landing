# DeepCLI Install Script for Windows
# One-liner: irm -useb https://deepcli.org/install.ps1 | iex
# Alternative: iwr -useb https://deepcli.org/install.ps1 | iex

$ErrorActionPreference = "Stop"
$Version = "0.1.1"
$BaseUrl = "https://deepcli.org/releases/v$Version"
$GitHubBase = "https://github.com/wassi-real/DeepCLI/releases/tag/v$Version"

# Detect architecture
$Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
$AssetName = "deepcli-$Version-windows-$Arch.zip"
$Url = "$BaseUrl/$AssetName"
$FallbackUrl = "$GitHubBase/$AssetName"

# Install directory: $env:LOCALAPPDATA\deepcli
$InstallDir = Join-Path $env:LOCALAPPDATA "deepcli"
$ZipPath = Join-Path $env:TEMP $AssetName

Write-Host "DeepCLI $Version installer" -ForegroundColor Cyan
Write-Host "Architecture: $Arch" -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "Downloading $AssetName..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing -MaximumRedirection 5
    } catch {
        Write-Host "Primary URL failed, trying GitHub Releases..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $FallbackUrl -OutFile $ZipPath -UseBasicParsing -MaximumRedirection 5
    }

    if (-not (Test-Path $ZipPath)) {
        throw "Download failed"
    }

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Host "Extracting to $InstallDir..." -ForegroundColor Yellow
    Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

    # The zip contains deepcli-0.1.1-windows-x86_64/deepcli.exe - move to InstallDir
    $ExtractedDir = Join-Path $InstallDir "deepcli-$Version-windows-$Arch"
    if (Test-Path $ExtractedDir) {
        $ExePath = Join-Path $ExtractedDir "deepcli.exe"
        if (Test-Path $ExePath) {
            Move-Item $ExePath $InstallDir -Force
            Remove-Item $ExtractedDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $DeepcliPath = Join-Path $InstallDir "deepcli.exe"
    if (-not (Test-Path $DeepcliPath)) {
        throw "deepcli.exe not found after extraction"
    }

    # Add to user PATH
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host ""
        Write-Host "Added to PATH: $InstallDir" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Already in PATH: $InstallDir" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "DeepCLI installed successfully!" -ForegroundColor Green
    Write-Host "Open a new terminal and run: deepcli init" -ForegroundColor Cyan
    Write-Host ""

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual install: Download from https://github.com/wassi-real/DeepCLI/releases" -ForegroundColor Yellow
    exit 1
}
