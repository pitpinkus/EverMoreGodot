class_name RespawnPoint
extends Resource
## Where to put the player when entering a level: after a battle, or at the last
## heal point after losing one. Saved as plain data with to_dict() / from_dict().

const KEY_LEVEL_PATH: String = "level_path"
const KEY_TRANSFORM: String = "transform"
const KEY_FACING_YAW: String = "facing_yaw"
const KEY_USE_LEVEL_SPAWN: String = "use_level_spawn"

@export_file("*.tscn") var level_path: String = ""
@export var transform: Transform3D = Transform3D.IDENTITY
@export var facing_yaw: float = 0.0
## Ignore transform and use the level's own player spawn.
@export var use_level_spawn: bool = false


static func create(path: String, at: Transform3D, yaw: float, level_spawn: bool = false) -> RespawnPoint:
	var point: RespawnPoint = RespawnPoint.new()
	point.level_path = path
	point.transform = at
	point.facing_yaw = yaw
	point.use_level_spawn = level_spawn
	return point


## A point at marker's position (upright, unrotated) whose facing is marker's yaw,
## e.g. from a Marker3D's global_transform. Characters face the marker's -Z.
static func from_marker(path: String, marker: Transform3D) -> RespawnPoint:
	return create(path, upright_at(marker), yaw_of(marker))


## marker's position with an unrotated basis (character bodies stay unrotated).
static func upright_at(marker: Transform3D) -> Transform3D:
	return Transform3D(Basis.IDENTITY, marker.origin)


## Yaw (radians, 0 = -Z) that marker faces.
static func yaw_of(marker: Transform3D) -> float:
	return marker.basis.get_euler().y


## Builds a RespawnPoint from to_dict() output; wrong or missing values keep their defaults.
static func from_dict(data: Dictionary) -> RespawnPoint:
	var point: RespawnPoint = RespawnPoint.new()
	var stored_path: Variant = data.get(KEY_LEVEL_PATH)
	if stored_path is String:
		point.level_path = stored_path
	var stored_transform: Variant = data.get(KEY_TRANSFORM)
	if stored_transform is Transform3D:
		point.transform = stored_transform
	var stored_yaw: Variant = data.get(KEY_FACING_YAW)
	if stored_yaw is float or stored_yaw is int:
		point.facing_yaw = float(stored_yaw)
	var stored_use_spawn: Variant = data.get(KEY_USE_LEVEL_SPAWN)
	if stored_use_spawn is bool:
		point.use_level_spawn = stored_use_spawn
	if not stored_transform is Transform3D and not point.use_level_spawn:
		push_warning("RespawnPoint: saved data has no valid '%s'; using the origin." % KEY_TRANSFORM)
	return point


## Plain-data copy for saving.
func to_dict() -> Dictionary:
	return {
		KEY_LEVEL_PATH: level_path,
		KEY_TRANSFORM: transform,
		KEY_FACING_YAW: facing_yaw,
		KEY_USE_LEVEL_SPAWN: use_level_spawn,
	}
