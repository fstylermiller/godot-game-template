param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [switch]$NoPreview
)

# Builds models/<Name>.py headlessly with portable Blender: exports its .glb into game/ and
# writes a preview sheet to builds/previews/<Name>.png.

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$blender = & (Join-Path $PSScriptRoot 'blender.ps1') -VerifyOnly | Select-Object -Last 1
$arguments = @(
    '--background', '--factory-startup',
    '--python-exit-code', '1',
    '--python', (Join-Path $projectRoot 'models\build.py'),
    '--', $Name
)
if ($NoPreview) {
    $arguments += '--no-preview'
}

& $blender @arguments 2>&1 | ForEach-Object {
    $line = "$_"
    if ($line -match '^(MODEL|Error|Traceback|  File|\w+Error)') {
        Write-Host $line
    }
}
if ($LASTEXITCODE -ne 0) {
    throw "Model build failed for '$Name' (exit $LASTEXITCODE)"
}
