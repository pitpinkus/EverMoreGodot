class_name PlayerInputComponent
extends Node
## Translates InputMap actions into intent signals for a character and its camera.
## Knows nothing about what it drives; wiring is done in the scene.
##
## R7 exception: mouse-look reads InputEventMouseMotion.relative because mouse
## motion cannot be bound to an InputMap action.

signal move_requested(direction: Vector3, running: bool)
signal jump_requested
## Radians: x = yaw to the right, y = pitch downwards (camera settings already applied).
signal look_requested(delta: Vector2)
## Positive = zoom in.
signal zoom_requested(amount: float)

const WHEEL_ZOOM_STEP: float = 1.0

## Node whose yaw defines "forward" for movement (usually the camera rig).
@export var camera_pivot: Node3D
@export_range(0.0001, 0.05, 0.0001) var mouse_sensitivity: float = 0.003
@export_range(0.1, 20.0, 0.1, "suffix:rad/s") var stick_look_speed: float = 3.0
@export_range(0.1, 20.0, 0.1) var zoom_trigger_rate: float = 4.0

## Copied from SettingsManager.current whenever settings are applied.
var _invert_y: bool = false
var _look_sensitivity: float = 1.0


func _ready() -> void:
	process_physics_priority = -1
	if camera_pivot == null:
		push_error("PlayerInputComponent '%s' has no camera_pivot assigned." % name)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SettingsManager.settings_applied.connect(_on_settings_applied)
	_on_settings_applied(SettingsManager.current)


func _physics_process(_delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	move_requested.emit(_to_world(input), Input.is_action_pressed("run"))


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if not stick.is_zero_approx():
		_emit_look(stick * stick_look_speed * delta)

	var zoom: float = Input.get_axis("camera_zoom_out", "camera_zoom_in")
	if not is_zero_approx(zoom):
		zoom_requested.emit(zoom * zoom_trigger_rate * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_requested.emit()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_emit_look(motion.relative * mouse_sensitivity)
	elif event is InputEventMouseButton and event.is_action_pressed("camera_zoom_in"):
		zoom_requested.emit(WHEEL_ZOOM_STEP)
	elif event is InputEventMouseButton and event.is_action_pressed("camera_zoom_out"):
		zoom_requested.emit(-WHEEL_ZOOM_STEP)
	elif event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _emit_look(delta: Vector2) -> void:
	delta *= _look_sensitivity
	if _invert_y:
		delta.y = -delta.y
	look_requested.emit(delta)


func _on_settings_applied(settings: GameSettings) -> void:
	_invert_y = settings.invert_camera_y
	_look_sensitivity = settings.camera_sensitivity


## Converts a 2D input vector into a flat world-space direction relative to camera_pivot.
func _to_world(input: Vector2) -> Vector3:
	if camera_pivot == null or input.is_zero_approx():
		return Vector3.ZERO
	var basis: Basis = camera_pivot.global_basis
	var right: Vector3 = Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var back: Vector3 = Vector3(basis.z.x, 0.0, basis.z.z).normalized()
	return right * input.x + back * input.y
