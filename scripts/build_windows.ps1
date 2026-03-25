# build_windows.ps1
# Automates the ZipLink build process on Windows, handling WSTP linker workarounds.

$ProjectDir = Get-Item .
$LinkDir = Join-Path $ProjectDir "zip_link"
$PacletDir = Join-Path $ProjectDir "ZipLink"
$FakeWstpDir = Join-Path $ProjectDir "fake_wstp"

# 1. Setup WSTP Workaround
Write-Host "Setting up WSTP workaround..." -ForegroundColor Cyan
if (-not (Test-Path $FakeWstpDir)) {
    New-Item -ItemType Directory -Path $FakeWstpDir | Out-Null
}

$WstpSrcDir = "C:\Program Files\Wolfram Research\Wolfram\15.0\SystemFiles\Links\WSTP\DeveloperKit\Windows-x86-64\CompilerAdditions"
if (-not (Test-Path $WstpSrcDir)) {
    Write-Error "WSTP CompilerAdditions not found at $WstpSrcDir"
    exit 1
}

# Copy dynamic import library as 'static' to trick wstp-sys
Copy-Item (Join-Path $WstpSrcDir "wstp64i4.lib") (Join-Path $FakeWstpDir "wstp64i4s.lib") -Force
Copy-Item (Join-Path $WstpSrcDir "wstp.h") (Join-Path $FakeWstpDir "wstp.h") -Force

# 2. Build Rust Library
Write-Host "Building Rust library..." -ForegroundColor Cyan
$env:WSTP_COMPILER_ADDITIONS_DIRECTORY = $FakeWstpDir

Push-Location $LinkDir
cargo build --release --target x86_64-pc-windows-msvc
$CargoResult = $LASTEXITCODE
Pop-Location

if ($CargoResult -ne 0) {
    Write-Error "Cargo build failed!"
    exit 1
}

# 3. Deploy DLL
Write-Host "Deploying DLL to Paclet..." -ForegroundColor Cyan
$OutputDir = Join-Path $PacletDir "LibraryResources\Windows-x86-64"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$SourceDll = Join-Path $LinkDir "target\x86_64-pc-windows-msvc\release\zip_link.dll"
$DestDll = Join-Path $OutputDir "libzip_link.dll"

Copy-Item $SourceDll $DestDll -Force

# 4. Cleanup
Write-Host "Cleaning up..." -ForegroundColor Cyan
Remove-Item -Recurse -Force $FakeWstpDir

Write-Host "Build and Deployment Successful!" -ForegroundColor Green
Write-Host "Deployed to: $DestDll"
