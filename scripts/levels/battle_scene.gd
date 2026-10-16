class_name BattleScene
extends Node3D
## The battle screen. Builds the battle from BattleFlow's setup (or fallback_encounter
## when the scene is run on its own): loads the map into %MapSlot, prepares
## %BattleNavigator for it, spawns units into %Units, binds the HUD and starts
## %BattleManager. Moves the camera to the active unit and the cursor, decides which
## camera inputs are live (see _update_camera_input), and hands the result back to
## BattleFlow when it ends.

@export var battle_monster_scene: PackedScene
## Used when the setup has no battle map.
@export var default_battle_map: PackedScene
## Enemies when there is no BattleFlow setup (scene run directly, F6).
@export var fallback_encounter: Encounter

var _cursor_mode: BattleCursor.Mode = BattleCursor.Mode.IDLE
var _list_open: bool = false
var _commands_open: bool = false

@onready var _map_slot: Node3D = %MapSlot
@onready var _units: Node3D = %Units
@onready var _camera_rig: BattleCameraRig = %CameraAnchor
@onready var _cursor: BattleCursor = %BattleCursor
@onready var _battle: BattleManager = %BattleManager
@onready var _navigator: BattleNavigator = %BattleNavigator
@onready var _hud: BattleHud = %BattleHud
@onready var _camera_input: CameraInputComponent = %CameraInputComponent


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_camera_rig.focus_moved.connect(_cursor.on_camera_moved)
	_cursor.mode_changed.connect(_on_cursor_mode_changed)
	_hud.list_visibility_changed.connect(_on_list_visibility_changed)
	_hud.command_menu_visibility_changed.connect(_on_command_menu_visibility_changed)
	InputDeviceTracker.device_changed.connect(_on_device_changed)
	_update_camera_input()
	var setup: BattleSetup = BattleFlow.get_current_setup()
	if setup == null:
		setup = _make_fallback_setup()
	var map: BattleMap = _load_map(setup)
	if map == null or battle_monster_scene == null:
		push_error("BattleScene: needs a BattleMap scene and battle_monster_scene.")
		return
	_navigator.setup(map)
	_camera_rig.set_bounds(map.global_position, map.arena_radius)
	var max_units: int = DataRegistry.get_rules().max_units_per_side
	var player_units: Array[BattleMonster] = _spawn_units(PlayerProfile.get_able_monsters(), max_units,
			map.get_player_spawns(), BattleTypes.Side.PLAYER)
	var enemy_units: Array[BattleMonster] = _spawn_units(setup.enemy_team, max_units,
			map.get_enemy_spawns(), BattleTypes.Side.ENEMY)
	_hud.bind_units(player_units, enemy_units)
	PortraitCache.prewarm(_get_species(player_units + enemy_units))
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


## Species of units, each once (portraits are made while the battle fades in).
static func _get_species(units: Array[BattleMonster]) -> Array[SpeciesData]:
	var species_list: Array[SpeciesData] = []
	for unit: BattleMonster in units:
		if not species_list.has(unit.instance.species):
			species_list.append(unit.instance.species)
	return species_list


func _on_turn_started(unit: BattleMonster) -> void:
	unit.set_selected(true)
	_hud.set_active_unit(unit)
	_camera_rig.focus_on(unit.global_position)


func _on_turn_ended(unit: BattleMonster) -> void:
	unit.set_selected(false)


func _on_timeline_changed() -> void:
	_hud.set_timeline(_battle.predict_turns(_hud.get_timeline_length()), _battle.get_current_unit())


func _on_cursor_moved(point: Vector3) -> void:
	_camera_rig.focus_on(point)


func _on_cursor_mode_changed(mode: BattleCursor.Mode) -> void:
	_cursor_mode = mode
	_update_camera_input()


func _on_list_visibility_changed(open: bool) -> void:
	_list_open = open
	_update_camera_input()


func _on_command_menu_visibility_changed(open: bool) -> void:
	_commands_open = open
	_update_camera_input()


## A gamepad taking over while picking a point pins the cursor to the camera focus.
func _on_device_changed(_device: InputDeviceTracker.Device) -> void:
	_cursor.on_camera_moved(_camera_rig.global_position)


## Which camera inputs are live, by what the player is doing:
## command menu: keyboard pans (the stick drives menu focus), rotate on, no look (arrows move focus);
## between turns: keyboard pans, look and rotate on;
## list open: no pan, look or rotate (Q/E and LB/RB switch list tabs);
## picking a point: keyboard and stick pan, look and rotate on;
## picking a unit: no pan, no look (left/right and A/D cycle targets), rotate on.
func _update_camera_input() -> void:
	var pan: BattleCameraRig.PanMode = BattleCameraRig.PanMode.KEYBOARD_ONLY
	var look: bool = true
	var rotate: bool = true
	if _list_open:
		pan = BattleCameraRig.PanMode.OFF
		look = false
		rotate = false
	elif _cursor_mode == BattleCursor.Mode.POINT:
		pan = BattleCameraRig.PanMode.ALL
	elif _cursor_mode == BattleCursor.Mode.UNIT:
		pan = BattleCameraRig.PanMode.OFF
		look = false
	elif _commands_open:
		look = false
	_camera_rig.set_pan_mode(pan)
	_camera_input.set_look_input_enabled(look)
	_camera_input.set_rotate_input_enabled(rotate)


func _on_battle_ended(result: BattleResult) -> void:
	await get_tree().create_timer(DataRegistry.get_rules().action_delay, false).timeout
	BattleFlow.finish_battle(result)
