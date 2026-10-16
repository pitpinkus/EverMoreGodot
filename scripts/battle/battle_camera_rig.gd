class_name BattleCameraRig
extends Node3D
## The battle camera's focus point (the ThirdPersonCamera orbits it as a child). Glides
## to points with focus_on, and pans with the move_* actions relative to the camera's
## yaw while set_pan_mode allows it. Never leaves the arena circle from set_bounds.
## Every focus change is reported with focus_moved.

## The focus point changed (pan or focus_on glide).
signal focus_moved(point: Vector3)

## OFF: no panning. KEYBOARD_ONLY: pans only while the keyboard/mouse is the active
## device (the stick drives menu focus). ALL: keyboard and stick pan.
enum PanMode { OFF, KEYBOARD_ONLY, ALL }

## Its yaw defines "forward" for panning (the ThirdPersonCamera).
@export var yaw_pivot: Node3D
@export_range(0.5, 50.0, 0.1, "suffix:m/s") var pan_speed: float = 8.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var focus_duration: float = 0.5

var _pan_mode: PanMode = PanMode.OFF
var _bounds_center: Vector3 = Vector3.ZERO
var _bounds_radius: float = INF
var _tween: Tween


## The focus stays within radius of center (on the ground plane).
func set_bounds(center: Vector3, radius: float) -> void:
	_bounds_center = center
	_bounds_radius = radius


func set_pan_mode(mode: PanMode) -> void:
	_pan_mode = mode


## Glides the focus to point (clamped to the bounds) over focus_duration.
func focus_on(point: Vector3) -> void:
	_stop_glide()
	_tween = create_tween()
	_tween.tween_method(_set_focus, global_position, _clamp(point), focus_duration)


func _process(delta: float) -> void:
	if _pan_mode == PanMode.OFF:
		return
	if _pan_mode == PanMode.KEYBOARD_ONLY \
			and InputDeviceTracker.current_device == InputDeviceTracker.Device.GAMEPAD:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.is_zero_approx():
		return
	_stop_glide()
	_set_focus(global_position + CameraRelativeInput.to_world(input, yaw_pivot) * pan_speed * delta)


func _set_focus(point: Vector3) -> void:
	global_position = _clamp(point)
	focus_moved.emit(global_position)


func _clamp(point: Vector3) -> Vector3:
	var offset: Vector3 = BattleFormulas.flat_offset(_bounds_center, point).limit_length(_bounds_radius)
	return Vector3(_bounds_center.x + offset.x, point.y, _bounds_center.z + offset.z)


func _stop_glide() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
