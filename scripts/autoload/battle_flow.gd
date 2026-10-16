extends Node
## Autoload. Moves the game between the overworld and battles: builds a BattleSetup
## from an Encounter, remembers where the player came from, opens the battle scene,
## and afterwards applies the result (cleared encounters, captured monster, heal and
## respawn at the last heal point on a loss) and returns to the overworld.
## Cleared encounter ids live in SaveSystem state (saved with the next full save).

signal battle_started(setup: BattleSetup)
signal battle_finished(result: BattleResult)

const BATTLE_SCENE_PATH: String = "res://levels/battle_scene.tscn"
## Optional ScreenFade prefab; without it scene changes are not faded.
const FADE_SCENE_PATH: String = "res://prefabs/ui/screen_fade.tscn"
const FADE_DURATION: float = 0.35
## After a battle no new encounter starts for this long (time while paused does not count).
const ENCOUNTER_GRACE_SECONDS: float = 2.0
const PLAYER_GROUP: StringName = &"player"
const CLEARED_STATE_KEY: StringName = &"cleared_encounters"

var _setup: BattleSetup
var _pending_return: RespawnPoint
## A battle is starting, running or ending.
var _busy: bool = false
var _grace_left: float = 0.0
var _cleared: Array[StringName] = []
var _fade: ScreenFade


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	SaveSystem.load_completed.connect(_on_load_completed)
	if ResourceLoader.exists(FADE_SCENE_PATH):
		var fade_scene: PackedScene = load(FADE_SCENE_PATH) as PackedScene
		_fade = fade_scene.instantiate() as ScreenFade if fade_scene != null else null
		if _fade != null:
			add_child(_fade)
		else:
			push_warning("BattleFlow: '%s' is not a ScreenFade scene; scene changes won't fade." % FADE_SCENE_PATH)


func _process(delta: float) -> void:
	_grace_left = maxf(0.0, _grace_left - delta)


## Starts a battle against encounter. encounter_id (may be empty = repeatable) is
## marked cleared when the player wins or captures. False if nothing was started.
func start_battle(encounter: Encounter, encounter_id: StringName) -> bool:
	if encounter == null or is_encounter_blocked():
		return false
	if not PlayerProfile.has_able_monster():
		return false
	var setup: BattleSetup = BattleSetup.from_encounter(encounter, RandomNumberGenerator.new(), DataRegistry.get_rules())
	if setup.enemy_team.is_empty():
		push_warning("BattleFlow: encounter '%s' has no enemies." % encounter.resource_path)
		return false
	_setup = setup
	_setup.encounter_id = encounter_id
	_setup.return_point = _make_return_point()
	_busy = true
	battle_started.emit(_setup)
	_enter_battle()
	return true


## The battle being fought, or null (e.g. the battle scene was run on its own).
func get_current_setup() -> BattleSetup:
	return _setup


## Applies result and leaves the battle scene: back to where the player came from,
## to the last heal point (or the level's spawn) after a loss, or to the title screen
## if there is no level to return to.
func finish_battle(result: BattleResult) -> void:
	battle_finished.emit(result)
	var target: RespawnPoint = _setup.return_point if _setup != null else null
	match result.outcome:
		BattleTypes.Outcome.WON, BattleTypes.Outcome.CAPTURED:
			_mark_cleared(result.encounter_id)
			if result.captured != null and not PlayerProfile.add_to_party(result.captured):
				push_warning("BattleFlow: party is full; captured monster was released.")
		BattleTypes.Outcome.LOST:
			PlayerProfile.heal_party()
			target = _get_loss_target(target)
	_setup = null
	if target == null or target.level_path.is_empty():
		_busy = false
		GameFlow.go_to_title_screen()
		return
	_pending_return = target
	await _change_scene_faded(target.level_path)
	_grace_left = ENCOUNTER_GRACE_SECONDS
	_busy = false


## The placement for level_path's player if it is the level being returned to
## (cleared once taken), else null.
func take_pending_return(level_path: String) -> RespawnPoint:
	if _pending_return == null or _pending_return.level_path != level_path:
		return null
	var point: RespawnPoint = _pending_return
	_pending_return = null
	return point


## True while a battle is starting/running or during the grace period after one.
func is_encounter_blocked() -> bool:
	return _busy or _grace_left > 0.0


func is_encounter_cleared(encounter_id: StringName) -> bool:
	return not encounter_id.is_empty() and _cleared.has(encounter_id)


## Forgets the current battle, pending return and cleared encounters (new game, load, title).
func reset() -> void:
	_setup = null
	_pending_return = null
	_busy = false
	_grace_left = 0.0
	_cleared.clear()


## Stays busy for the whole battle; only a failed scene change ends it here.
func _enter_battle() -> void:
	if not await _change_scene_faded(BATTLE_SCENE_PATH):
		_busy = false


## Where the player stands now, as a return point in the current level.
func _make_return_point() -> RespawnPoint:
	var level_path: String = get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	var player: Character = get_tree().get_first_node_in_group(PLAYER_GROUP) as Character
	if player == null:
		return RespawnPoint.create(level_path, Transform3D.IDENTITY, 0.0, true)
	return RespawnPoint.create(level_path, player.global_transform, player.get_facing_yaw())


## After a loss: the last heal point, else the spawn of the level the battle started from.
func _get_loss_target(return_point: RespawnPoint) -> RespawnPoint:
	var heal_point: RespawnPoint = PlayerProfile.get_respawn_point()
	if heal_point != null:
		return heal_point
	var level_path: String = return_point.level_path if return_point != null else ""
	return RespawnPoint.create(level_path, Transform3D.IDENTITY, 0.0, true)


func _mark_cleared(encounter_id: StringName) -> void:
	if encounter_id.is_empty() or _cleared.has(encounter_id):
		return
	_cleared.append(encounter_id)
	if SaveSystem.has_active_slot():
		var ids: Array[String] = []
		for id: StringName in _cleared:
			ids.append(String(id))
		SaveSystem.set_state(CLEARED_STATE_KEY, ids)


## Fades out, opens path, fades back in once the new scene is running. Returns
## whether the scene could be opened; on failure the pending battle/return is dropped.
func _change_scene_faded(path: String) -> bool:
	if _fade != null:
		await _fade.fade_out(FADE_DURATION)
	var opened: bool = GameFlow.change_scene(path) == OK
	if opened:
		await get_tree().scene_changed
	else:
		_setup = null
		_pending_return = null
	if _fade != null:
		await _fade.fade_in(FADE_DURATION)
	return opened


func _on_load_completed(_info: SaveSlotInfo) -> void:
	_cleared.clear()
	var stored: Variant = SaveSystem.get_state(CLEARED_STATE_KEY, [])
	if stored is Array:
		for id: Variant in stored:
			_cleared.append(StringName(str(id)))
