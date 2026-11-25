param(
    [switch]$VerifyOnly
)

# Portable Blender for modeling. -VerifyOnly downloads and verifies it, then returns the
# executable path on the pipeline (used by model.ps1) instead of launching the editor.

$ErrorActionPreference = 'Stop'

$version = '5.2.4'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$toolsDirectory = Join-Path $projectRoot '.tools'
$installDirectory = Join-Path $toolsDirectory "blender-$version"
$executablePath = Join-Path $installDirectory 'blender.exe'
$archiveName = "blender-$version-windows-x64"
$expectedHash = 'bbd78f8931dc940444da4ff2983374930f9f5c092ae0e330588e9760bb9d967c'
# download.blender.org rejects scripted downloads; this is an official Blender mirror and the
# hash comes from Blender's published blender-5.2.4.sha256.
$downloadUrl = "https://ftp.nluug.nl/pub/graphics/blender/release/Blender5.2/$archiveName.zip"

if (-not (Test-Path -LiteralPath $executablePath)) {
    New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
    $archivePath = Join-Path $toolsDirectory 'blender-download.zip'
    $extractDirectory = Join-Path $toolsDirectory 'blender-extract'

    try {
        Write-Host "Downloading portable Blender $version (about 400 MB)..."
        $previousProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $archivePath
        $ProgressPreference = $previousProgress
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "Blender archive SHA-256 mismatch: expected $expectedHash, got $actualHash"
        }

        Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDirectory -Force
        $extracted = Join-Path $extractDirectory $archiveName
        if (-not (Test-Path -LiteralPath (Join-Path $extracted 'blender.exe'))) {
            throw "The verified archive did not contain $archiveName\blender.exe"
        }
        Move-Item -LiteralPath $extracted -Destination $installDirectory
    }
    finally {
        Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# A 'portable' folder keeps Blender's preferences and add-ons inside .tools, off the host profile.
New-Item -ItemType Directory -Path (Join-Path $installDirectory 'portable') -Force | Out-Null

$versionOutput = Join-Path $toolsDirectory 'blender-version.txt'
try {
    $versionProcess = Start-Process -FilePath $executablePath -ArgumentList '--factory-startup --version' `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput $versionOutput
    $reportedVersion = (Get-Content -LiteralPath $versionOutput | Select-Object -First 1).Trim()
}
finally {
    Remove-Item -LiteralPath $versionOutput -Force -ErrorAction SilentlyContinue
}

if ($versionProcess.ExitCode -ne 0 -or $reportedVersion -notmatch "^Blender $([regex]::Escape($version))( LTS)?$") {
    throw "Expected Blender $version at $executablePath, found '$reportedVersion'"
}

Write-Host "Verified $reportedVersion"
if ($VerifyOnly) {
    return $executablePath
}

Write-Host 'Launching Blender...'
& $executablePath
