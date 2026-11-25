# Godot template guidance

- Keep changes typed, modular, and scoped. Scenes compose independent systems; they do not
  implement another system's internals. Communicate through signals, exported references,
  and small typed APIs.
- Do not assume a genre, art style, player count, story, or game-specific controller behavior.
- Route authored colors through `ColorRules`: palettes use `resolved()` / `swatch()`,
  fixed materials use `RuledMaterial`, lights use `RuledLight`, and atmosphere uses settings
  resources. Tune global constraints in `game/art/color_rules.tres`.
- Follow `models/README.md` for static visuals and the script-driven model pipeline.
- Preserve pinned dependency versions unless an upgrade is explicitly requested.
- Use Windows-compatible PowerShell on the host. Do not install Godot system-wide or change
  host networking. Use the portable Windows editor for GPU/controller validation.
- Run lint, tests, and Windows exports in the pinned container:
  `docker compose run --rm dev bash scripts/lint.sh`,
  `docker compose run --rm dev bash scripts/test.sh`, and
  `docker compose run --rm dev bash scripts/export.sh`.
- Refresh exports when changing playable behavior. Rendering changes need a real Forward+
  GPU check; input tests do not establish physical-controller or streaming correctness.
- State automated results and remaining manual checks separately. Keep diagnostics and
  temporary probes out of normal startup.
