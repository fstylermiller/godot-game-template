# Model pipeline

No game models are included. Optional helpers build self-authored models using portable,
hash-verified Blender, without installing Blender system-wide.

1. Add `models/<name>.py` with `OUTPUT` (a `res://` GLB path), `PREVIEW_TARGET` (a point),
   and `build()`. Optionally set `PREVIEW_DISTANCE`.
2. Use `lib.py` for geometry, material slots, pivots, and triangle counting. `lib.material()`
   reads preview colors from Godot `RuledMaterial` resources.
3. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\model.ps1 -Name <name>`.
4. Review the sheet in `builds/previews/`, iterate, and configure the GLB import's external
   material mapping to `RuledMaterial` resources. Commit the script, GLB, and `.glb.import`.
5. Run container tests and export, then check the result in the Windows Forward+ editor.

One Blender unit equals one Godot meter. Models face Blender +Y (Godot -Z), with Z up.
Keep animatable parts separate and place their origins at their pivots.
Choose a triangle budget per part and review the build report.
`build.py` exports object custom properties as glTF extras.

## Static visuals

Shipped static visuals come from model files, not primitive or script-generated meshes.
Collision shapes and lights remain in scenes. Scripts can change supplied meshes' settings
but do not create static geometry. `game/tests/test_static_models.gd` enforces this convention.
Moving geometry that a model with separate parts cannot express requires a documented exception
in that test's `EXCEPTIONS`.

| Exception | Class | Reason |
| --- | --- | --- |
| `game/tests/` | Test fixture | Isolated throwaway meshes for cutaway tests, excluded from export. |

## Optional live inspection

Run `scripts\blender-mcp.ps1` to build the pinned MCP container and install its matching add-on
into portable Blender. Open Blender with `scripts\blender.ps1`. The VS Code MCP configuration
uses the local Compose service; safe mode stays on and telemetry stays off.
Fold experiments back into model scripts and rebuild; do not use hand-edited exports as source.
