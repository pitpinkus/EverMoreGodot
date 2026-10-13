class_name AnimationComponent
extends Node
## Model-agnostic animation driver. Plays the animation named after the current
## state on the assigned AnimationPlayer. Connect a StateMachine's state_changed
## signal to _on_state_changed in the scene.

@export var animation_player: AnimationPlayer
## State name → animation name. States not listed play an animation of the same name.
@export var animation_overrides: Dictionary[StringName, StringName] = {}
@export_range(0.0, 1.0, 0.01, "suffix:s") var blend_time: float = 0.15

var _warned_missing: Dictionary[StringName, bool] = {}


func _ready() -> void:
	if animation_player == null:
		push_error("AnimationComponent '%s' has no animation_player assigned." % name)


func _on_state_changed(_from: StringName, to: StringName) -> void:
	if animation_player == null:
		return
	var anim: StringName = animation_overrides.get(to, to)
	if not animation_player.has_animation(anim):
		# Warn once per name and keep the current animation playing.
		if not _warned_missing.has(anim):
			_warned_missing[anim] = true
			push_warning("AnimationComponent '%s': no animation '%s' for state '%s'." % [name, anim, to])
		return
	animation_player.play(anim, blend_time)
