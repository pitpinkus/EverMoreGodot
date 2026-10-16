class_name MonsterModel
extends Node3D
## Root of every monster model prefab (prefabs/characters/monster_model.tscn and the
## scenes inheriting it). Faces -Z with its feet at the origin. Clips are played by
## key through its AnimationComponent (idle = its idle_key); models without clips
## simply ignore them.

const CLIP_WALK: StringName = &"walk"
const CLIP_ATTACK: StringName = &"attack"
const CLIP_HIT: StringName = &"hit"
const CLIP_FAINT: StringName = &"faint"

## Plays this model's clips. Its animation_overrides map idle_key and the CLIP_* keys to animations.
@export var animation: AnimationComponent
## Where a portrait camera looks from. Null = frame the top of the model's bounds.
@export var portrait_camera: Marker3D
## Render layers given to every mesh of the model (layer 2 "monsters" by default, so
## e.g. the battle reach decal can leave monsters out of its cull mask).
@export_flags_3d_render var render_layers: int = 2


func _ready() -> void:
	_apply_render_layers(self)
	if animation == null:
		push_error("MonsterModel '%s' has no AnimationComponent assigned." % name)
		return
	set_walking(false)


func has_clip(key: StringName) -> bool:
	return animation != null and animation.has_clip(key)


## Loops walk, or the AnimationComponent's idle_key (ignored if the model lacks the clip).
func set_walking(walking: bool) -> void:
	if animation == null:
		return
	var key: StringName = CLIP_WALK if walking else animation.idle_key
	if has_clip(key):
		animation.play(key)


## Plays key's clip once. Await it; returns at once if the model lacks the clip.
func play_once(key: StringName, return_to_idle: bool = true) -> void:
	if has_clip(key):
		await animation.play_once(key, return_to_idle)


## Sets render_layers on every VisualInstance3D below node (FBX meshes included).
func _apply_render_layers(node: Node) -> void:
	for child: Node in node.get_children():
		var visual: VisualInstance3D = child as VisualInstance3D
		if visual != null:
			visual.layers = render_layers
		_apply_render_layers(child)
