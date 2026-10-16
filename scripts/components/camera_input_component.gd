class_name CameraInputComponent
extends Node
## Translates camera InputMap actions (stick/arrow look, zoom) and mouse look into
## intent signals for a ThirdPersonCamera. Knows nothing about what it drives;
## wiring is done in the scene (look_requested -> rotate_view, zoom_requested -> zoom).
##
## R7 exception: mouse-look reads InputEventMouseMotion.relative because mouse
## motion cannot be bound to an InputMap action.

## Radians: x = yaw to the right, y = pitch downwards (camera settings already applied).
signal look_requested(delta: Vector2)
## Positive = zoom in.
signal zoom_requested(amount: float)

const WHEEL_ZOOM_STEP: float = 1.0

@export_range(0.0001, 0.05, 0.0001) var mouse_sensitivity: float = 0.003
@export_range(0.1, 20.0, 0.1, "suffix:rad/s") var stick_look_speed: float = 3.0
@export_range(0.1, 20.0, 0.1) var zoom_trigger_rate: float = 4.0
## Capture the mouse cursor (for mouse look) when the scene starts.
@export var capture_mouse_on_ready: bool = true
## The capture_mouse action (click) captures the cursor again, e.g. after a menu freed it.
@export var capture_on_click: bool = true

## Copied from SettingsManager.current whenever settings are applied.
var _invert_y: bool = false
var _look_sensitivity: float = 1.0
var _look_input_enabled: bool = true


func _ready() -> void:
	if capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SettingsManager.settings_applied.connect(_on_settings_applied)
	_on_settings_applied(SettingsManager.current)


## Turns stick/key look on or off (e.g. while the same keys pick something else).
## Mouse look and zoom are not affected.
func set_look_input_enabled(enabled: bool) -> void:
	_look_input_enabled = enabled


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if _look_input_enabled and not stick.is_zero_approx():
		_emit_look(stick * stick_look_speed * delta)

	var zoom: float = Input.get_axis("camera_zoom_out", "camera_zoom_in")
	if not is_zero_approx(zoom):
		zoom_requested.emit(zoom * zoom_trigger_rate * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_emit_look(motion.relative * mouse_sensitivity)
	elif event is InputEventMouseButton and event.is_action_pressed("camera_zoom_in"):
		zoom_requested.emit(WHEEL_ZOOM_STEP)
	elif event is InputEventMouseButton and event.is_action_pressed("camera_zoom_out"):
		zoom_requested.emit(-WHEEL_ZOOM_STEP)
	elif capture_on_click and event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _emit_look(delta: Vector2) -> void:
	delta *= _look_sensitivity
	if _invert_y:
		delta.y = -delta.y
	look_requested.emit(delta)


func _on_settings_applied(settings: GameSettings) -> void:
	_invert_y = settings.invert_camera_y
	_look_sensitivity = settings.camera_sensitivity
