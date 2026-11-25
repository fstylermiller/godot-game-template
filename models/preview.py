"""Renders a 2x2 preview sheet (front 3/4, side, back 3/4, front) for agent and human review.

Previews use Cycles on the CPU so they work headless on any machine. They show shape and
proportion only; the game's look comes from Godot's Forward+ renderer and ColorRules.
"""

import math
from pathlib import Path

import bpy
import numpy as np

SIZE = 512
VIEWS = (("front_three_quarter", 35.0, 14.0), ("side", 90.0, 8.0), ("back", 200.0, 18.0), ("front", 0.0, 6.0))


def _setup(target):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"

    world = bpy.data.worlds.new("Preview")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.6, 0.68, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    scene.world = world

    sun_data = bpy.data.lights.new("PreviewSun", "SUN")
    sun_data.energy = 3.0
    sun_data.angle = math.radians(12.0)
    sun = bpy.data.objects.new("PreviewSun", sun_data)
    sun.rotation_euler = (math.radians(50.0), 0.0, math.radians(150.0))
    scene.collection.objects.link(sun)

    bpy.ops.mesh.primitive_plane_add(size=60.0)
    ground_material = bpy.data.materials.new("PreviewGround")
    ground_material.use_nodes = True
    ground_shader = ground_material.node_tree.nodes["Principled BSDF"]
    ground_shader.inputs["Base Color"].default_value = (0.42, 0.45, 0.4, 1.0)
    ground_shader.inputs["Roughness"].default_value = 1.0
    bpy.context.active_object.data.materials.append(ground_material)

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera_data.lens = 50.0
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    aim = bpy.data.objects.new("PreviewAim", None)
    aim.location = target
    scene.collection.objects.link(aim)
    track = camera.constraints.new("TRACK_TO")
    track.target = aim
    return camera


def render(name, directory: Path, target=(0.0, 0.0, 0.8), distance=4.2):
    directory.mkdir(parents=True, exist_ok=True)
    camera = _setup(target)
    tiles = []
    for label, azimuth, elevation in VIEWS:
        a, e = math.radians(azimuth), math.radians(elevation)
        camera.location = (
            target[0] + distance * math.cos(e) * math.sin(a),
            target[1] + distance * math.cos(e) * math.cos(a),
            target[2] + distance * math.sin(e),
        )
        path = directory / f"{name}_{label}.png"
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(path))
        pixels = np.empty(SIZE * SIZE * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        tiles.append(pixels.reshape(SIZE, SIZE, 4))
        bpy.data.images.remove(image)
        path.unlink()

    # Blender images start at the bottom-left, so the first row of views goes on top.
    sheet = np.vstack([np.hstack(tiles[2:4]), np.hstack(tiles[0:2])])
    output = bpy.data.images.new(f"{name}_preview", SIZE * 2, SIZE * 2, alpha=True)
    output.pixels.foreach_set(sheet.ravel())
    sheet_path = directory / f"{name}.png"
    output.filepath_raw = str(sheet_path)
    output.file_format = "PNG"
    output.save()
    return sheet_path
