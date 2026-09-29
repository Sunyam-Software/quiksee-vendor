# Create a password-protected ZIP to share with other developers.
# Requires 7-Zip. You will be prompted for the share password (not stored).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$sevenZip = $null
foreach ($c in @(
  "C:\Program Files\7-Zip\7z.exe",
  "C:\Program Files (x86)\7-Zip\7z.exe"
)) {
  if (Test-Path $c) { $sevenZip = $c; break }
}
if (-not $sevenZip) {
  Write-Host "7-Zip not found. Install from https://www.7-zip.org/ then run again."
  Write-Host "Or manually: right-click project folder -> 7-Zip -> Add to archive -> set password."
  exit 1
}

$secure = Read-Host "Share password (for other developers)" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
if ([string]::IsNullOrWhiteSpace($password)) {
  Write-Host "Empty password not allowed."
  exit 1
}

$stamp = Get-Date -Format "yyyyMMdd-HHmm"
$outDir = Join-Path $root "_share_out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zipPath = Join-Path $outDir "QuikSee-VendorApp-$stamp.7z"

# Exclude build junk + local unlock secrets (devs set their own key)
$excludes = @(
  "-xr!build",
  "-xr!.dart_tool",
  "-xr!.idea",
  "-xr!.vscode",
  "-xr!.cursor",
  "-xr!_share_out",
  "-xr!_verify_xlsx",
  "-xr!_xlsx_out",
  "-xr!_xlsx_ref",
  "-xr!.qse\k",
  "-xr!.quiksee_source_locked",
  "-xr!**/*.iml",
  "-xr!**/local.properties",
  "-xr!**/.gradle"
)

Write-Host "Creating password-protected archive..."
& $sevenZip a -t7z -mhe=on "-p$password" $excludes $zipPath "$root\*" | Out-Host
$password = $null

if (-not (Test-Path $zipPath)) {
  Write-Host "Failed to create archive."
  exit 1
}

Write-Host ""
Write-Host "DONE."
Write-Host "File: $zipPath"
Write-Host "Send this file to the developer."
Write-Host "Send the password on a DIFFERENT channel (WhatsApp/call) — not inside the zip email."
Write-Host "They open with 7-Zip / WinRAR using your password."
