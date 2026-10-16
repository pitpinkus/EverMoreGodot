class_name BattleScene
extends Node3D
## The battle screen. Builds the battle from BattleFlow's setup (or fallback_encounter
## when the scene is run on its own): loads the map into %MapSlot, spawns units into
## %Units, binds the HUD and starts %BattleManager. Moves the camera to the active
## unit and the cursor, and hands the result back to BattleFlow when it ends.

@export var battle_monster_scene: PackedScene
## Used when the setup has no battle map.
@export var default_battle_map: PackedScene
## Enemies when there is no BattleFlow setup (scene run directly, F6).
@export var fallback_encounter: Encounter
@export_range(0.0, 3.0, 0.05, "suffix:s") var camera_move_duration: float = 0.5

var _camera_tween: Tween

@onready var _map_slot: Node3D = %MapSlot
@onready var _units: Node3D = %Units
@onready var _camera_anchor: Node3D = %CameraAnchor
@onready var _cursor: BattleCursor = %BattleCursor
@onready var _battle: BattleManager = %BattleManager
@onready var _hud: BattleHud = %BattleHud
@onready var _camera_input: CameraInputComponent = %CameraInputComponent


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var setup: BattleSetup = BattleFlow.get_current_setup()
	if setup == null:
		setup = _make_fallback_setup()
	var map: BattleMap = _load_map(setup)
	if map == null or battle_monster_scene == null:
		push_error("BattleScene: needs a BattleMap scene and battle_monster_scene.")
		return
	_cursor.set_arena(map.global_position, map.arena_radius)
	var max_units: int = DataRegistry.get_rules().max_units_per_side
	var player_units: Array[BattleMonster] = _spawn_units(PlayerProfile.get_able_monsters(), max_units,
			map.get_player_spawns(), BattleTypes.Side.PLAYER)
	var enemy_units: Array[BattleMonster] = _spawn_units(setup.enemy_team, max_units,
			map.get_enemy_spawns(), BattleTypes.Side.ENEMY)
	_hud.bind_units(player_units, enemy_units)
	_battle.start(setup, player_units, enemy_units)


func _make_fallback_setup() -> BattleSetup:
	if fallback_encounter == null:
		push_error("BattleScene: no BattleFlow setup and no fallback_encounter.")
		return BattleSetup.new()
	return BattleSetup.from_encounter(fallback_encounter, RandomNumberGenerator.new(), DataRegistry.get_rules())


func _load_map(setup: BattleSetup) -> BattleMap:
	var map_scene: PackedScene = setup.battle_map if setup.battle_map != null else default_battle_map
	if map_scene == null:
		return null
	var map: BattleMap = map_scene.instantiate() as BattleMap
	if map != null:
		_map_slot.add_child(map)
	return map


## One unit for each of the first max_units monsters, on the matching spawn marker.
## Monsters without a spawn marker are left out.
func _spawn_units(monsters: Array[MonsterInstance], max_units: int, spawns: Array[Transform3D],
		side: BattleTypes.Side) -> Array[BattleMonster]:
	var count: int = mini(monsters.size(), max_units)
	if count > spawns.size():
		push_warning("BattleScene: %d monsters but only %d spawn markers." % [count, spawns.size()])
	var units: Array[BattleMonster] = []
	for index: int in mini(count, spawns.size()):
		var unit: BattleMonster = battle_monster_scene.instantiate() as BattleMonster
		_units.add_child(unit)
		unit.place(RespawnPoint.upright_at(spawns[index]), RespawnPoint.yaw_of(spawns[index]))
		unit.setup(monsters[index], side)
		units.append(unit)
	return units


func _move_camera_to(point: Vector3) -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(_camera_anchor, "global_position", point, camera_move_duration)


func _on_turn_started(unit: BattleMonster) -> void:
	unit.set_selected(true)
	_hud.set_active_unit(unit)
	_move_camera_to(unit.global_position)


func _on_turn_ended(unit: BattleMonster) -> void:
	unit.set_selected(false)


func _on_timeline_changed() -> void:
	_hud.set_timeline(_battle.predict_turns(_hud.get_timeline_length()), _battle.get_current_unit())


func _on_cursor_moved(point: Vector3) -> void:
	_move_camera_to(point)


## The arrow keys cycle targets and turn the camera; only one may happen at a time.
func _on_unit_picking_changed(active: bool) -> void:
	_camera_input.set_look_input_enabled(not active)


func _on_battle_ended(result: BattleResult) -> void:
	await get_tree().create_timer(DataRegistry.get_rules().action_delay, false).timeout
	BattleFlow.finish_battle(result)
