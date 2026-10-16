class_name StepBudgetComponent
extends Node
## How far a unit may still walk this turn, and walking it to a point in a straight
## line. Only the distance actually travelled is deducted. Drives the body through
## move_requested (connect it to Character.move); never moves the body itself.

## Wanted walking direction (world space, unit length or zero).
signal move_requested(direction: Vector3, running: bool)
signal budget_changed(remaining: float, maximum: float)
## A move_to() finished: arrived, out of budget or stuck.
signal destination_reached

## The node whose position is measured (the unit's body).
@export var body: Node3D
## Closer than this to the destination counts as arrived.
@export_range(0.01, 2.0, 0.01, "suffix:m") var arrive_distance: float = 0.15
## Moving slower than stuck_speed for stuck_timeout ends the move (blocked by a wall/unit).
@export_range(0.05, 5.0, 0.05, "suffix:s") var stuck_timeout: float = 0.4
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var stuck_speed: float = 0.3

var _maximum: float = 0.0
var _remaining: float = 0.0
var _destination: Vector3 = Vector3.ZERO
var _last_position: Vector3 = Vector3.ZERO
var _stuck_time: float = 0.0


func _ready() -> void:
	if body == null:
		push_error("StepBudgetComponent '%s' has no body assigned." % name)
	set_physics_process(false)


## Starts a new turn with max_steps metres to walk.
func reset(max_steps: float) -> void:
	_maximum = maxf(0.0, max_steps)
	_set_remaining(_maximum)


func get_remaining() -> float:
	return _remaining


## point moved (on the ground plane) towards the body so it is within the remaining budget.
func clamp_destination(point: Vector3) -> Vector3:
	var origin: Vector3 = body.global_position
	var offset: Vector3 = BattleFormulas.flat_offset(origin, point).limit_length(_remaining)
	return Vector3(origin.x + offset.x, point.y, origin.z + offset.z)


## Walks towards point (clamped to the budget). Await it: returns once arrived,
## out of budget or stuck.
func move_to(point: Vector3) -> void:
	if body == null or _remaining <= 0.0:
		return
	_destination = clamp_destination(point)
	if BattleFormulas.flat_distance(body.global_position, _destination) <= arrive_distance:
		return
	_last_position = body.global_position
	_stuck_time = 0.0
	set_physics_process(true)
	await destination_reached


func _physics_process(delta: float) -> void:
	var position: Vector3 = body.global_position
	var travelled: float = BattleFormulas.flat_distance(_last_position, position)
	_last_position = position
	_set_remaining(_remaining - travelled)
	_stuck_time = _stuck_time + delta if travelled < stuck_speed * delta else 0.0
	var distance: float = BattleFormulas.flat_distance(position, _destination)
	if distance <= arrive_distance or _remaining <= 0.0 or _stuck_time >= stuck_timeout:
		_stop()
		return
	var direction: Vector3 = BattleFormulas.flat_offset(position, _destination).normalized()
	move_requested.emit(direction, false)


func _stop() -> void:
	set_physics_process(false)
	move_requested.emit(Vector3.ZERO, false)
	destination_reached.emit()


func _set_remaining(value: float) -> void:
	_remaining = maxf(0.0, value)
	budget_changed.emit(_remaining, _maximum)
