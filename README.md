# Godot Game Template

A content-free 3D Godot starter with reusable systems and a pinned development toolchain.
There are no characters, levels, story, game assets, movement implementation, or required
player count. Running the project opens an empty scene with a sky, sun, and camera.

## Quick start

1. Open this folder in VS Code. Docker Desktop is required for container commands.
2. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\editor.ps1`.
   It downloads and hash-verifies the portable Windows editor into `.tools/`.
   Nothing is installed system-wide. Add `-VerifyOnly` to verify without opening the editor.
3. Open `game/main.tscn`, add your own systems, and press F5.
4. Validate and export from the repository root:

   ```powershell
   docker compose run --rm dev bash scripts/lint.sh
   docker compose run --rm dev bash scripts/test.sh
   docker compose run --rm dev bash scripts/export.sh
   ```

   Compose builds the toolchain on first use. Tests import the project, smoke-test startup,
   and run GUT. Exports produce `builds/<version>/Game.exe` and refresh
   `builds/current/Game.exe`. Launch the latter with `scripts\playtest.ps1`.
   Test code and GUT are excluded from exported builds.

## Included systems

All systems are opt-in except the startup atmosphere, sun, and camera.

| Location | Purpose |
| --- | --- |
| `game/art/` | Shared OKHSL `ColorRules`, `HueCap`, `Palette`, `RuledMaterial`, and `RuledLight` |
| `game/camera/` | Multi-target `CoopCamera` with capped follow/zoom and spatial `CameraZone` hints |
| `game/input/` | Device-isolated `PlayerSlot` intent and optional two-slot local `PlayerSlots` manager |
| `game/world/cutaway/` | Group-based roof fading, per-node opacity floors, and optional shadow-only model |
| `game/world/sky/`, `fog/`, `post/`, `atmosphere/`, `lighting/` | Separately editable environment resources |
| `game/tests/` | Isolated system tests and static-model architecture check |
| `models/` | Optional script-driven Blender build and preview pipeline, without game models |
| `docker/blender-mcp/`, `.vscode/mcp.json` | Optional pinned Blender inspection integration |

See [docs/systems.md](docs/systems.md) for APIs and integration details, and
[models/README.md](models/README.md) for the model pipeline.

## Customize

- Rename `config/name` in `game/project.godot` and the dev-container display name in
  `.devcontainer/devcontainer.json`. The template has no copied Git history or remote.
- Change `Game.exe` together in `game/export_presets.cfg`, `scripts/export.sh`, and
  `scripts/playtest.ps1` if you want a different build filename.
- Author scene palettes in `game/art/palettes/`. Global color rules start without hue caps,
  saturation reduction, or luminosity clamping; tune them for your own art direction.
- The engine remains pinned to **Godot 4.7.2 stable**, GDScript, **Forward+**, and a
  **Windows x86_64** export. No versions or dependency hashes were upgraded.
  The Dockerfile, version check, editor launcher, and project feature version must stay aligned.
- Input bindings include WASD/left stick, Shift/B (run), and Space/A (jump). No movement or
  player scene is supplied. The manager supports Enter or A/Start to join when instantiated.

## Development

Use the portable Windows editor for GPU and physical-controller checks. Use the dev container
for lint, GUT tests, and exports; VS Code's *Reopen in Container* uses the same service.
Caches (`.tools/`, `game/.godot/`) and outputs (`builds/`) are ignored and are not template assets.
Color rules and atmosphere resources update live in the editor.

Headless tests cannot establish Forward+ visual quality, physical-controller behavior, or
streaming quality. Validate those manually when adding relevant content.
Record third-party assets and their licenses in [CREDITS.md](CREDITS.md).
