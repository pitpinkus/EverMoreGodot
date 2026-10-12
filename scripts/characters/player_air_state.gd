class_name PlayerAirState
extends PlayerState
## Airborne. Used by both the Jump and Fall nodes. Keeps the run state from
## takeoff so a sprint cannot be started mid-air.


func enter(previous: StringName) -> void:
	if previous != JUMP and previous != FALL:
		intent.running_at_takeoff = intent.running


func _drive_character(_delta: float) -> void:
	move_requested.emit(intent.move_direction, intent.running_at_takeoff)
