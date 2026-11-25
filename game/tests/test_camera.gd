extends GutTest

const CAMERA_SCENE := preload("res://camera/coop_camera.tscn")


func test_camera_caps_follow_and_zoom_for_multiple_targets() -> void:
	var first := _add_target(Vector3.ZERO)
	var second := _add_target(Vector3.ZERO)
	var camera := _add_camera([first, second])
	first.global_position = Vector3(-15, 0, 0)
	second.global_position = Vector3(15, 0, 0)
	var previous := camera.global_position
	camera.follow(0.25)
	assert_lte(camera.zoom, camera.max_zoom_speed * 0.25 + 0.001)
	assert_lte(previous.distance_to(camera.global_position), camera.max_speed * 0.25 + 0.001)


func test_camera_ignores_hidden_and_freed_targets() -> void:
	var first := _add_target(Vector3.ZERO)
	var hidden := _add_target(Vector3(20, 0, 0))
	hidden.visible = false
	var removed := Node3D.new()
	add_child(removed)
	var camera := _add_camera([first, hidden, removed])
	removed.free()
	camera.snap_to_targets()
	assert_eq(camera.zoom, 0.0)
	assert_almost_eq(
		camera.global_position,
		camera.offset + Vector3.UP * camera.target_height,
		Vector3.ONE * 0.001
	)
	camera.targets.clear()
	var previous := camera.global_position
	camera.follow(1.0)
	assert_eq(camera.global_position, previous)


func test_camera_uses_strongest_zone_and_restores_base_framing_outside() -> void:
	var zone := CameraZone.new()
	zone.yaw_degrees = 90.0
	zone.distance_scale = 0.5
	add_child_autofree(zone)
	var camera := _add_camera([_add_target(Vector3.ZERO)])
	assert_almost_eq(
		camera.framing_offset(Vector3.ZERO),
		camera.offset.rotated(Vector3.UP, PI * 0.5) * 0.5,
		Vector3.ONE * 0.001
	)
	assert_eq(camera.framing_offset(Vector3(100, 0, 100)), camera.offset)
	assert_almost_eq(zone.weight_at(Vector3(6, 0, 0)), 0.5, 0.001)


func _add_target(start: Vector3) -> Node3D:
	var target := Node3D.new()
	add_child_autofree(target)
	target.global_position = start
	return target


func _add_camera(targets: Array[Node3D]) -> CoopCamera:
	var camera := CAMERA_SCENE.instantiate() as CoopCamera
	add_child_autofree(camera)
	camera.set_process(false)
	camera.targets = targets
	camera.snap_to_targets()
	return camera
