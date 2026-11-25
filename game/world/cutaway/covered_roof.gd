class_name CoveredRoof
extends Area3D

## Reusable covered-area cutaway. Put it under any roof, awning or upper floor, give it collision
## shapes for the covered space, and point `roof` at the geometry to hide. While any visible body
## in `occupant_group` is inside, the roof fades out quickly; it fades back when the last one
## leaves. Point `shadow_caster` at a second instance of the same roof model: it is switched to
## shadows-only and keeps shading the ground, so the space still feels covered. The cutaway never
## builds geometry itself.
##
## When the active camera is under the roof and enough occupants are in its frame, the roof
## hides nothing, so it stays (or turns) solid again. With fewer occupants visible, or any
## visible occupant out of frame, it keeps fading. "Under" means inside the roof's
## horizontal footprint and below its mid-height.
##
## Partial fade: `faded_opacity` is the opacity every roof mesh keeps when fully faded. Any node
## under `roof` can override it for itself and everything beneath it with a `cutaway_opacity`
## metadata value (0 to 1); the nearest one wins. A model script can set it as an object custom
## property instead (`obj["cutaway_opacity"] = 0.2`), which Godot imports into `extras` metadata.

const DEFAULT_OCCUPANTS := &"cutaway_occupants"
const OPACITY_META := &"cutaway_opacity"
const GLTF_EXTRAS := &"extras"

@export var roof: Node3D
## Optional. Without it, the roof stops casting shadows entirely.
@export var shadow_caster: Node3D
@export var occupant_group := DEFAULT_OCCUPANTS
@export_range(0.05, 2.0, 0.05, "suffix:s") var fade_time := 0.4
@export_range(0.0, 1.0, 0.01) var faded_opacity := 0.0
## Visible occupants that must all be in frame before a camera under the roof makes it solid.
@export_range(1, 4) var occupants_to_frame := 1

## 0 is a solid roof, 1 is fully faded out.
var fade := 0.0

var _occupants: Array[Node3D] = []
var _visuals: Array[MeshInstance3D] = []
var _visual_floors: Array[float] = []
var _materials: Array[BaseMaterial3D] = []
var _material_floors: Array[float] = []


func _ready() -> void:
	assert(roof != null, "CoveredRoof requires a roof.")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	for mesh in _meshes_under(roof):
		_take_over(mesh)
	if shadow_caster != null:
		for mesh in _meshes_under(shadow_caster):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_apply()


func _process(delta: float) -> void:
	var target := 1.0 if is_occupied() and not is_seen_from_below() else 0.0
	if fade != target:
		fade = move_toward(fade, target, maxf(delta, 0.0) / fade_time)
		_apply()


func is_occupied() -> bool:
	for body in _occupants:
		if is_instance_valid(body) and body.is_visible_in_tree():
			return true
	return false


func is_seen_from_below() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _visuals.is_empty():
		return false
	var bounds := _visuals[0].global_transform * _visuals[0].get_aabb()
	for index in range(1, _visuals.size()):
		bounds = bounds.merge(_visuals[index].global_transform * _visuals[index].get_aabb())
	var eye := camera.global_position
	var inside := (
		eye.x > bounds.position.x
		and eye.x < bounds.end.x
		and eye.z > bounds.position.z
		and eye.z < bounds.end.z
		and eye.y < bounds.get_center().y
	)
	if not inside:
		return false
	var framed := 0
	for node in get_tree().get_nodes_in_group(occupant_group):
		var body := node as Node3D
		if body == null or not body.is_visible_in_tree():
			continue
		if not camera.is_position_in_frustum(body.global_position):
			return false
		framed += 1
	return framed >= occupants_to_frame


## Opacity `node` keeps when fully faded: its nearest `cutaway_opacity` up to `roof`, else
## `faded_opacity`.
func opacity_floor(node: Node) -> float:
	var current := node
	while current != null:
		if current.has_meta(OPACITY_META):
			return clampf(float(current.get_meta(OPACITY_META)), 0.0, 1.0)
		var extras: Variant = (
			current.get_meta(GLTF_EXTRAS) if current.has_meta(GLTF_EXTRAS) else null
		)
		if extras is Dictionary and (extras as Dictionary).has(OPACITY_META):
			return clampf(float((extras as Dictionary)[OPACITY_META]), 0.0, 1.0)
		if current == roof:
			break
		current = current.get_parent()
	return faded_opacity


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(occupant_group) and not _occupants.has(body):
		_occupants.append(body)


func _on_body_exited(body: Node3D) -> void:
	_occupants.erase(body)


func _meshes_under(node: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		meshes.append(mesh)
	return meshes


func _take_over(mesh: MeshInstance3D) -> void:
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var floor_opacity := opacity_floor(mesh)
	for surface in mesh.mesh.get_surface_count():
		# Each cutaway fades its own copy, so shared materials elsewhere stay solid.
		var material := mesh.get_active_material(surface).duplicate() as BaseMaterial3D
		assert(material != null, "%s needs a BaseMaterial3D to fade." % mesh.name)
		mesh.set_surface_override_material(surface, material)
		_materials.append(material)
		_material_floors.append(floor_opacity)
	_visuals.append(mesh)
	_visual_floors.append(floor_opacity)


func _apply() -> void:
	var eased := ease(fade, 0.6)
	for index in _materials.size():
		var material := _materials[index]
		material.transparency = (
			BaseMaterial3D.TRANSPARENCY_ALPHA
			if fade > 0.0
			else BaseMaterial3D.TRANSPARENCY_DISABLED
		)
		var alpha := lerpf(1.0, _material_floors[index], eased)
		if material is RuledMaterial:
			var ruled := material as RuledMaterial
			var color := ruled.base_color
			color.a = alpha
			ruled.base_color = color
		else:
			material.albedo_color.a = alpha
	for index in _visuals.size():
		_visuals[index].visible = fade < 1.0 or _visual_floors[index] > 0.0
