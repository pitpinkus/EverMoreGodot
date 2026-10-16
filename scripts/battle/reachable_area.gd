class_name ReachableArea
extends RefCounted
## The ground a unit can walk to this turn, sampled on a square grid of cells around
## its position (built by BattleNavigator.compute_reachable). Read-only after building.

## The walking unit's position; the grid is centred on it.
var origin: Vector3
## Straight-line walk range; no reachable cell is further from origin than this.
var radius: float
var cell_size: float
## Cells per grid side.
var cells_per_side: int

## 1 = reachable, row-major from the grid's -X / -Z corner (index = z * cells_per_side + x).
var _mask: PackedByteArray = PackedByteArray()


func _init(center: Vector3, walk_radius: float, cell: float) -> void:
	origin = center
	radius = walk_radius
	cell_size = cell
	cells_per_side = maxi(1, ceili(2.0 * walk_radius / cell))
	_mask.resize(cells_per_side * cells_per_side)


## World-space centre of grid cell (x, z), at the origin's height.
func get_cell_center(x: int, z: int) -> Vector3:
	var corner: Vector3 = get_grid_corner()
	return Vector3(corner.x + (x + 0.5) * cell_size, origin.y, corner.z + (z + 0.5) * cell_size)


## World-space -X / -Z corner of the grid, at the origin's height.
func get_grid_corner() -> Vector3:
	var half: float = get_grid_extent() / 2.0
	return origin - Vector3(half, 0.0, half)


## Side length of the whole grid in metres.
func get_grid_extent() -> float:
	return cells_per_side * cell_size


func set_reachable(x: int, z: int) -> void:
	_mask[z * cells_per_side + x] = 1


## True if point (ignoring height) lies in a reachable cell.
func contains(point: Vector3) -> bool:
	var corner: Vector3 = get_grid_corner()
	var x: int = floori((point.x - corner.x) / cell_size)
	var z: int = floori((point.z - corner.z) / cell_size)
	return _is_reachable(x, z)


## One pixel per cell (row = z): fill colour on reachable cells, edge colour on
## reachable cells next to an unreachable one, transparent elsewhere.
func make_texture(fill: Color, edge: Color) -> ImageTexture:
	var image: Image = Image.create_empty(cells_per_side, cells_per_side, false, Image.FORMAT_RGBA8)
	for z: int in cells_per_side:
		for x: int in cells_per_side:
			if _is_reachable(x, z):
				image.set_pixel(x, z, edge if _is_edge(x, z) else fill)
	return ImageTexture.create_from_image(image)


func _is_reachable(x: int, z: int) -> bool:
	if x < 0 or z < 0 or x >= cells_per_side or z >= cells_per_side:
		return false
	return _mask[z * cells_per_side + x] != 0


func _is_edge(x: int, z: int) -> bool:
	return not (_is_reachable(x - 1, z) and _is_reachable(x + 1, z) \
			and _is_reachable(x, z - 1) and _is_reachable(x, z + 1))
