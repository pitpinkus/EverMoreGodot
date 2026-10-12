class_name Level
extends Node3D
## Base for every map. Holds the standard layer nodes and, until a level loader
## exists, spawns the player at a named Marker3D under %SpawnPoints.

@export var player_scene: PackedScene
@export var player_spawn: StringName = &"PlayerSpawn"

@onready var _characters: Node3D = %Characters
@onready var _spawn_points: Node3D = %SpawnPoints


func _ready() -> void:
	if player_scene == null:
		return
	var player: Node3D = player_scene.instantiate() as Node3D
	if player == null:
		push_error("Level '%s': player_scene root is not a Node3D." % name)
		return
	_characters.add_child(player)
	player.global_transform = get_spawn(player_spawn)


## Global transform of the spawn point with that name, or this level's origin if missing.
func get_spawn(spawn_name: StringName) -> Transform3D:
	var spawn: Node3D = _spawn_points.get_node_or_null(NodePath(spawn_name)) as Node3D
	if spawn == null:
		push_error("Level '%s': spawn point '%s' not found under SpawnPoints." % [name, spawn_name])
		return global_transform
	return spawn.global_transform
