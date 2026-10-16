class_name PlayerInputComponent
extends CameraInputComponent
## Overworld player input: everything CameraInputComponent does (look, zoom, mouse
## capture) plus camera-relative movement and jumping as intent signals for a
## character. Knows nothing about what it drives; wiring is done in the scene.

signal move_requested(direction: Vector3, running: bool)
signal jump_requested

## Node whose yaw defines "forward" for movement (usually the camera rig).
@export var camera_pivot: Node3D


func _ready() -> void:
	process_physics_priority = -1
	if camera_pivot == null:
		push_error("PlayerInputComponent '%s' has no camera_pivot assigned." % name)
	super()


func _physics_process(_delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	move_requested.emit(CameraRelativeInput.to_world(input, camera_pivot), Input.is_action_pressed("run"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_requested.emit()
	else:
		super(event)
