class_name CameraZone
extends Node3D

## A framing override the camera eases into as its targets approach a place. Inside the
## rectangle the override is full strength; it fades out over `falloff` meters around it.

const GROUP := &"camera_zones"

## Rectangle on the ground (local X and Z), centered on this node.
@export var size := Vector2(8.0, 8.0)
@export_range(0.0, 20.0, 0.1, "suffix:m") var falloff := 4.0
## Orbits the camera around its targets; negative swings it to the left so it looks right.
@export_range(-180.0, 180.0, 1.0, "degrees") var yaw_degrees := 0.0
## Below 1 brings the camera closer.
@export_range(0.2, 2.0, 0.01) var distance_scale := 1.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func weight_at(point: Vector3) -> float:
	var local := to_local(point)
	var outside := (
		Vector2(maxf(absf(local.x) - size.x * 0.5, 0.0), maxf(absf(local.z) - size.y * 0.5, 0.0))
		. length()
	)
	if falloff <= 0.0:
		return 1.0 if outside <= 0.0 else 0.0
	return 1.0 - smoothstep(0.0, falloff, outside)


func apply_to(offset: Vector3, weight: float) -> Vector3:
	var rotated := offset.rotated(Vector3.UP, deg_to_rad(yaw_degrees) * weight)
	return rotated * lerpf(1.0, distance_scale, weight)
