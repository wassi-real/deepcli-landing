# DeepCLI Install Script for Windows
# One-liner: irm -useb https://deepcli.org/install.ps1 | iex
# Alternative: iwr -useb https://deepcli.org/install.ps1 | iex

$ErrorActionPreference = "Stop"
$Version = "0.1.1"
$AssetName = "DeepCLI-$Version.zip"
$BaseUrl = "https://deepcli.org/releases/v$Version"
$GitHubUrl = "https://github.com/wassi-real/DeepCLI/releases/download/v$Version/$AssetName"

# Install directory: $env:LOCALAPPDATA\deepcli
$InstallDir = Join-Path $env:LOCALAPPDATA "deepcli"
$ZipPath = Join-Path $env:TEMP $AssetName

Write-Host "DeepCLI $Version installer" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "Downloading $AssetName..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "$BaseUrl/$AssetName" -OutFile $ZipPath -UseBasicParsing -MaximumRedirection 5
    } catch {
        Write-Host "Trying GitHub Releases..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $GitHubUrl -OutFile $ZipPath -UseBasicParsing -MaximumRedirection 5
    }

    if (-not (Test-Path $ZipPath)) {
        throw "Download failed"
    }

    # Validate zip (avoid extracting HTML error pages)
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    if ($bytes.Length -lt 100 -or $bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
        throw "Downloaded file is not a valid zip (got $($bytes.Length) bytes). Check if release exists: https://github.com/wassi-real/DeepCLI/releases"
    }

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Host "Extracting to $InstallDir..." -ForegroundColor Yellow
    $ExtractTo = Join-Path $env:TEMP "deepcli-extract"
    if (Test-Path $ExtractTo) { Remove-Item $ExtractTo -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractTo -Force
    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

    # Find deepcli.exe (could be at root or in a subfolder like DeepCLI-0.1.1/)
    $ExePath = Get-ChildItem -Path $ExtractTo -Filter "deepcli.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($ExePath) {
        Copy-Item $ExePath $InstallDir -Force
    }
    Remove-Item $ExtractTo -Recurse -Force -ErrorAction SilentlyContinue

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
