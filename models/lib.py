"""Shared helpers for headless model scripts.

Conventions every model follows (see models/README.md):
- 1 Blender unit = 1 Godot meter; the model faces Blender +Y (Godot -Z) with Z up.
- Each animatable part is its own object, with its origin at its pivot.
- Material names are slots; Godot maps each slot to a RuledMaterial in the game, so the
  colors set here are preview-only and are read from those RuledMaterial files.
"""

import math
import re
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

REPO = Path(__file__).resolve().parent.parent
GAME = REPO / "game"


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def res_path(res: str) -> Path:
    return GAME / res.removeprefix("res://")


def preview_color(res: str) -> tuple:
    """Reads base_color from a Godot RuledMaterial .tres so previews match the game's source."""
    text = res_path(res).read_text(encoding="utf-8")
    match = re.search(r"base_color\s*=\s*Color\(([^)]*)\)", text)
    if match is None:
        raise ValueError(f"No base_color in {res}")
    return tuple(float(part) for part in match.group(1).split(","))


def material(slot: str, res: str, roughness: float = 0.8) -> bpy.types.Material:
    mat = bpy.data.materials.get(slot) or bpy.data.materials.new(slot)
    mat.use_nodes = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = preview_color(res)
    shader.inputs["Roughness"].default_value = roughness
    mat["godot_material"] = res
    return mat


def ellipsoid(bm, center, radii, rotation=(0.0, 0.0, 0.0), segments=32, rings=16, shape=None):
    """Adds an ellipsoid. shape(local) may reshape the unit-sphere point before scaling."""
    created = bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    rot = Euler([math.radians(a) for a in rotation]).to_matrix()
    for vert in created["verts"]:
        local = vert.co.copy()
        if shape is not None:
            local = shape(local)
        scaled = Vector((local.x * radii[0], local.y * radii[1], local.z * radii[2]))
        vert.co = rot @ scaled + Vector(center)
    return created["verts"]


def tube(bm, start, end, start_radius, end_radius, steps=8):
    """A tapered tube built from overlapping spheres; meant to be fused."""
    start, end = Vector(start), Vector(end)
    for i in range(steps + 1):
        t = i / steps
        radius = start_radius + (end_radius - start_radius) * t
        ellipsoid(bm, start.lerp(end, t), (radius,) * 3, segments=16, rings=8)


def prism(bm, outline, bottom, height):
    """Extrudes a closed XY outline (list of (x, y)) upward from z=bottom."""
    verts = [bm.verts.new((x, y, bottom)) for x, y in outline]
    face = bm.faces.new(verts)
    extruded = bmesh.ops.extrude_face_region(bm, geom=[face])
    top = [e for e in extruded["geom"] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=top, vec=(0.0, 0.0, height))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])


def _object_from_bmesh(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _apply_modifiers(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated)
    old = obj.data
    obj.modifiers.clear()
    obj.data = mesh
    bpy.data.meshes.remove(old)


def triangle_count(obj) -> int:
    return sum(len(poly.vertices) - 2 for poly in obj.data.polygons)


def fuse(name, bm, voxel_size, target_triangles, smooth_repeat=8, smooth_factor=0.5):
    """Unions overlapping closed shapes into one soft surface, then reduces it to a budget."""
    obj = _object_from_bmesh(name, bm)
    remesh = obj.modifiers.new("Remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel_size
    smooth = obj.modifiers.new("Smooth", "LAPLACIANSMOOTH")
    smooth.iterations = smooth_repeat
    smooth.lambda_factor = smooth_factor
    smooth.use_volume_preserve = True
    _apply_modifiers(obj)
    current = triangle_count(obj)
    if current > target_triangles:
        decimate = obj.modifiers.new("Decimate", "DECIMATE")
        decimate.ratio = target_triangles / current
        _apply_modifiers(obj)
    return obj


def part(name, bm):
    """A part that is used as built, without fusing."""
    return _object_from_bmesh(name, bm)


def finish(obj, mat, pivot=(0.0, 0.0, 0.0)):
    """Assigns the material slot, shades smooth, and moves the origin to the part's pivot."""
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    pivot = Vector(pivot)
    obj.data.transform(Matrix.Translation(-pivot))
    obj.location = pivot
    obj.data.shade_smooth()
    return obj
