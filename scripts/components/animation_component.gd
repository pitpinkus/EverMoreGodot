class_name AnimationComponent
extends Node
## Model-agnostic animation driver. Clips are asked for by key (a state name, or a
## monster clip like idle / walk / attack / hit / faint); animation_overrides maps a
## key to the AnimationPlayer's animation name. Either connect a StateMachine's
## state_changed to _on_state_changed, or call play / play_once from code.
## Without an animation_player (e.g. a model with no clips) every request is ignored.

## Lower bound for speed_scale when timing play_once (avoids dividing by zero).
const MIN_SPEED_SCALE: float = 0.001

@export var animation_player: AnimationPlayer
## Key → animation name. Keys not listed play an animation of the same name.
@export var animation_overrides: Dictionary[StringName, StringName] = {}
@export_range(0.0, 1.0, 0.01, "suffix:s") var blend_time: float = 0.15
## Key play_once returns to when its clip is done.
@export var idle_key: StringName = &"idle"

var _warned_missing: Dictionary[StringName, bool] = {}


func _ready() -> void:
	if animation_player == null and not animation_overrides.is_empty():
		push_error("AnimationComponent '%s' has animation_overrides but no animation_player." % name)


## True if key resolves to an animation the player has.
func has_clip(key: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(_resolve(key))


## Blends to key's clip (looping clips keep looping). Missing clips are warned about
## once and the current animation keeps playing.
func play(key: StringName) -> void:
	if animation_player == null:
		return
	if not has_clip(key):
		_warn_missing(key)
		return
	animation_player.play(_resolve(key), blend_time)


## Plays key's clip once. Await it: returns when the clip ends, then blends back to
## idle_key if return_to_idle and nothing else was started meanwhile. Returns at once
## without the clip.
func play_once(key: StringName, return_to_idle: bool = true) -> void:
	if not has_clip(key):
		return
	var anim: StringName = _resolve(key)
	animation_player.play(anim, blend_time)
	var speed: float = maxf(absf(animation_player.speed_scale), MIN_SPEED_SCALE)
	await get_tree().create_timer(animation_player.get_animation(anim).length / speed, false).timeout
	# assigned_animation stays set after a one-shot clip ends; it changes if another clip started.
	if return_to_idle and animation_player.assigned_animation == anim:
		play(idle_key)


func _on_state_changed(_from: StringName, to: StringName) -> void:
	play(to)


func _resolve(key: StringName) -> StringName:
	return animation_overrides.get(key, key)


## Warns once per animation name.
func _warn_missing(key: StringName) -> void:
	var anim: StringName = _resolve(key)
	if not _warned_missing.has(anim):
		_warned_missing[anim] = true
		push_warning("AnimationComponent '%s': no animation '%s' for '%s'." % [name, anim, key])
