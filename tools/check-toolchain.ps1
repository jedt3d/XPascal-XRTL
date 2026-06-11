param(
    [string]$RequiredVersion = "3.3.1"
)

$ErrorActionPreference = "Stop"

function Find-Fpc {
    if ($env:FPC_BIN -and (Test-Path $env:FPC_BIN)) {
        return (Resolve-Path $env:FPC_BIN).Path
    }

    $cmd = Get-Command fpc -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $local = Get-ChildItem -Path ".toolchains" -Recurse -Include "fpc.exe","ppc*.exe" -File -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -First 1
    if ($local) {
        return $local.FullName
    }

    return $null
}

$fpc = Find-Fpc
if (-not $fpc) {
    Write-Error "fpc was not found. Run tools/install-fpc.ps1 or set FPC_BIN to fpc.exe."
}

$version = (& $fpc -iV).Trim()
Write-Host "fpc: $fpc"
Write-Host "version: $version"

if ($version -ne $RequiredVersion) {
    Write-Error "Expected FreePascal $RequiredVersion, got $version."
}

Write-Host "ok: FreePascal toolchain matches $RequiredVersion"
