$ErrorActionPreference = "Stop"

$xpc = Join-Path $PSScriptRoot "..\build\xpc.exe"

if (-not (Test-Path $xpc)) {
    throw "build/xpc.exe was not found. Run tools/build-xpc.ps1 first."
}

if (-not $env:FPC_BIN) {
    $localFpc = Get-ChildItem -Path (Join-Path $PSScriptRoot "..\.toolchains") -Recurse -Include "fpc.exe","ppc*.exe" -File -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -First 1
    if ($localFpc) {
        $env:FPC_BIN = $localFpc.FullName
    }
}

& $xpc @args
exit $LASTEXITCODE
