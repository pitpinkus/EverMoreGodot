class_name BattleMap
extends Node3D
## Base of every battle arena: terrain plus spawn markers for both sides. Units
## stand on the Marker3D children of %PlayerSpawns / %EnemySpawns, facing their -Z.

@export var display_name: String = ""
## Units and the cursor stay within this distance of the map origin.
@export_range(1.0, 200.0, 0.5, "suffix:m") var arena_radius: float = 12.0

@onready var _player_spawns: Node3D = %PlayerSpawns
@onready var _enemy_spawns: Node3D = %EnemySpawns


func get_player_spawns() -> Array[Transform3D]:
	return _get_spawns(_player_spawns)


func get_enemy_spawns() -> Array[Transform3D]:
	return _get_spawns(_enemy_spawns)


static func _get_spawns(parent: Node3D) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	for child: Node in parent.get_children():
		var marker: Node3D = child as Node3D
		if marker != null:
			spawns.append(marker.global_transform)
	return spawns
