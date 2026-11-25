$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$executablePath = Join-Path $projectRoot 'builds\current\Game.exe'

if (-not (Test-Path -LiteralPath $executablePath)) {
    throw "Build not found at $executablePath. Run scripts/export.sh in the dev container first."
}

Start-Process -FilePath $executablePath -WorkingDirectory (Split-Path -Parent $executablePath)
