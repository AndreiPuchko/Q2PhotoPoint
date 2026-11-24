[CmdletBinding()]
param(
    [string]$QtRoot = "C:\Qt\6.8.3\msvc2022_64",
    [string]$BuildDirectory = "build\distribution",
    [string]$OutputDirectory = "dist\Q2PhotoPoint"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$qtRootPath = [System.IO.Path]::GetFullPath($QtRoot)

function Resolve-ProjectPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

$buildPath = Resolve-ProjectPath $BuildDirectory
$outputPath = Resolve-ProjectPath $OutputDirectory
$buildPrefix = $buildPath.TrimEnd('\') + '\'
$outputPrefix = $outputPath.TrimEnd('\') + '\'
$repoPrefix = $repoRoot.TrimEnd('\') + '\'
$distPrefix = (Join-Path $repoRoot "dist").TrimEnd('\') + '\'
$outputIsInsideRepo = $outputPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)
$outputIsInsideDist = $outputPath.StartsWith($distPrefix, [System.StringComparison]::OrdinalIgnoreCase)

if (-not (Test-Path -LiteralPath (Join-Path $qtRootPath "lib\cmake\Qt6\Qt6Config.cmake"))) {
    throw "Qt 6 was not found under '$qtRootPath'. Pass the Qt kit path with -QtRoot."
}

$webEngineConfig = Join-Path $qtRootPath "lib\cmake\Qt6WebEngineQuick\Qt6WebEngineQuickConfig.cmake"
if (-not (Test-Path -LiteralPath $webEngineConfig)) {
    throw "Qt WebEngineQuick was not found under '$qtRootPath'. Install a Qt 6.8+ MSVC kit with WebEngineQuick, or pass its path with -QtRoot."
}

$qt6ConfigDirectory = Join-Path $qtRootPath "lib\cmake\Qt6"
$windeployqt = Join-Path $qtRootPath "bin\windeployqt.exe"
if (-not (Test-Path -LiteralPath $windeployqt)) {
    throw "windeployqt was not found at '$windeployqt'."
}

$cmakeCommand = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmakeCommand) {
    throw "CMake was not found on PATH."
}

if ($outputPath.Equals($repoRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $outputPath.Equals($buildPath, [System.StringComparison]::OrdinalIgnoreCase) -or
    $outputPath.StartsWith($buildPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
    $buildPath.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
    $repoRoot.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
    ($outputIsInsideRepo -and -not $outputIsInsideDist)) {
    throw "Choose an output directory outside source/build files; use the repository's dist folder or a separate path."
}

$configureArguments = @(
    "-U", "Qt6*_DIR",
    "-S", $repoRoot,
    "-B", $buildPath,
    "-G", "Visual Studio 17 2022",
    "-A", "x64",
    "-DCMAKE_PREFIX_PATH=$qtRootPath",
    "-DQt6_DIR=$qt6ConfigDirectory"
)

Write-Host "Configuring Release build..."
& $cmakeCommand.Source @configureArguments
if ($LASTEXITCODE -ne 0) {
    throw "CMake configuration failed with exit code $LASTEXITCODE."
}

Write-Host "Building Q2PhotoPoint..."
& $cmakeCommand.Source --build $buildPath --config Release --target Q2PhotoPoint --parallel
if ($LASTEXITCODE -ne 0) {
    throw "Release build failed with exit code $LASTEXITCODE."
}

Write-Host "Installing application to '$outputPath'..."
& $cmakeCommand.Source --install $buildPath --config Release --prefix $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "CMake install failed with exit code $LASTEXITCODE."
}

$executable = Join-Path $outputPath "bin\Q2PhotoPoint.exe"
if (-not (Test-Path -LiteralPath $executable)) {
    throw "The installed executable was not found at '$executable'."
}

$qmlDirectory = Join-Path $repoRoot "src\qml"
$deployDirectory = Join-Path $outputPath "bin"
Write-Host "Deploying Qt libraries and QML modules..."
& $windeployqt --release --compiler-runtime --qmldir $qmlDirectory --dir $deployDirectory $executable
if ($LASTEXITCODE -ne 0) {
    throw "windeployqt failed with exit code $LASTEXITCODE."
}

Copy-Item -LiteralPath (Join-Path $repoRoot "readme.MD") -Destination $outputPath -Force

Write-Host ""
Write-Host "Distribution is ready:"
Write-Host "  $executable"
