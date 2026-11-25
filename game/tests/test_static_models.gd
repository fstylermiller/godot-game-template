extends GutTest

## Enforces "everything visible and static is a model": shipped scenes and scripts may not
## build geometry from primitives or code. Test fixtures are exempt because they never ship.

const FIXTURE_DIRS: Array[String] = ["res://addons", "res://tests"]
const PRIMITIVE := (
	'\\[sub_resource type="(Box|Plane|Sphere|Cylinder|Capsule|Prism|Torus|Quad|Array'
	+ '|Immediate|Text|Ribbon|Tube)Mesh"'
)
const GENERATED := "\\b(\\w+Mesh\\.new|MeshInstance3D\\.new|SurfaceTool\\.new)\\("

## Documented exceptions, keyed by path, with the reason (see models/README.md).
const EXCEPTIONS := {}


func test_shipped_visuals_come_from_models() -> void:
	var primitive := RegEx.create_from_string(PRIMITIVE)
	var generated := RegEx.create_from_string(GENERATED)
	var offenders: Array[String] = []
	for path in _shipped_files("res://"):
		if EXCEPTIONS.has(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		var pattern := primitive if path.ends_with(".tscn") else generated
		if pattern.search(text) != null:
			offenders.append(path)
	assert_eq(
		offenders,
		[] as Array[String],
		"Static visuals must be models (models/<name>.py), or a documented moving exception."
	)


func _shipped_files(dir: String) -> Array[String]:
	var found: Array[String] = []
	if dir in FIXTURE_DIRS or dir.begins_with("res://."):
		return found
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tscn") or file.ends_with(".gd"):
			found.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		found.append_array(_shipped_files(dir.path_join(sub)))
	return found
