$ErrorActionPreference = "Stop"

./tools/check-toolchain.ps1

$fpc = if ($env:FPC_BIN -and (Test-Path $env:FPC_BIN)) {
    (Resolve-Path $env:FPC_BIN).Path
} else {
    $cmd = Get-Command fpc -ErrorAction SilentlyContinue
    if ($cmd) {
        $cmd.Source
    } else {
        (Get-ChildItem -Path ".toolchains" -Recurse -Include "fpc.exe","ppc*.exe" -File | Sort-Object Name | Select-Object -First 1).FullName
    }
}

New-Item -ItemType Directory -Force build | Out-Null
Remove-Item -Force build/xpc, build/xpc.exe, build/hello_xpc, build/hello_xpc.exe -ErrorAction SilentlyContinue
& $fpc -Mobjfpc -Sh -Fu. -FEbuild -obuild/xpc src/xpc/xpc.pas
if ($LASTEXITCODE -ne 0) { throw "Failed to build xpc." }
if (-not (Test-Path build/xpc)) { throw "Expected build/xpc to be created." }
Move-Item -LiteralPath build/xpc -Destination build/xpc.exe -Force
& $fpc -Mobjfpc -Sh -FEbuild -obuild/hello_xpc tests/smoke/hello_xpc.pas
if ($LASTEXITCODE -ne 0) { throw "Failed to build hello_xpc." }
if (-not (Test-Path build/hello_xpc)) { throw "Expected build/hello_xpc to be created." }
Move-Item -LiteralPath build/hello_xpc -Destination build/hello_xpc.exe -Force

Write-Host "built: build/xpc.exe"
Write-Host "built: build/hello_xpc.exe"
