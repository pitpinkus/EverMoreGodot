class_name BattleCursor
extends Node3D
## 3D cursor for picking where a unit walks (pick_point) or which unit an action
## targets (pick_unit). Results arrive as point_picked / unit_picked. Hidden while idle.
## While picking a point, %ReachDecal shows the ReachableArea on the ground and the
## marker switches to unreachable_material outside it.
##
## Mouse: the cursor follows the mouse over the ground (or the unit under it);
## confirm_point (left click) confirms, cancel_point (right click) cancels. When the
## camera pans (on_camera_moved) the point under the mouse is picked again.
## Gamepad: the cursor stays pinned to the camera focus (screen centre); the stick
## pans the camera (BattleCameraRig), not the cursor. Keyboard and gamepad
## confirm/cancel with confirm_point / cancel_point or ui_cancel. Units cycle with
## ui_left / ui_right / move_left / move_right. mode_changed tells the owner which
## camera inputs to allow.
##
## R7 exception: the mouse position is read from InputEventMouseMotion / the click
## event / the viewport, because a pointer position cannot be bound to an InputMap action.

signal point_picked(confirmed: bool, point: Vector3)
## The chosen unit, or null if cancelled.
signal unit_picked(target: BattleMonster)
## The cursor jumped by target cycling or a new pick (not by the mouse or the camera,
## so a camera following it can't drag the point under the mouse along).
signal moved(position: Vector3)
## Picking started (POINT / UNIT) or ended (IDLE).
signal mode_changed(mode: Mode)
## A confirmed point was ignored: too close to the origin or outside the reachable area.
signal point_rejected(reason: RejectReason)

const PREVIOUS_ACTIONS: Array[StringName] = [&"ui_left", &"move_left"]
const NEXT_ACTIONS: Array[StringName] = [&"ui_right", &"move_right"]
const CANCEL_ACTIONS: Array[StringName] = [&"cancel_point", &"ui_cancel"]

enum Mode { IDLE, POINT, UNIT }
enum RejectReason { TOO_CLOSE, UNREACHABLE }

## Reach decal colour inside the reachable area and along its edge.
@export var reach_fill_color: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var reach_edge_color: Color = Color(1.0, 1.0, 1.0, 0.8)
## Vertical size of %ReachDecal's projection box (covers bumps in the ground).
@export_range(0.1, 50.0, 0.1, "suffix:m") var decal_height: float = 4.0
## Marker material where the point can be walked to / where it can't. Null = keep the scene's.
@export var reachable_material: Material
@export var unreachable_material: Material
## Layers the mouse ray treats as ground when picking a point.
@export_flags_3d_physics var ground_mask: int = 1
## Layers the mouse ray checks for units when picking a target.
@export_flags_3d_physics var unit_mask: int = 2
@export_range(1.0, 1000.0, 1.0, "suffix:m") var mouse_ray_length: float = 200.0

var _mode: Mode = Mode.IDLE
var _origin: Vector3 = Vector3.ZERO
var _area: ReachableArea
var _min_distance: float = 0.0
var _candidates: Array[BattleMonster] = []
var _candidate_index: int = 0

@onready var _marker: MeshInstance3D = %Marker
@onready var _reach_decal: Decal = %ReachDecal
@onready var _ground_ray: RayCast3D = %GroundRay


func _ready() -> void:
	_set_idle()


## Lets the player pick a ground point within area.radius of origin. Answer: point_picked.
## Confirming a point closer than min_distance to origin or outside area is ignored
## (point_rejected).
func pick_point(origin: Vector3, area: ReachableArea, min_distance: float = 0.0) -> void:
	_origin = origin
	_area = area
	_min_distance = min_distance
	global_position = origin
	_set_mode(Mode.POINT)
	_show_reach(area)
	_show_at(origin)


## Lets the player pick one of candidates. Answer: unit_picked.
func pick_unit(candidates: Array[BattleMonster]) -> void:
	if candidates.is_empty():
		push_error("BattleCursor: pick_unit() called without candidates.")
		unit_picked.emit(null)
		return
	_candidates = candidates
	_set_mode(Mode.UNIT)
	_select_candidate(0)


## The camera focus moved to point. While picking a point the gamepad cursor follows
## it; with keyboard/mouse the point under the mouse is picked again.
func on_camera_moved(point: Vector3) -> void:
	if _mode != Mode.POINT:
		return
	if InputDeviceTracker.current_device == InputDeviceTracker.Device.GAMEPAD:
		_show_at(_clamp_point(point), false)
	else:
		_follow_mouse(get_viewport().get_mouse_position())


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
			point_rejected.emit(RejectReason.TOO_CLOSE)
		elif _mode == Mode.POINT and not _area.contains(global_position):
			point_rejected.emit(RejectReason.UNREACHABLE)
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


## point limited to the straight-line walk radius around the origin.
func _clamp_point(point: Vector3) -> Vector3:
	return _origin + BattleFormulas.flat_offset(_origin, point).limit_length(_area.radius)


## Projects area's reach texture onto the ground around it.
func _show_reach(area: ReachableArea) -> void:
	var extent: float = area.get_grid_extent()
	_reach_decal.texture_albedo = area.make_texture(reach_fill_color, reach_edge_color)
	_reach_decal.size = Vector3(extent, decal_height, extent)
	_reach_decal.global_position = area.origin
	_reach_decal.show()


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
	if _mode == Mode.POINT:
		_set_marker_reachable(_area.contains(global_position))
	_marker.show()
	if report:
		moved.emit(global_position)


func _set_marker_reachable(reachable: bool) -> void:
	var material: Material = reachable_material if reachable else unreachable_material
	if material != null:
		_marker.material_override = material


func _finish(confirmed: bool) -> void:
	var mode: Mode = _mode
	var point: Vector3 = global_position
	var target: BattleMonster = _candidates[_candidate_index] if confirmed and mode == Mode.UNIT else null
	_set_idle()
	if mode == Mode.POINT:
		point_picked.emit(confirmed, point)
	else:
		unit_picked.emit(target)


func _set_idle() -> void:
	_candidates = []
	_area = null
	_set_marker_reachable(true)
	_marker.hide()
	_reach_decal.hide()
	_set_mode(Mode.IDLE)


func _set_mode(mode: Mode) -> void:
	if mode == _mode:
		return
	_mode = mode
	mode_changed.emit(mode)
