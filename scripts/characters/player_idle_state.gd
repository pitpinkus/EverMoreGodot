class_name PlayerIdleState
extends PlayerState
## Standing still on the floor.


func _drive_character(_delta: float) -> void:
	move_requested.emit(Vector3.ZERO, false)
