class_name Projectile
extends Node3D
## A shot flying in an arc from one point to another (fireball, orb, ...). %Core is the
## visible body, hidden on arrival; %Trail stops emitting on arrival and the projectile
## frees itself once the trail has faded. Spawned by ActionVfxPlayer.

## Arc height factor: 4 * t * (1 - t) peaks at 1.0 halfway.
const ARC_SHAPE: float = 4.0

## Flight speed along the straight line between the points.
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var speed: float = 14.0
## Height of the arc's top above the straight line.
@export_range(0.0, 10.0, 0.05, "suffix:m") var arc_height: float = 0.6
## Shortest flight, so very close targets still show the shot.
@export_range(0.0, 2.0, 0.01, "suffix:s") var min_flight_time: float = 0.15
## Time the trail is left to fade after arrival before the node is freed.
@export_range(0.0, 5.0, 0.05, "suffix:s") var trail_linger: float = 0.6

var _from: Vector3
var _to: Vector3

@onready var _core: Node3D = %Core
@onready var _trail: GPUParticles3D = %Trail


## Flies from from_point to to_point. Await it: returns on arrival (the node frees itself later).
func fly(from_point: Vector3, to_point: Vector3) -> void:
	_from = from_point
	_to = to_point
	global_position = from_point
	var flight_time: float = maxf(from_point.distance_to(to_point) / speed, min_flight_time)
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, flight_time)
	await tween.finished
	_core.hide()
	_trail.emitting = false
	get_tree().create_timer(trail_linger, false).timeout.connect(queue_free)


## Puts the projectile at progress (0..1) along the arc, facing along it.
func _set_progress(progress: float) -> void:
	var point: Vector3 = _from.lerp(_to, progress) + Vector3.UP * arc_height * ARC_SHAPE * progress * (1.0 - progress)
	if not BattleFormulas.flat_offset(global_position, point).is_zero_approx():
		look_at(point)
	global_position = point
