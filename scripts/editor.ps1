param(
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$toolsDirectory = Join-Path $projectRoot '.tools'
$executableName = 'Godot_v4.7.2-stable_win64.exe'
$executablePath = Join-Path $toolsDirectory $executableName
$expectedHash = '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'
$downloadUrl = 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'

if (-not (Test-Path -LiteralPath $executablePath)) {
    New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
    $archivePath = Join-Path $toolsDirectory 'godot-download.zip'
    $extractDirectory = Join-Path $toolsDirectory 'godot-extract'

    try {
        Write-Host 'Downloading the official Godot 4.7.2 portable editor...'
        Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $archivePath
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA512).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "Godot archive SHA-512 mismatch: expected $expectedHash, got $actualHash"
        }

        Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDirectory -Force
        $downloadedExecutable = Join-Path $extractDirectory $executableName
        if (-not (Test-Path -LiteralPath $downloadedExecutable)) {
            throw "The verified archive did not contain $executableName"
        }
        Move-Item -LiteralPath $downloadedExecutable -Destination $executablePath
    }
    finally {
        Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$markerPath = Join-Path $toolsDirectory '_sc_'
if (-not (Test-Path -LiteralPath $markerPath)) {
    New-Item -ItemType File -Path $markerPath | Out-Null
}

$versionOutput = Join-Path $toolsDirectory 'godot-version.txt'
try {
    $versionProcess = Start-Process -FilePath $executablePath -ArgumentList '--headless --version' `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput $versionOutput
    $reportedVersion = (Get-Content -Raw -LiteralPath $versionOutput).Trim()
}
finally {
    Remove-Item -LiteralPath $versionOutput -Force -ErrorAction SilentlyContinue
}

if ($versionProcess.ExitCode -ne 0 -or $reportedVersion -notmatch '^4\.7\.2\.stable') {
    throw "Expected Godot 4.7.2 stable at $executablePath, found '$reportedVersion'"
}

Write-Host "Verified Godot $reportedVersion"
if ($VerifyOnly) {
    Write-Host 'Editor download and version verification completed.'
    return
}

Write-Host 'Launching the editor...'
& $executablePath --editor --path (Join-Path $projectRoot 'game')
