class_name PlayerMoveState
extends PlayerState
## Moving on the floor. Used by both the Walk and Run nodes; speed follows intent.running.


func _drive_character(_delta: float) -> void:
	move_requested.emit(intent.move_direction, intent.running)
