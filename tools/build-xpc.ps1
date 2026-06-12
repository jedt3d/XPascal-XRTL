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
    $projectUnitBuild = Join-Path $projectBuild "units"
    $projectOutput = Join-Path $projectBuild $projectName
    $projectExe = Join-Path $projectBuild "$projectName.exe"

    if (-not (Test-Path $projectFile)) { throw "Expected xproject.toml in $projectRoot." }
    if (-not (Test-Path $mainFile)) { throw "Expected src/main.pas in $projectRoot." }

    New-Item -ItemType Directory -Force $projectBuild, $projectUnitBuild | Out-Null
    Remove-Item -Force $projectOutput, $projectExe -ErrorAction SilentlyContinue
    & $fpc -Mobjfpc -Sh "-FU$projectUnitBuild" "-FE$projectBuild" "-o$projectOutput" $mainFile
    if ($LASTEXITCODE -ne 0) { throw "Failed to build project $projectName." }
    if (Test-Path $projectOutput) {
        Move-Item -LiteralPath $projectOutput -Destination $projectExe -Force
    }
    if (-not (Test-Path $projectExe)) { throw "Expected project executable to be created." }
    Write-Host "built: $projectName/build/$projectName.exe"
    exit 0
}

$buildDir = Join-Path (Get-Location) "build"
$unitBuildDir = Join-Path $buildDir "units"
$coreTests = @("core_smoke", "core_result_tests", "core_option_tests")

New-Item -ItemType Directory -Force $buildDir, $unitBuildDir | Out-Null
Remove-Item -Force build/xpc, build/xpc.exe, build/hello_xpc, build/hello_xpc.exe -ErrorAction SilentlyContinue
foreach ($testName in $coreTests) {
    Remove-Item -Force "build/$testName", "build/$testName.exe" -ErrorAction SilentlyContinue
}

& $fpc -Mobjfpc -Sh -Fu. "-FU$unitBuildDir" -FEbuild -obuild/xpc src/xpc/xpc.pas
if ($LASTEXITCODE -ne 0) { throw "Failed to build xpc." }
if (-not (Test-Path build/xpc)) { throw "Expected build/xpc to be created." }
Move-Item -LiteralPath build/xpc -Destination build/xpc.exe -Force
& $fpc -Mobjfpc -Sh "-FU$unitBuildDir" -FEbuild -obuild/hello_xpc tests/smoke/hello_xpc.pas
if ($LASTEXITCODE -ne 0) { throw "Failed to build hello_xpc." }
if (-not (Test-Path build/hello_xpc)) { throw "Expected build/hello_xpc to be created." }
Move-Item -LiteralPath build/hello_xpc -Destination build/hello_xpc.exe -Force

foreach ($testName in $coreTests) {
    $source = "tests/xrtl/core/$testName.pas"
    $output = "build/$testName"
    $exe = "build/$testName.exe"
    & $fpc -Mobjfpc -Sh -Fusrc/xrtl/core "-FU$unitBuildDir" -FEbuild "-o$output" $source
    if ($LASTEXITCODE -ne 0) { throw "Failed to build $testName." }
    if (-not (Test-Path $output)) { throw "Expected $output to be created." }
    Move-Item -LiteralPath $output -Destination $exe -Force
    & "./$exe"
    if ($LASTEXITCODE -ne 0) { throw "Failed to run $testName." }
}

Write-Host "built: build/xpc.exe"
Write-Host "built: build/hello_xpc.exe"
foreach ($testName in $coreTests) {
    Write-Host "built: build/$testName.exe"
}
