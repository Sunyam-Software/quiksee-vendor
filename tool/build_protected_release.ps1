

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$symbols = Join-Path $root "build\symbols"
New-Item -ItemType Directory -Force -Path $symbols | Out-Null

Write-Host "Building obfuscated release APK..."
flutter build apk --release --obfuscate --split-debug-info="$symbols"

Write-Host ""
Write-Host "Done. APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Host "Symbols (KEEP PRIVATE): $symbols"
