extends Node
## Autoload. Every save and load in the game goes through SaveSystem.
## It owns the active save slot (lists slots, starts new games, loads, saves, counts
## playtime) and two kinds of slot data. Keys must be unique game-wide. Values must be
## plain data (SaveGame.is_plain_data): no Object, Callable, Signal or RID, at any depth.
##
## STATE: a snapshot of the world (positions, HP, ...), written only by a full save
## (save_current). Push it when save_started fires; pull it when load_completed fires
## (the loaded level is in the tree and ready, spawns already placed):
##     SaveSystem.save_started.connect(func() -> void: SaveSystem.set_state(&"player", data))
##     SaveSystem.load_completed.connect(func(_info: SaveSlotInfo) -> void: apply(SaveSystem.get_state(&"player")))
##
## PROGRESS: things gained during the run (discoveries, unlocks) that must not be
## lost even if the player never saves. One call stores it and writes the slot file
## right away (coalesced: several calls in one frame make a single write). The
## state snapshot in the file stays as of the last full save.
##     if SaveSystem.unlock(&"monsters_seen", &"emberfox"):
##         show_new_monster_banner()
##     SaveSystem.save_progress(&"best_catch_streak", 7)
##
## Files: one SaveGame per slot, managed through SaveSlotFiles. SaveConfig (CONFIG_PATH) picks
## whether new saves are encrypted or readable text; both kinds are always loadable.

## Emitted at the start of save_current(): push your latest state with set_state() now.
signal save_started
signal save_completed(info: SaveSlotInfo)
## Emitted for every key of a progress write once it is on disk. Errors use save_failed.
signal progress_saved(key: StringName)
signal save_failed(slot_id: String, error: Error)
signal load_completed(info: SaveSlotInfo)
signal load_failed(slot_id: String, error: Error)

const CONFIG_PATH: String = "res://data/save/save_config.tres"
const SLOT_NAME_FORMAT: String = "Save %d"

var _config: SaveConfig
## Whether new saves are encrypted: _config.encrypt unless that can't work.
var _encrypt: bool = false
## The slot being played, or null on the title screen.
var _active: SaveSlotInfo
## Live state: set_state() writes here, get_state() reads from here.
var _state: Dictionary[StringName, Variant] = {}
## State as of the last full save (or load); what progress writes put in the file.
var _saved_state: Dictionary[StringName, Variant] = {}
var _progress: Dictionary[StringName, Variant] = {}
## Progress keys changed since the last write.
var _dirty_progress_keys: Array[StringName] = []
var _progress_flush_queued: bool = false
## A slot was just loaded; emit load_completed after the next scene change.
var _load_on_scene_change: bool = false
var _save_on_scene_change: bool = false


func _ready() -> void:
	# Pausable so the pause menu does not count as playtime.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_config = load(CONFIG_PATH) as SaveConfig
	if _config == null:
		push_error("SaveSystem: '%s' is missing or not a SaveConfig; saving unencrypted." % CONFIG_PATH)
		_config = SaveConfig.new()
	elif _config.encrypt and _config.encryption_password.is_empty():
		push_error("SaveSystem: '%s' enables encryption without a password; saving unencrypted." % CONFIG_PATH)
	else:
		_encrypt = _config.encrypt
	get_tree().scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if _active != null:
		_active.playtime_seconds += delta


## Every readable save slot (headers only), newest first.
func list_saves() -> Array[SaveSlotInfo]:
	var saves: Array[SaveSlotInfo] = []
	for slot_id: String in SaveSlotFiles.get_existing_slot_ids():
		var path: String = SaveSlotFiles.find_slot_path(slot_id, _config.encryption_password)
		var info: SaveSlotInfo = SaveGame.read_info(path, _config.encryption_password)
		if info == null:
			continue
		info.slot_id = slot_id
		saves.append(info)
	saves.sort_custom(func(a: SaveSlotInfo, b: SaveSlotInfo) -> bool: return a.saved_at_unix > b.saved_at_unix)
	return saves


## Makes a fresh slot active. It is written once the next scene (level_path) has loaded.
func begin_new_game(level_path: String) -> void:
	_clear_session()
	var number: int = SaveSlotFiles.find_free_slot_number()
	_active = SaveSlotInfo.new()
	_active.slot_id = SaveSlotFiles.get_slot_id(number)
	_active.display_name = SLOT_NAME_FORMAT % number
	_active.level_path = level_path
	_save_on_scene_change = true


## Reads slot and makes it active with its saved data. load_completed follows the next scene change.
## On error emits load_failed and returns false.
func begin_load(slot: SaveSlotInfo) -> bool:
	if slot == null:
		push_error("SaveSystem: begin_load() called without a slot.")
		load_failed.emit("", ERR_INVALID_PARAMETER)
		return false
	var path: String = SaveSlotFiles.find_slot_path(slot.slot_id, _config.encryption_password)
	var save: SaveGame = SaveGame.read(path, _config.encryption_password)
	if save == null:
		load_failed.emit(slot.slot_id, ERR_FILE_CORRUPT if FileAccess.file_exists(path) else ERR_FILE_NOT_FOUND)
		return false
	if save.info.level_path.is_empty():
		push_warning("SaveSystem: slot '%s' has no level path." % slot.slot_id)
		load_failed.emit(slot.slot_id, ERR_FILE_CORRUPT)
		return false
	_clear_session()
	_active = save.info
	_active.slot_id = slot.slot_id
	_state = save.state
	_saved_state = save.state.duplicate(true)
	_progress = save.progress
	_load_on_scene_change = true
	return true


## Level scene of the active slot, or "" if none.
func get_active_level_path() -> String:
	return _active.level_path if _active != null else ""


## True while a slot is active and the current scene is a Level.
func can_save() -> bool:
	return _active != null and get_tree().current_scene is Level


## Emits save_started, then writes the current level, state and progress to the active slot.
func save_current() -> void:
	var slot_id: String = _active.slot_id if _active != null else ""
	if not can_save():
		push_warning("SaveSystem: nothing to save (no active slot or not in a level).")
		save_failed.emit(slot_id, ERR_UNAVAILABLE)
		return
	var level: Level = get_tree().current_scene as Level
	_active.level_path = level.scene_file_path
	_active.level_name = level.display_name
	_active.saved_at_unix = int(Time.get_unix_time_from_system())
	save_started.emit()
	_saved_state = _state.duplicate(true)
	if _write_slot() == OK:
		save_completed.emit(_active)


## Leaves the active slot (back to the title screen).
func end_session() -> void:
	_clear_session()


## Stores value under key in the live state; written by the next save_current().
## Ignored with a warning if no slot is active or value is not plain data.
func set_state(key: StringName, value: Variant) -> void:
	if _can_store("set_state", key, value):
		_state[key] = value


## State stored under key, or default. Containers are shared: don't modify them in place.
func get_state(key: StringName, default: Variant = null) -> Variant:
	return _state.get(key, default)


func has_state(key: StringName) -> bool:
	return _state.has(key)


func erase_state(key: StringName) -> void:
	_state.erase(key)


## Stores progress and writes the slot file at the end of the frame; emits progress_saved
## once it is on disk. Ignored with a warning if no slot is active or value is not plain data.
func save_progress(key: StringName, value: Variant) -> void:
	if not _can_store("save_progress", key, value):
		return
	_progress[key] = value
	if not _dirty_progress_keys.has(key):
		_dirty_progress_keys.append(key)
	if not _progress_flush_queued:
		_progress_flush_queued = true
		_flush_progress.call_deferred()


## Progress stored under key, or default. Containers are shared: don't modify them in place.
func get_progress(key: StringName, default: Variant = null) -> Variant:
	return _progress.get(key, default)


func has_progress(key: StringName) -> bool:
	return _progress.has(key)


## Adds id to the unlock set category (a progress key) and saves it.
## Returns true if id was new; false if already unlocked or no slot is active.
func unlock(category: StringName, id: StringName) -> bool:
	if not _can_store("unlock", category, id):
		return false
	var unlocked: Array[StringName] = get_unlocked(category)
	if unlocked.has(id):
		return false
	unlocked.append(id)
	save_progress(category, unlocked)
	return true


func is_unlocked(category: StringName, id: StringName) -> bool:
	return get_unlocked(category).has(id)


## Copy of the ids unlocked in category, in unlock order.
func get_unlocked(category: StringName) -> Array[StringName]:
	var unlocked: Array[StringName] = []
	var stored: Variant = _progress.get(category, [])
	if not stored is Array:
		push_warning("SaveSystem: progress '%s' is not an unlock set." % category)
		return unlocked
	for id: Variant in stored:
		unlocked.append(StringName(str(id)))
	return unlocked


func _can_store(caller: String, key: StringName, value: Variant) -> bool:
	if _active == null:
		push_warning("SaveSystem: %s('%s') ignored, no active save slot." % [caller, key])
		return false
	if not SaveGame.is_plain_data(value):
		push_warning("SaveSystem: %s('%s') ignored, value contains an Object, Callable, Signal or RID." % [caller, key])
		return false
	return true


## Deferred from save_progress(): one write for all progress changed this frame.
func _flush_progress() -> void:
	_progress_flush_queued = false
	if _active == null or _dirty_progress_keys.is_empty():
		return
	# Level path/name stay as of the last full save: they belong to the saved state
	# snapshot (loading opens that level and applies that state). saved_at (and the
	# running playtime) describe the slot as a whole and the file really is written
	# now, so they are current; the Load menu then sorts and shows the slot correctly.
	_active.saved_at_unix = int(Time.get_unix_time_from_system())
	_write_slot()


## Writes _active, _saved_state and _progress to the slot file. On success emits
## progress_saved for every progress key it wrote; on error emits save_failed.
func _write_slot() -> Error:
	var save: SaveGame = SaveGame.new()
	save.info = _active
	save.state = _saved_state
	save.progress = _progress
	var error: Error = SaveSlotFiles.ensure_save_dir()
	if error == OK:
		var path: String = SaveSlotFiles.get_slot_path(_active.slot_id, SaveSlotFiles.get_write_extension(_encrypt))
		error = save.write(path, _config.encryption_password)
	if error != OK:
		save_failed.emit(_active.slot_id, error)
		return error
	SaveSlotFiles.remove_other_format(_active.slot_id, _encrypt)
	var written_keys: Array[StringName] = _dirty_progress_keys
	_dirty_progress_keys = []
	for key: StringName in written_keys:
		progress_saved.emit(key)
	return OK


## Ends the session, first writing progress still waiting for its deferred flush.
func _clear_session() -> void:
	if _active != null and not _dirty_progress_keys.is_empty():
		_flush_progress()
	_active = null
	_state = {}
	_saved_state = {}
	_progress = {}
	_dirty_progress_keys = []
	_load_on_scene_change = false
	_save_on_scene_change = false


func _on_scene_changed() -> void:
	if _load_on_scene_change:
		_load_on_scene_change = false
		load_completed.emit(_active)
	elif _save_on_scene_change:
		_save_on_scene_change = false
		save_current()
