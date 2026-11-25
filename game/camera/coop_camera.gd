class_name CoopCamera
extends Camera3D

@export var offset := Vector3(11.0, 10.0, 15.0)
@export var target_height := 0.8
@export var max_speed := 4.0
@export var max_zoom_speed := 2.0
@export var zoom_per_meter := 0.5
@export var max_zoom := 6.0

var targets: Array[Node3D] = []
var zoom := 0.0


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	follow(delta)


func snap_to_targets() -> void:
	var active := _active_targets()
	if active.is_empty():
		return
	var focus := _focus_point(active)
	zoom = _desired_zoom(active)
	global_position = _desired_position(focus)
	look_at(focus, Vector3.UP)


func follow(delta: float) -> void:
	var active := _active_targets()
	if active.is_empty():
		return
	var step := maxf(delta, 0.0)
	var focus := _focus_point(active)
	zoom = move_toward(zoom, _desired_zoom(active), max_zoom_speed * step)
	global_position = global_position.move_toward(_desired_position(focus), max_speed * step)
	look_at(focus, Vector3.UP)


func _active_targets() -> Array[Node3D]:
	var active: Array[Node3D] = []
	for target in targets:
		if is_instance_valid(target) and target.is_visible_in_tree():
			active.append(target)
	return active


func _focus_point(active: Array[Node3D]) -> Vector3:
	var center := Vector3.ZERO
	for target in active:
		center += target.global_position
	center /= float(active.size())
	center.y += target_height
	return center


func _desired_zoom(active: Array[Node3D]) -> float:
	var spread := 0.0
	for a in active:
		for b in active:
			spread = maxf(spread, a.global_position.distance_to(b.global_position))
	return minf(spread * zoom_per_meter, max_zoom)


func _desired_position(focus: Vector3) -> Vector3:
	var framing := framing_offset(focus)
	return focus + framing + framing.normalized() * zoom


## The base offset, eased toward the strongest CameraZone around the focus point.
func framing_offset(focus: Vector3) -> Vector3:
	if not is_inside_tree():
		return offset
	var strongest: CameraZone = null
	var strongest_weight := 0.0
	for zone: CameraZone in get_tree().get_nodes_in_group(CameraZone.GROUP):
		var weight := zone.weight_at(focus)
		if weight > strongest_weight:
			strongest = zone
			strongest_weight = weight
	if strongest == null:
		return offset
	return strongest.apply_to(offset, strongest_weight)
