class_name BattleCursor
extends Node3D
## 3D cursor for picking where a unit walks (pick_point) or which unit an action
## targets (pick_unit). Results arrive as point_picked / unit_picked. Hidden while idle.
##
## Mouse: the cursor follows the mouse over the ground (or the unit under it);
## confirm_point (left click) confirms, cancel_point (right click) cancels.
## Gamepad: the left stick (move_* actions) moves the cursor relative to the camera;
## stick movement is ignored while the keyboard/mouse is the active device, so the
## keyboard does not move it. Keyboard and gamepad confirm/cancel with confirm_point /
## cancel_point or ui_cancel. Units cycle with ui_left / ui_right / move_left /
## move_right; while cycling, unit_picking_changed lets the owner turn off camera key
## look (the arrow keys are also camera keys).
##
## R7 exception: the mouse position is read from InputEventMouseMotion / the click
## event, because a pointer position cannot be bound to an InputMap action.

signal point_picked(confirmed: bool, point: Vector3)
## The chosen unit, or null if cancelled.
signal unit_picked(target: BattleMonster)
## The cursor moved by stick, cycling or a new pick (not by the mouse, so a camera
## following it can't drag the point under the mouse along).
signal moved(position: Vector3)
signal unit_picking_changed(active: bool)
## A point was confirmed closer than min_distance to the origin and ignored.
signal point_rejected

const PREVIOUS_ACTIONS: Array[StringName] = [&"ui_left", &"move_left"]
const NEXT_ACTIONS: Array[StringName] = [&"ui_right", &"move_right"]
const CANCEL_ACTIONS: Array[StringName] = [&"cancel_point", &"ui_cancel"]

enum Mode { IDLE, POINT, UNIT }

## Its yaw defines "forward" for stick movement (the battle camera rig).
@export var camera_pivot: Node3D
@export_range(0.5, 30.0, 0.1, "suffix:m/s") var move_speed: float = 6.0
## Radius of the %RangeRing mesh at scale 1; the ring is scaled to the walk range.
@export_range(0.01, 10.0, 0.01, "suffix:m") var ring_base_radius: float = 1.0
## Layers the mouse ray treats as ground when picking a point.
@export_flags_3d_physics var ground_mask: int = 1
## Layers the mouse ray checks for units when picking a target.
@export_flags_3d_physics var unit_mask: int = 2
@export_range(1.0, 1000.0, 1.0, "suffix:m") var mouse_ray_length: float = 200.0

var _mode: Mode = Mode.IDLE
var _origin: Vector3 = Vector3.ZERO
var _radius: float = 0.0
var _min_distance: float = 0.0
var _arena_center: Vector3 = Vector3.ZERO
var _arena_radius: float = INF
var _candidates: Array[BattleMonster] = []
var _candidate_index: int = 0

@onready var _marker: Node3D = %Marker
@onready var _range_ring: Node3D = %RangeRing
@onready var _ground_ray: RayCast3D = %GroundRay


func _ready() -> void:
	_set_idle()


## The cursor never leaves the circle of radius around center.
func set_arena(center: Vector3, radius: float) -> void:
	_arena_center = center
	_arena_radius = radius


## Lets the player pick a ground point within radius of origin. Answer: point_picked.
## Confirming a point closer than min_distance to origin is ignored (point_rejected).
func pick_point(origin: Vector3, radius: float, min_distance: float = 0.0) -> void:
	_mode = Mode.POINT
	_origin = origin
	_radius = radius
	_min_distance = min_distance
	global_position = origin
	_range_ring.global_position = origin
	var ring_scale: float = radius / ring_base_radius
	_range_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
	_range_ring.show()
	_show_at(origin)
	set_process(true)


## Lets the player pick one of candidates. Answer: unit_picked.
func pick_unit(candidates: Array[BattleMonster]) -> void:
	if candidates.is_empty():
		push_error("BattleCursor: pick_unit() called without candidates.")
		unit_picked.emit(null)
		return
	_mode = Mode.UNIT
	_candidates = candidates
	_select_candidate(0)
	unit_picking_changed.emit(true)


func _process(delta: float) -> void:
	if InputDeviceTracker.current_device != InputDeviceTracker.Device.GAMEPAD:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not input.is_zero_approx():
		_show_at(_clamp_point(global_position + CameraRelativeInput.to_world(input, camera_pivot) * move_speed * delta))


func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.IDLE:
		return
	if event is InputEventMouseMotion:
		_follow_mouse((event as InputEventMouseMotion).position)
	elif event.is_action_pressed("confirm_point"):
		# A click only counts where it points at something pickable.
		if event is InputEventMouseButton and not _follow_mouse((event as InputEventMouseButton).position):
			return
		get_viewport().set_input_as_handled()
		if _mode == Mode.POINT and BattleFormulas.flat_distance(_origin, global_position) < _min_distance:
			point_rejected.emit()
		else:
			_finish(true)
	elif _is_cancel(event):
		get_viewport().set_input_as_handled()
		_finish(false)
	elif _mode == Mode.UNIT:
		var step: int = _get_cycle_step(event)
		if step != 0:
			get_viewport().set_input_as_handled()
			_select_candidate(wrapi(_candidate_index + step, 0, _candidates.size()))


## Moves the cursor to what the mouse at screen_position points at (ground point or
## candidate unit). False if it points at nothing pickable.
func _follow_mouse(screen_position: Vector2) -> bool:
	if _mode == Mode.POINT:
		var hit: Dictionary = _raycast_mouse(screen_position, ground_mask)
		if hit.is_empty():
			return false
		_show_at(_clamp_point(hit.position), false)
		return true
	var unit_hit: Dictionary = _raycast_mouse(screen_position, unit_mask)
	var index: int = _candidates.find(unit_hit.get("collider") as BattleMonster) if not unit_hit.is_empty() else -1
	if index < 0:
		return false
	_select_candidate(index, false)
	return true


## Physics ray from the active camera through screen_position; empty if nothing on mask is hit.
func _raycast_mouse(screen_position: Vector2, mask: int) -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var from: Vector3 = camera.project_ray_origin(screen_position)
	var to: Vector3 = from + camera.project_ray_normal(screen_position) * mouse_ray_length
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask))


## point limited to the walk radius around the origin and to the arena.
func _clamp_point(point: Vector3) -> Vector3:
	var wanted: Vector3 = _origin + BattleFormulas.flat_offset(_origin, point).limit_length(_radius)
	return _arena_center + BattleFormulas.flat_offset(_arena_center, wanted).limit_length(_arena_radius)


func _select_candidate(index: int, report: bool = true) -> void:
	_candidate_index = index
	_show_at(_candidates[index].global_position, report)


static func _is_cancel(event: InputEvent) -> bool:
	return CANCEL_ACTIONS.any(func(action: StringName) -> bool: return event.is_action_pressed(action))


## -1 / +1 if event presses a previous / next action, else 0.
static func _get_cycle_step(event: InputEvent) -> int:
	for action: StringName in PREVIOUS_ACTIONS:
		if event.is_action_pressed(action, true):
			return -1
	for action: StringName in NEXT_ACTIONS:
		if event.is_action_pressed(action, true):
			return 1
	return 0


## Moves the cursor to point snapped to the ground below it and shows it; emits
## moved if report.
func _show_at(point: Vector3, report: bool = true) -> void:
	global_position = point
	_ground_ray.force_raycast_update()
	if _ground_ray.is_colliding():
		global_position.y = _ground_ray.get_collision_point().y
	_marker.show()
	if report:
		moved.emit(global_position)


func _finish(confirmed: bool) -> void:
	var mode: Mode = _mode
	var point: Vector3 = global_position
	var target: BattleMonster = _candidates[_candidate_index] if confirmed and mode == Mode.UNIT else null
	_set_idle()
	if mode == Mode.POINT:
		point_picked.emit(confirmed, point)
	else:
		unit_picking_changed.emit(false)
		unit_picked.emit(target)


func _set_idle() -> void:
	_mode = Mode.IDLE
	_candidates = []
	set_process(false)
	_marker.hide()
	_range_ring.hide()
