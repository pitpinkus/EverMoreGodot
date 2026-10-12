@tool
class_name Block
extends StaticBody3D
## Box-shaped blockout prop. Mesh and collision are resized together from `size`.
## Origin sits at the bottom centre, or at the top centre with top_at_origin.

@export var size: Vector3 = Vector3(2.0, 1.0, 2.0):
	set(value):
		size = value
		_apply()

@export var material: Material:
	set(value):
		material = value
		_apply()

@export var top_at_origin: bool = false:
	set(value):
		top_at_origin = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var mesh_instance: MeshInstance3D = %Mesh
	var collision: CollisionShape3D = %CollisionShape3D

	var box_mesh: BoxMesh = mesh_instance.mesh as BoxMesh
	if box_mesh != null:
		box_mesh.size = size
	else:
		push_warning("Block '%s': %%Mesh has no BoxMesh." % name)

	var box_shape: BoxShape3D = collision.shape as BoxShape3D
	if box_shape != null:
		box_shape.size = size
	else:
		push_warning("Block '%s': %%CollisionShape3D has no BoxShape3D." % name)

	mesh_instance.material_override = material

	var half_height: float = size.y * 0.5
	var offset: Vector3 = Vector3.DOWN * half_height if top_at_origin else Vector3.UP * half_height
	mesh_instance.position = offset
	collision.position = offset
