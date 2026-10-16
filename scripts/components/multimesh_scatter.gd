@tool
class_name MultiMeshScatter
extends Node3D
## Fills a rectangular area (x/z centred on this node, standing on y = 0) with
## randomly placed copies of mesh at a fixed density, so a bigger area gets more
## copies instead of stretched ones. Call set_area (e.g. from
## EncounterTrigger.size_changed). Instances live in an internal MultiMeshInstance3D
## that is rebuilt on change and never saved into the scene.

@export var mesh: Mesh:
	set(value):
		mesh = value
		_regenerate()
@export var material: Material:
	set(value):
		material = value
		if _instance != null:
			_instance.material_override = material
## Copies per square metre of area.
@export_range(0.0, 100.0, 0.1, "suffix:/m²") var density: float = 6.0:
	set(value):
		density = value
		_regenerate()
## Height of each copy in metres, picked between x (min) and y (max).
@export var height_range: Vector2 = Vector2(0.6, 1.0):
	set(value):
		height_range = value
		_regenerate()
## Same seed + same area = same layout.
@export var random_seed: int = 0:
	set(value):
		random_seed = value
		_regenerate()
## Upper bound on copies, however large the area gets.
@export_range(1, 100000, 1) var max_instances: int = 4000:
	set(value):
		max_instances = value
		_regenerate()

var _area: Vector2 = Vector2.ZERO
var _instance: MultiMeshInstance3D


func _ready() -> void:
	_instance = MultiMeshInstance3D.new()
	_instance.material_override = material
	add_child(_instance, false, Node.INTERNAL_MODE_FRONT)
	_regenerate()


## Covers size.x by size.z metres (size.y is ignored).
func set_area(size: Vector3) -> void:
	_area = Vector2(maxf(size.x, 0.0), maxf(size.z, 0.0))
	_regenerate()


func _regenerate() -> void:
	if _instance == null:
		return
	if mesh == null:
		_instance.multimesh = null
		return
	var count: int = mini(roundi(density * _area.x * _area.y), max_instances)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	var bounds: AABB = mesh.get_aabb()
	var mesh_height: float = maxf(bounds.size.y, 0.001)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed
	for i: int in count:
		var height_scale: float = rng.randf_range(height_range.x, height_range.y) / mesh_height
		var basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(1.0, height_scale, 1.0))
		var origin: Vector3 = Vector3(
			rng.randf_range(-0.5, 0.5) * _area.x,
			-bounds.position.y * height_scale,
			rng.randf_range(-0.5, 0.5) * _area.y)
		multimesh.set_instance_transform(i, Transform3D(basis, origin))
	_instance.multimesh = multimesh
