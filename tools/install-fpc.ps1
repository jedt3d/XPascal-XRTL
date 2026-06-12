param(
    [string]$InstallDir = ".toolchains/fpc-3.3.1",
    [string]$ArchiveUrl = "",
    [string]$Sha256 = ""
)

$ErrorActionPreference = "Stop"

if (-not $ArchiveUrl) {
    $ArchiveUrl = "https://downloads.freepascal.org/fpc/snapshot/v33/x86_64-win64/fpc-3.3.1.x86_64-win64.built.on.i386-win32.zip"
    if (-not $Sha256) {
        $Sha256 = "b3bf9859e3130c8196513a04891d5718b62fa637f7a093bb4d37d86863ecece8"
    }
}

$installPath = Resolve-Path -LiteralPath (New-Item -ItemType Directory -Force -Path $InstallDir)
$archiveName = Split-Path $ArchiveUrl -Leaf
$archivePath = Join-Path $installPath $archiveName

if (Test-Path $archivePath) {
    Write-Host "Using existing archive $archivePath"
} else {
    Write-Host "Downloading FPC 3.3.1 from $ArchiveUrl"
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $archivePath
}

if (-not $Sha256 -or $Sha256 -eq "PENDING") {
    throw "SHA256 is required for FPC archives. Set -Sha256 for custom ArchiveUrl values."
}

$actual = (Get-FileHash -Algorithm SHA256 $archivePath).Hash.ToLowerInvariant()
if ($actual -ne $Sha256.ToLowerInvariant()) {
    throw "SHA256 mismatch. Expected $Sha256, got $actual."
}

Write-Host "Extracting $archivePath"
Expand-Archive -LiteralPath $archivePath -DestinationPath $installPath -Force

$fpc = Get-ChildItem -Path $installPath -Recurse -Include "fpc.exe","ppc*.exe" -File |
    Sort-Object Name |
    Select-Object -First 1
if (-not $fpc) {
    throw "Archive extracted, but no fpc.exe or ppc*.exe compiler was found under $installPath."
}

$fpcDir = Split-Path $fpc.FullName -Parent
$fpcDriver = Join-Path $fpcDir "fpc.cmd"
if ($fpc.Name -ne "fpc.exe") {
    Set-Content -Path $fpcDriver -Value "@echo off`r`n`"%~dp0$($fpc.Name)`" %*`r`n" -Encoding ASCII
    Write-Host "created wrapper: $fpcDriver"
}
Write-Host "fpc: $($fpc.FullName)"

if ($env:GITHUB_PATH) {
    Add-Content -Path $env:GITHUB_PATH -Value $fpcDir
}

$env:PATH = "$fpcDir;$env:PATH"
$env:FPC_BIN = $fpc.FullName
& $fpc.FullName -iV
