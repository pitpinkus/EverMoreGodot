class_name Character
extends CharacterBody3D
## Base for every walking creature/person. Owns the physics body and delegates
## movement maths to %MovementComponent. Has no knowledge of input or AI:
## controllers call move() and jump().
## With save_key set, position and facing are saved and loaded through SaveSystem.

const SAVE_KEY_TRANSFORM: String = "transform"
const SAVE_KEY_FACING_YAW: String = "facing_yaw"

## Key of this character's entry in SaveSystem. Must be unique game-wide; empty = not saved.
@export var save_key: StringName

@onready var _movement: MovementComponent = %MovementComponent
@onready var _visual: Node3D = %Visual


func _ready() -> void:
	if save_key.is_empty():
		return
	SaveSystem.save_started.connect(_on_save_started)
	SaveSystem.load_completed.connect(_on_load_completed)


func move(direction: Vector3, running: bool = false) -> void:
	_movement.set_move_input(direction, running)


func jump() -> void:
	_movement.request_jump()


func _on_save_started() -> void:
	SaveSystem.set_state(save_key, {
		SAVE_KEY_TRANSFORM: global_transform,
		SAVE_KEY_FACING_YAW: _movement.get_facing_yaw(),
	})


func _on_load_completed(_info: SaveSlotInfo) -> void:
	var state: Variant = SaveSystem.get_state(save_key)
	if state is Dictionary:
		_apply_save_state(state)


## Puts the character back where _on_save_started() recorded it, standing still.
func _apply_save_state(state: Dictionary) -> void:
	var saved_transform: Variant = state.get(SAVE_KEY_TRANSFORM)
	if saved_transform is Transform3D:
		global_transform = saved_transform
	else:
		push_warning("Character '%s': save state has no valid '%s'." % [name, SAVE_KEY_TRANSFORM])
	velocity = Vector3.ZERO
	var yaw: Variant = state.get(SAVE_KEY_FACING_YAW)
	if yaw is float:
		_movement.set_facing_yaw(yaw)
		_visual.rotation.y = yaw


func _physics_process(delta: float) -> void:
	velocity = _movement.compute_velocity(velocity, is_on_floor(), delta)
	move_and_slide()
	_visual.rotation.y = _movement.step_facing(_visual.rotation.y, delta)
