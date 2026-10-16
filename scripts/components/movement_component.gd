class_name MovementComponent
extends Node
## Pure movement maths for a character body. Reads no input and touches no body:
## the owner feeds it intent (set_move_input / request_jump) and asks it for a
## new velocity and facing each physics frame.

@export var stats: MovementStats

var _move_direction: Vector3 = Vector3.ZERO
var _running: bool = false
var _facing_direction: Vector3 = Vector3.FORWARD
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func _ready() -> void:
	if stats == null:
		push_error("MovementComponent '%s' has no MovementStats assigned." % name)


## direction is in world space; y is ignored and analog magnitude (≤ 1) is kept.
func set_move_input(direction: Vector3, running: bool) -> void:
	_move_direction = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	_running = running
	set_facing_direction(_move_direction)


func request_jump() -> void:
	if stats == null:
		return
	_jump_buffer_timer = stats.jump_buffer_time


func compute_velocity(current: Vector3, on_floor: bool, delta: float) -> Vector3:
	if stats == null:
		return current
	var velocity: Vector3 = current

	if on_floor:
		_coyote_timer = stats.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = stats.get_jump_speed()
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif not on_floor:
		velocity.y = maxf(velocity.y - stats.gravity * delta, -stats.max_fall_speed)

	var speed: float = stats.run_speed if _running else stats.walk_speed
	var target: Vector3 = _move_direction * speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = _get_horizontal_rate(on_floor)
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	return velocity


## Smoothly turns current_yaw towards the last movement direction.
func step_facing(current_yaw: float, delta: float) -> float:
	if stats == null:
		return current_yaw
	var target_yaw: float = _direction_to_yaw(_facing_direction)
	var weight: float = 1.0 - exp(-delta / stats.turn_smooth_time)
	return lerp_angle(current_yaw, target_yaw, weight)


## Yaw (radians around +Y) of the direction the character wants to face.
func get_facing_yaw() -> float:
	return _direction_to_yaw(_facing_direction)


## Sets the wanted facing directly, e.g. when restoring a save.
func set_facing_yaw(yaw: float) -> void:
	_facing_direction = _yaw_to_direction(yaw)


## Sets the wanted facing to direction (flattened); ignored if it has no horizontal part.
func set_facing_direction(direction: Vector3) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if not flat.is_zero_approx():
		_facing_direction = flat.normalized()


## Yaw 0 faces Vector3.FORWARD (-Z).
static func _direction_to_yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


static func _yaw_to_direction(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _get_horizontal_rate(on_floor: bool) -> float:
	if not on_floor:
		return stats.air_acceleration
	if _move_direction.is_zero_approx():
		return stats.ground_deceleration
	return stats.ground_acceleration
