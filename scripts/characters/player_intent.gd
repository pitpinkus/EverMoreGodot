class_name PlayerIntent
extends RefCounted
## What the player currently wants to do, shared between PlayerStateMachine and
## its states. Filled from PlayerInputComponent signals.

## World-space, flat, length ≤ 1.
var move_direction: Vector3 = Vector3.ZERO
var running: bool = false
## Run flag locked at takeoff by PlayerAirState. Lives here (not in the state) so
## it survives the Jump → Fall hand-off between two separate air state nodes.
var running_at_takeoff: bool = false
var _jump_pending: bool = false


func request_jump() -> void:
	_jump_pending = true


## Returns true once per request_jump() call, then clears the request.
func consume_jump() -> bool:
	var pending: bool = _jump_pending
	_jump_pending = false
	return pending
