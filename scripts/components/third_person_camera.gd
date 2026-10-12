class_name ThirdPersonCamera
extends Node3D
## Orbit camera rig. Yaw rotates this node, pitch rotates %Pitch, and zoom drives
## %SpringArm3D length. Reads no input: call rotate_view() and zoom() from outside.

@export_group("Pitch")
@export_range(-89.0, 0.0, 0.5, "suffix:°") var pitch_min_deg: float = -50.0
@export_range(-89.0, 89.0, 0.5, "suffix:°") var pitch_max_deg: float = 10.0
@export_range(-89.0, 89.0, 0.5, "suffix:°") var initial_pitch_deg: float = -17.5

@export_group("Zoom")
@export_range(0.5, 50.0, 0.1, "suffix:m") var distance: float = 5.0
@export_range(0.5, 50.0, 0.1, "suffix:m") var min_distance: float = 3.0
@export_range(0.5, 50.0, 0.1, "suffix:m") var max_distance: float = 15.0
@export_range(0.1, 10.0, 0.1, "suffix:m") var zoom_step: float = 2.0
@export_range(0.1, 50.0, 0.1) var zoom_smoothing: float = 10.0

var _target_distance: float = 0.0

@onready var _pitch: Node3D = %Pitch
@onready var _spring_arm: SpringArm3D = %SpringArm3D


func _ready() -> void:
	_pitch.rotation.x = deg_to_rad(clampf(initial_pitch_deg, pitch_min_deg, pitch_max_deg))
	_target_distance = clampf(distance, min_distance, max_distance)
	_spring_arm.spring_length = _target_distance


## delta in radians: x = yaw to the right, y = pitch downwards.
func rotate_view(delta: Vector2) -> void:
	rotation.y -= delta.x
	_pitch.rotation.x = clampf(
		_pitch.rotation.x - delta.y,
		deg_to_rad(pitch_min_deg),
		deg_to_rad(pitch_max_deg)
	)


## Positive amount zooms in (shorter arm).
func zoom(amount: float) -> void:
	_target_distance = clampf(_target_distance - amount * zoom_step, min_distance, max_distance)


func _process(delta: float) -> void:
	var weight: float = 1.0 - exp(-zoom_smoothing * delta)
	_spring_arm.spring_length = lerpf(_spring_arm.spring_length, _target_distance, weight)
