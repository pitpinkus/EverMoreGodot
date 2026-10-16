class_name PortraitStudio
extends SubViewport
## Off-screen photo booth for monster portraits (prefabs/ui/portrait_studio.tscn):
## its own World3D with a transparent background, %Camera, a key light and an
## environment. render() poses a species' MonsterModel in %ModelSlot, frames it
## through the model's PortraitCamera (or the top part of its bounds), draws one
## frame and returns a copy of the image. Used by the PortraitCache autoload.

## Fraction of the model's height (from the top) framed when it has no PortraitCamera.
@export_range(0.05, 1.0, 0.01) var fallback_top_fraction: float = 0.45
## Extra room around the framed part (1 = touching the edges).
@export_range(1.0, 3.0, 0.05) var framing_margin: float = 1.15

@onready var _camera: Camera3D = %Camera
@onready var _model_slot: Node3D = %ModelSlot


func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_DISABLED


## A portrait of species' model, or null without a model. Await it; one render at a time.
func render(species: SpeciesData) -> Texture2D:
	var model: MonsterModel = species.instantiate_model()
	if model == null:
		return null
	_model_slot.add_child(model)
	_frame(model)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image: Image = get_texture().get_image()
	_model_slot.remove_child(model)
	model.queue_free()
	return ImageTexture.create_from_image(image) if image != null else null


func _frame(model: MonsterModel) -> void:
	if model.portrait_camera != null:
		_camera.global_transform = model.portrait_camera.global_transform
		return
	var bounds: AABB = _get_bounds(model)
	var height: float = bounds.size.y * fallback_top_fraction
	var top: Vector3 = bounds.get_center() + Vector3(0.0, bounds.size.y / 2.0, 0.0)
	var target: Vector3 = top - Vector3(0.0, height / 2.0, 0.0)
	var half_extent: float = maxf(height, maxf(bounds.size.x, bounds.size.z)) / 2.0 * framing_margin
	var distance: float = half_extent / tan(deg_to_rad(_camera.fov) / 2.0) + bounds.size.z / 2.0
	# Models face -Z, so the camera stands in front of them on -Z looking back at +Z.
	_camera.look_at_from_position(target + Vector3(0.0, 0.0, -distance), target)


## Merged world-space bounds of every mesh in model.
static func _get_bounds(model: Node3D) -> AABB:
	var bounds: AABB = AABB(model.global_position, Vector3.ZERO)
	var pending: Array[Node] = [model]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual != null:
			bounds = bounds.merge(visual.global_transform * visual.get_aabb())
	return bounds
