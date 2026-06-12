$ErrorActionPreference = "Stop"

$xpc = Join-Path $PSScriptRoot "..\build\xpc.exe"

if ($args.Count -gt 0 -and $args[0] -eq "build") {
    & (Join-Path $PSScriptRoot "build-xpc.ps1")
    exit $LASTEXITCODE
}

if (-not (Test-Path $xpc)) {
    throw "build/xpc.exe was not found. Run tools/run-xpc.ps1 build first."
}

if (-not $env:FPC_BIN) {
    $localFpc = Get-ChildItem -Path (Join-Path $PSScriptRoot "..\.toolchains") -Recurse -Include "fpc.exe","ppc*.exe" -File -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -First 1
    if ($localFpc) {
        $env:FPC_BIN = $localFpc.FullName
    }
}

if (-not $env:FPC_VERSION -and $env:FPC_BIN -and (Test-Path $env:FPC_BIN)) {
    $env:FPC_VERSION = (& $env:FPC_BIN -iV).Trim()
}

& $xpc @args
exit $LASTEXITCODE
