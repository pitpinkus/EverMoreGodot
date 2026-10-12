class_name Character
extends CharacterBody3D
## Base for every walking creature/person. Owns the physics body and delegates
## movement maths to %MovementComponent. Has no knowledge of input or AI:
## controllers call move() and jump().

@onready var _movement: MovementComponent = %MovementComponent
@onready var _visual: Node3D = %Visual


func move(direction: Vector3, running: bool = false) -> void:
	_movement.set_move_input(direction, running)


func jump() -> void:
	_movement.request_jump()


func _physics_process(delta: float) -> void:
	velocity = _movement.compute_velocity(velocity, is_on_floor(), delta)
	move_and_slide()
	_visual.rotation.y = _movement.step_facing(_visual.rotation.y, delta)
