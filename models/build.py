"""Headless model build: blender --background --factory-startup --python models/build.py -- NAME.

Runs models/NAME.py's build(), reports triangle counts and bounds, exports the .glb to the
module's OUTPUT path, and (unless --no-preview) renders a 2x2 preview sheet to builds/previews.
"""

import importlib
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib  # noqa: E402
import preview  # noqa: E402


def report(objects):
    bpy.context.view_layer.update()
    total = 0
    low = [float("inf")] * 3
    high = [float("-inf")] * 3
    for obj in sorted(objects, key=lambda o: o.name):
        triangles = lib.triangle_count(obj)
        total += triangles
        for corner in obj.bound_box:
            world = obj.matrix_world @ lib.Vector(corner)
            low = [min(a, b) for a, b in zip(low, world)]
            high = [max(a, b) for a, b in zip(high, world)]
        slots = ",".join(m.name for m in obj.data.materials)
        print(f"MODEL part {obj.name}: {triangles} tris, material {slots}")
    print(f"MODEL total {total} tris")
    print("MODEL bounds min (%.3f, %.3f, %.3f) max (%.3f, %.3f, %.3f)" % (*low, *high))


def main():
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if not args:
        raise SystemExit("Usage: ... --python models/build.py -- MODEL_NAME [--no-preview]")
    name = args[0]
    lib.reset_scene()
    module = importlib.import_module(name)
    module.build()
    parts = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    report(parts)

    output = lib.res_path(module.OUTPUT)
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )
    print(f"MODEL exported {output}")

    if "--no-preview" not in args:
        sheet = preview.render(
            name, lib.REPO / "builds" / "previews", module.PREVIEW_TARGET,
            distance=getattr(module, "PREVIEW_DISTANCE", 4.2),
        )
        print(f"MODEL preview {sheet}")


main()
