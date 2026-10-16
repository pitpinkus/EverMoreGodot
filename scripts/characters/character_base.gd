class_name Character
extends CharacterBody3D
## Base for every walking creature/person. Owns the physics body and delegates
## movement maths to %MovementComponent. Has no knowledge of input or AI:
## controllers call move() and jump().
## With save_key set, position and facing are saved and loaded through SaveSystem
## (stored as a RespawnPoint dictionary without a level path).

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


## Puts the character at at, facing yaw (radians, 0 = -Z) right away, standing still.
func place(at: Transform3D, yaw: float) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	_movement.set_facing_yaw(yaw)
	_visual.rotation.y = yaw


## Yaw (radians, 0 = -Z) the character faces or is turning to.
func get_facing_yaw() -> float:
	return _movement.get_facing_yaw()


## Turns (smoothly) to look at point; height is ignored.
func face_towards(point: Vector3) -> void:
	_movement.set_facing_direction(point - global_position)


func _on_save_started() -> void:
	SaveSystem.set_state(save_key, RespawnPoint.create("", global_transform, get_facing_yaw()).to_dict())


func _on_load_completed(_info: SaveSlotInfo) -> void:
	var state: Variant = SaveSystem.get_state(save_key)
	if state is Dictionary:
		var point: RespawnPoint = RespawnPoint.from_dict(state)
		place(point.transform, point.facing_yaw)


func _physics_process(delta: float) -> void:
	velocity = _movement.compute_velocity(velocity, is_on_floor(), delta)
	move_and_slide()
	_visual.rotation.y = _movement.step_facing(_visual.rotation.y, delta)
