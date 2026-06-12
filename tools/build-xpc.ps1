param(
    [string]$ProjectPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

& (Join-Path $PSScriptRoot "check-toolchain.ps1")

$fpc = if ($env:FPC_BIN -and (Test-Path $env:FPC_BIN)) {
    (Resolve-Path $env:FPC_BIN).Path
} else {
    $cmd = Get-Command fpc -ErrorAction SilentlyContinue
    if ($cmd) {
        $cmd.Source
    } else {
        (Get-ChildItem -Path (Join-Path $repoRoot ".toolchains") -Recurse -Include "fpc.exe","ppc*.exe" -File | Sort-Object Name | Select-Object -First 1).FullName
    }
}

$compilerArgs = @("-Mobjfpc", "-Sh")
$unitRoot = $null
if ($env:FPC_UNIT_DIR -and (Test-Path $env:FPC_UNIT_DIR)) {
    $unitRoot = (Resolve-Path $env:FPC_UNIT_DIR).Path
} else {
    $candidateUnitRoots = @(
        (Join-Path $repoRoot ".toolchains\fpc-3.3.1\units\x86_64-win64"),
        (Join-Path $repoRoot ".toolchains\fpc-3.3.1\units\i386-win32")
    )
    foreach ($candidate in $candidateUnitRoots) {
        if (Test-Path $candidate) {
            $unitRoot = (Resolve-Path $candidate).Path
            break
        }
    }
}
if ($unitRoot) {
    @("rtl", "rtl-objpas", "fcl-base", "fcl-db", "sqlite") | ForEach-Object {
        $unitPath = Join-Path $unitRoot $_
        if (Test-Path $unitPath) {
            $compilerArgs += "-Fu$((Resolve-Path $unitPath).Path)"
        }
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
    & $fpc @compilerArgs "-FU$projectUnitBuild" "-FE$projectBuild" "-o$projectOutput" $mainFile
    if ($LASTEXITCODE -ne 0) { throw "Failed to build project $projectName." }
    if (Test-Path $projectOutput) {
        Move-Item -LiteralPath $projectOutput -Destination $projectExe -Force
    }
    if (-not (Test-Path $projectExe)) { throw "Expected project executable to be created." }
    Write-Host "built: $projectName/build/$projectName.exe"
    exit 0
}

$buildDir = Join-Path $repoRoot "build"
$unitBuildDir = Join-Path $buildDir "units"
$coreTests = @("core_smoke", "core_result_tests", "core_option_tests")
$databaseTests = @("database_smoke", "database_sqlite_tests")

New-Item -ItemType Directory -Force $buildDir, $unitBuildDir | Out-Null
Remove-Item -Force (Join-Path $buildDir "xpc"), (Join-Path $buildDir "xpc.exe"), (Join-Path $buildDir "hello_xpc"), (Join-Path $buildDir "hello_xpc.exe") -ErrorAction SilentlyContinue
foreach ($testName in $coreTests) {
    Remove-Item -Force (Join-Path $buildDir $testName), (Join-Path $buildDir "$testName.exe") -ErrorAction SilentlyContinue
}
foreach ($testName in $databaseTests) {
    Remove-Item -Force (Join-Path $buildDir $testName), (Join-Path $buildDir "$testName.exe") -ErrorAction SilentlyContinue
}

$xpcOutput = Join-Path $buildDir "xpc"
$xpcExe = Join-Path $buildDir "xpc.exe"
$helloOutput = Join-Path $buildDir "hello_xpc"
$helloExe = Join-Path $buildDir "hello_xpc.exe"

& $fpc @compilerArgs "-Fu$repoRoot" "-FU$unitBuildDir" "-FE$buildDir" "-o$xpcOutput" (Join-Path $repoRoot "src/xpc/xpc.pas")
if ($LASTEXITCODE -ne 0) { throw "Failed to build xpc." }
if (-not (Test-Path $xpcOutput)) { throw "Expected build/xpc to be created." }
Move-Item -LiteralPath $xpcOutput -Destination $xpcExe -Force
& $fpc @compilerArgs "-FU$unitBuildDir" "-FE$buildDir" "-o$helloOutput" (Join-Path $repoRoot "tests/smoke/hello_xpc.pas")
if ($LASTEXITCODE -ne 0) { throw "Failed to build hello_xpc." }
if (-not (Test-Path $helloOutput)) { throw "Expected build/hello_xpc to be created." }
Move-Item -LiteralPath $helloOutput -Destination $helloExe -Force

foreach ($testName in $coreTests) {
    $source = Join-Path $repoRoot "tests/xrtl/core/$testName.pas"
    $output = Join-Path $buildDir $testName
    $exe = Join-Path $buildDir "$testName.exe"
    & $fpc @compilerArgs "-Fu$(Join-Path $repoRoot "src/xrtl/core")" "-FU$unitBuildDir" "-FE$buildDir" "-o$output" $source
    if ($LASTEXITCODE -ne 0) { throw "Failed to build $testName." }
    if (-not (Test-Path $output)) { throw "Expected $output to be created." }
    Move-Item -LiteralPath $output -Destination $exe -Force
    & $exe
    if ($LASTEXITCODE -ne 0) { throw "Failed to run $testName." }
}

foreach ($testName in $databaseTests) {
    $source = Join-Path $repoRoot "tests/xrtl/database/$testName.pas"
    $output = Join-Path $buildDir $testName
    $exe = Join-Path $buildDir "$testName.exe"
    & $fpc @compilerArgs "-Fu$(Join-Path $repoRoot "src/xrtl/core")" "-Fu$(Join-Path $repoRoot "src/xrtl/database")" "-FU$unitBuildDir" "-FE$buildDir" "-o$output" $source
    if ($LASTEXITCODE -ne 0) { throw "Failed to build $testName." }
    if (-not (Test-Path $output)) { throw "Expected $output to be created." }
    Move-Item -LiteralPath $output -Destination $exe -Force
    & $exe
    if ($LASTEXITCODE -ne 0) { throw "Failed to run $testName." }
}

Write-Host "built: build/xpc.exe"
Write-Host "built: build/hello_xpc.exe"
foreach ($testName in $coreTests) {
    Write-Host "built: build/$testName.exe"
}
foreach ($testName in $databaseTests) {
    Write-Host "built: build/$testName.exe"
}
