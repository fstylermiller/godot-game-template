# Reusable systems

The startup scene contains no gameplay wiring. Instance only the systems your game needs.
Systems communicate through typed APIs, exported references, and signals.

## Color and atmosphere

`ColorRules.current()` shares `art/color_rules.tres` across materials, palettes, lights, sky,
and fog. The resource uses neutral limits in this template; individual `ColorRules.new()`
instances retain their original configurable defaults. Use `Palette.swatch(name)` or
`Palette.resolved()` to resolve authored swatches. Use `RuledMaterial.base_color`,
`base_emission`, and `emission_strength` rather than assigning resolved colors directly.
`RuledLight` resolves its `base_color` through the same rules.

`Atmosphere` builds an Environment from exported `SkySettings`, `FogSettings`, and
`PostProcessSettings`. Changes to these resources or global rules rebuild it automatically.
The generic sky, volumetric fog, glow, sun, and project-wide TAA are starter settings, not
validated visual targets for a particular game. They can all be tuned or removed.

## Camera

Instance `camera/coop_camera.tscn`, assign its `targets: Array[Node3D]`, then call
`snap_to_targets()` after targets enter the tree. Each frame it follows visible, valid targets,
frames their average position, and zooms for their spread. `max_speed`, `max_zoom_speed`,
`max_zoom`, and `offset` are exported tunables. It works with one or more targets and has no
dependency on characters or input.

Add a `CameraZone` node to override framing within a local XZ rectangle. Its size, falloff,
yaw, and distance scale are exported; the strongest zone around the focus point wins.

## Input

Add a `PlayerSlots` node to opt into two-slot local input assignment. Listen for `slots_changed`
and read `slots`. Each `PlayerSlot` exposes `connected`, `movement()`, `run_held`, `jump_held`,
and `take_jump()` (consumes one pending press). A/Start joins a controller; Enter joins the
keyboard. Bindings live in `PlayerSlot`; the project InputMap retains matching generic actions.
No actor is created or moved by the input system.

A disconnect clears intent and blocks input routing until a matching GUID reconnects with
A/Start. The consuming game decides how to pause actors or show reconnection UI. Identical
controllers sharing a GUID cannot be distinguished after both disconnect. `PlayerSlots`
retains a two-slot default as an optional utility, not a requirement of the startup scene.
Games with different assignment policies can use `PlayerSlot` directly.

## Cutaway

Add `CoveredRoof` to an Area3D with collision shapes for a covered space. Export `roof` points
at existing geometry; `shadow_caster` optionally points at a second model instance, switched
to shadows-only. Add relevant physics bodies to `cutaway_occupants`, or set `occupant_group`.
Configure the area's collision mask to detect those bodies.

`fade_time` controls transition duration. `faded_opacity` controls the remaining opacity.
`cutaway_opacity` metadata on a node overrides its subtree; the nearest override wins.
Blender object properties arrive inside Godot's `extras` metadata and are supported too.
Materials must derive from `BaseMaterial3D`; the component duplicates them per instance.

When the camera is inside the roof's horizontal bounds and below its midpoint, the roof becomes
solid only if all visible group members are in frame and at least `occupants_to_frame` are
visible (default 1). Set that threshold to your game's required party size if appropriate.
The component does not generate geometry or depend on a particular actor.
