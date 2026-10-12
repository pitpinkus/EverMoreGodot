@abstract
class_name PlayerState
extends State
## Base for all player locomotion states. States never drive the character
## directly (R4): they emit move_requested / jump_requested, which
## PlayerStateMachine relays upward. The character is only read (floor, velocity).
##
## R3: third level of our own classes on purpose. It holds the injected
## Character/PlayerIntent and the jump + transition logic every player state
## shares, which would otherwise be duplicated in each state (R1).

signal move_requested(direction: Vector3, running: bool)
signal jump_requested

## Must match the state node names in prefabs/components/player_state_machine.tscn.
const IDLE: StringName = &"Idle"
const WALK: StringName = &"Walk"
const RUN: StringName = &"Run"
const JUMP: StringName = &"Jump"
const FALL: StringName = &"Fall"

## Read-only here: used for is_on_floor() and velocity.
var character: Character
var intent: PlayerIntent


func setup(p_character: Character, p_intent: PlayerIntent) -> void:
	character = p_character
	intent = p_intent


func physics_update(delta: float) -> void:
	_drive_character(delta)
	if intent.consume_jump():
		jump_requested.emit()
	var next: StringName = _next_locomotion_state()
	if next != name:
		transition_requested.emit(next)


## Emits this state's movement intent via move_requested.
@abstract func _drive_character(delta: float) -> void


func _next_locomotion_state() -> StringName:
	if not character.is_on_floor():
		return JUMP if character.velocity.y > 0.0 else FALL
	if intent.move_direction.is_zero_approx():
		return IDLE
	return RUN if intent.running else WALK
