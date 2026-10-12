class_name MovementStats
extends Resource
## Tunable movement values shared by every character that uses a MovementComponent.

@export_group("Ground")
@export_range(0.0, 50.0, 0.1, "suffix:m/s") var walk_speed: float = 6.0
@export_range(0.0, 50.0, 0.1, "suffix:m/s") var run_speed: float = 9.0
@export_range(0.0, 500.0, 0.5, "suffix:m/s²") var ground_acceleration: float = 60.0
@export_range(0.0, 500.0, 0.5, "suffix:m/s²") var ground_deceleration: float = 80.0

@export_group("Air")
@export_range(0.0, 500.0, 0.5, "suffix:m/s²") var air_acceleration: float = 20.0
@export_range(0.0, 200.0, 0.5, "suffix:m/s²") var gravity: float = 25.0
@export_range(0.0, 200.0, 0.5, "suffix:m/s") var max_fall_speed: float = 40.0

@export_group("Jump")
@export_range(0.0, 10.0, 0.05, "suffix:m") var jump_height: float = 1.2
@export_range(0.0, 1.0, 0.01, "suffix:s") var coyote_time: float = 0.12
@export_range(0.0, 1.0, 0.01, "suffix:s") var jump_buffer_time: float = 0.15

@export_group("Turning")
@export_range(0.01, 2.0, 0.01, "suffix:s") var turn_smooth_time: float = 0.1


## Initial upward speed needed to reach jump_height under gravity.
func get_jump_speed() -> float:
	return sqrt(2.0 * gravity * jump_height)
