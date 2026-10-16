class_name BattleMap
extends Node3D
## Base of every battle arena: terrain plus spawn markers for both sides. Units
## stand on the Marker3D children of %PlayerSpawns / %EnemySpawns, facing their -Z.
## %NavRegion holds the walkable-area NavigationMesh; BattleNavigator bakes it at
## runtime from the nodes in its source group (terrain and props).

@export var display_name: String = ""
## The player can only pick walk targets within this distance of the map origin;
## the navigation bake box (get_bounds) is this wide too.
@export_range(1.0, 200.0, 0.5, "suffix:m") var arena_radius: float = 12.0
## Height of the navigation bake box, centred on the map origin.
@export_range(1.0, 200.0, 0.5, "suffix:m") var bounds_height: float = 20.0

@onready var _player_spawns: Node3D = %PlayerSpawns
@onready var _enemy_spawns: Node3D = %EnemySpawns
@onready var _nav_region: NavigationRegion3D = %NavRegion


func get_player_spawns() -> Array[Transform3D]:
	return _get_spawns(_player_spawns)


func get_enemy_spawns() -> Array[Transform3D]:
	return _get_spawns(_enemy_spawns)


func get_navigation_region() -> NavigationRegion3D:
	return _nav_region


## World-space box around the arena (arena_radius wide, bounds_height tall); nothing outside is walkable.
func get_bounds() -> AABB:
	var half_size: Vector3 = Vector3(arena_radius, bounds_height / 2.0, arena_radius)
	return AABB(global_position - half_size, half_size * 2.0)


static func _get_spawns(parent: Node3D) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	for child: Node in parent.get_children():
		var marker: Node3D = child as Node3D
		if marker != null:
			spawns.append(marker.global_transform)
	return spawns
