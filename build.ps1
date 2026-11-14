# Builds CoopBalance.zip (mods-unpacked/ at the zip root, "/" separators).
# Windows PowerShell 5.1 compatible. Usage: powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$modDir = Join-Path $root 'mods-unpacked\BrotatoCoop-CoopBalance'
$zipPath = Join-Path $root 'CoopBalance.zip'

if (-not (Test-Path $modDir)) { throw "Mod folder not found: $modDir" }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$rootFull = (Resolve-Path $root).Path.TrimEnd('\') + '\'
$files = Get-ChildItem -Path $modDir -Recurse -File | Sort-Object FullName

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($rootFull.Length).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        Write-Host "  + $entryName"
    }
}
finally {
    $zip.Dispose()
}

Write-Host "Built $zipPath ($($files.Count) files)"
