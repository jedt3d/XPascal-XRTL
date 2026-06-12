param(
    [string]$ProjectPath = ""
)

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

if ($ProjectPath) {
    $projectRoot = (Resolve-Path $ProjectPath).Path
    $projectFile = Join-Path $projectRoot "xproject.toml"
    $mainFile = Join-Path $projectRoot "src\main.pas"
    $projectName = Split-Path $projectRoot -Leaf
    $projectBuild = Join-Path $projectRoot "build"
    $projectOutput = Join-Path $projectBuild $projectName
    $projectExe = Join-Path $projectBuild "$projectName.exe"

    if (-not (Test-Path $projectFile)) { throw "Expected xproject.toml in $projectRoot." }
    if (-not (Test-Path $mainFile)) { throw "Expected src/main.pas in $projectRoot." }

    New-Item -ItemType Directory -Force $projectBuild | Out-Null
    Remove-Item -Force $projectOutput, $projectExe -ErrorAction SilentlyContinue
    & $fpc -Mobjfpc -Sh "-FE$projectBuild" "-o$projectOutput" $mainFile
    if ($LASTEXITCODE -ne 0) { throw "Failed to build project $projectName." }
    if (Test-Path $projectOutput) {
        Move-Item -LiteralPath $projectOutput -Destination $projectExe -Force
    }
    if (-not (Test-Path $projectExe)) { throw "Expected project executable to be created." }
    Write-Host "built: $projectName/build/$projectName.exe"
    exit 0
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
