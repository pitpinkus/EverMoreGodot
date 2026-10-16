class_name BattleNavigator
extends Node
## The only place for battle path logic. Bakes the map's navigation mesh each turn
## with every other living unit as an obstacle, then answers path and reach queries
## for the manager, the AI and the player controller. Lengths are measured on the
## ground plane, like the step budget.
##
## setup(map) once, then await prepare_turn(unit, blockers) at the start of each turn
## (and again when a blocker faints) before any query.

## Emitted by the navigation server when an async bake is done.
signal _bake_done

## Sides of the polygon that stands in for a blocking unit.
const OBSTRUCTION_SIDES: int = 8
## Smallest reach-grid cell, so a zero budget still makes a valid grid.
const MIN_CELL_SIZE: float = 0.01

## Height of a unit's obstacle, starting obstruction_below under its feet.
@export_range(0.1, 10.0, 0.1, "suffix:m") var obstruction_height: float = 2.5
@export_range(0.0, 5.0, 0.05, "suffix:m") var obstruction_below: float = 0.5
## compute_reachable samples at most this many cells from the centre to the edge.
@export_range(4, 64, 1) var max_cells_per_radius: int = 20
## Physics frames to wait for the navigation map to pick up a new bake before giving up.
@export_range(1, 120, 1) var max_sync_frames: int = 30

var _region: NavigationRegion3D
var _navmesh: NavigationMesh
var _static_source: NavigationMeshSourceGeometryData3D
var _arena_center: Vector3 = Vector3.ZERO
var _arena_radius: float = INF


## Parses map's static geometry once and takes over its navigation region.
func setup(map: BattleMap) -> void:
	_arena_center = map.global_position
	_arena_radius = map.arena_radius
	_region = map.get_navigation_region()
	if _region == null or _region.navigation_mesh == null:
		push_error("BattleNavigator: map '%s' has no NavigationRegion3D with a NavigationMesh." % map.name)
		_region = null
		return
	_navmesh = _region.navigation_mesh.duplicate() as NavigationMesh
	var bounds: AABB = _region.global_transform.affine_inverse() * map.get_bounds()
	_navmesh.filter_baking_aabb = bounds
	_region.navigation_mesh = _navmesh
	_static_source = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(_navmesh, _static_source, _region)


## Rebakes the navmesh with blockers as obstacles (off the main thread) and returns
## once the navigation map uses it. Await it.
func prepare_turn(unit: BattleMonster, blockers: Array[BattleMonster]) -> void:
	if _region == null:
		return
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	source.merge(_static_source)
	for blocker: BattleMonster in blockers:
		if blocker != unit:
			_add_obstruction(source, _region.to_local(blocker.global_position), blocker.get_body_radius())
	NavigationServer3D.bake_from_source_geometry_data_async(_navmesh, source, _bake_done.emit)
	# Without baking threads the bake (and its callback) already ran synchronously.
	if NavigationServer3D.is_baking_navigation_mesh(_navmesh):
		await _bake_done
	var map: RID = _region.get_navigation_map()
	var iteration: int = NavigationServer3D.map_get_iteration_id(map)
	NavigationServer3D.region_set_navigation_mesh(_region.get_rid(), _navmesh)
	for _frame: int in max_sync_frames:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(map) != iteration:
			return
	push_warning("BattleNavigator: the navigation map did not update within %d frames." % max_sync_frames)


## Path from from towards to, cut off once it is budget metres long. Empty without a navmesh.
func get_path_within(from: Vector3, to: Vector3, budget: float) -> PackedVector3Array:
	if _region == null:
		return PackedVector3Array()
	var path: PackedVector3Array = NavigationServer3D.map_get_path(_region.get_navigation_map(), from, to, true)
	return truncate_path(path, budget)


## Every grid cell around from whose centre is inside the arena circle, on the navmesh
## and at most budget metres away along a path. Cells are at least the navmesh cell size.
func compute_reachable(from: Vector3, budget: float) -> ReachableArea:
	var cell: float = maxf(budget / max_cells_per_radius, MIN_CELL_SIZE)
	if _region == null:
		return ReachableArea.new(from, budget, cell)
	var map: RID = _region.get_navigation_map()
	var area: ReachableArea = ReachableArea.new(from, budget, maxf(NavigationServer3D.map_get_cell_size(map), cell))
	var on_mesh_tolerance: float = area.cell_size / 2.0
	for z: int in area.cells_per_side:
		for x: int in area.cells_per_side:
			var sample: Vector3 = area.get_cell_center(x, z)
			if BattleFormulas.flat_distance(from, sample) > budget \
					or BattleFormulas.flat_distance(_arena_center, sample) > _arena_radius:
				continue
			var closest: Vector3 = NavigationServer3D.map_get_closest_point(map, sample)
			if BattleFormulas.flat_distance(closest, sample) > on_mesh_tolerance:
				continue
			var path: PackedVector3Array = NavigationServer3D.map_get_path(map, from, closest, true)
			if not path.is_empty() and path_length(path) <= budget \
					and BattleFormulas.flat_distance(path[path.size() - 1], closest) <= on_mesh_tolerance:
				area.set_reachable(x, z)
	return area


## Length of path on the ground plane.
static func path_length(path: PackedVector3Array) -> float:
	var length: float = 0.0
	for i: int in range(1, path.size()):
		length += BattleFormulas.flat_distance(path[i - 1], path[i])
	return length


## path cut off (with an interpolated last point) once it is budget metres long.
static func truncate_path(path: PackedVector3Array, budget: float) -> PackedVector3Array:
	if path.is_empty():
		return path
	var result: PackedVector3Array = PackedVector3Array([path[0]])
	var left: float = budget
	for i: int in range(1, path.size()):
		var segment: float = BattleFormulas.flat_distance(path[i - 1], path[i])
		if segment >= left:
			if segment > 0.0:
				result.append(path[i - 1].lerp(path[i], left / segment))
			return result
		left -= segment
		result.append(path[i])
	return result


## A projected polygon of radius (the unit's body) around position (navmesh-local) that
## the bake keeps clear; the navmesh's agent_radius is added on top while baking.
func _add_obstruction(source: NavigationMeshSourceGeometryData3D, position: Vector3, radius: float) -> void:
	var outline: PackedVector3Array = PackedVector3Array()
	for i: int in OBSTRUCTION_SIDES:
		var angle: float = TAU * i / OBSTRUCTION_SIDES
		outline.append(position + Vector3(cos(angle), 0.0, sin(angle)) * radius)
	source.add_projected_obstruction(outline, position.y - obstruction_below, obstruction_height, false)
