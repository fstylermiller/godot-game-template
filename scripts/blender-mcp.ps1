# Installs the MCP add-on into the portable Blender in .tools and builds the container that runs
# the MCP server. Nothing is installed on the host outside the repository.
# The add-on is copied from the pinned, hash-verified package inside the image, so the add-on
# and server versions always match.

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$blender = & (Join-Path $PSScriptRoot 'blender.ps1') -VerifyOnly | Select-Object -Last 1
$addonDirectory = Join-Path (Split-Path $blender) 'portable\scripts\addons'
$addonPath = Join-Path $addonDirectory 'blender_mcp.py'

Push-Location $projectRoot
try {
    docker compose --profile blender build blender-mcp
    if ($LASTEXITCODE -ne 0) { throw 'Building the blender-mcp image failed.' }
    $image = docker compose --profile blender images -q blender-mcp
    if ($LASTEXITCODE -ne 0 -or -not $image) { throw 'Could not resolve the blender-mcp image.' }

    New-Item -ItemType Directory -Path $addonDirectory -Force | Out-Null
    $container = docker create $image
    try {
        docker cp "${container}:/opt/mcp/lib/python3.11/site-packages/blender_mcp/bundled/addon.py" $addonPath
        if ($LASTEXITCODE -ne 0) { throw 'Copying the add-on out of the image failed.' }
    }
    finally {
        docker rm $container | Out-Null
    }
}
finally {
    Pop-Location
}

$enable = @'
import addon_utils, bpy
addon_utils.enable('blender_mcp', default_set=True, persistent=True)
bpy.ops.wm.save_userpref()
print('MCP add-on enabled:', addon_utils.check('blender_mcp'))
'@
$ErrorActionPreference = 'Continue'
& $blender --background --python-exit-code 1 --python-expr $enable 2>&1 |
    Where-Object { "$_" -match 'MCP add-on|Error' } | ForEach-Object { Write-Host $_ }
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'Enabling the MCP add-on failed.' }

Write-Host "Installed $addonPath"
Write-Host 'Start Blender with scripts/blender.ps1; the add-on serves on localhost:9876.'
