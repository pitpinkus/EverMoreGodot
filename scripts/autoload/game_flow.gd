extends Node
## Autoload. Moves the game between its top-level states (title screen, playing, quit).

const START_LEVEL_PATH: String = "res://levels/test_overworld.tscn"
const TITLE_SCREEN_PATH: String = "res://ui/screens/title_screen.tscn"


## Starts a new game at START_LEVEL_PATH in a fresh save slot.
func start_new_game() -> void:
	PlayerProfile.reset_to_starting_profile()
	BattleFlow.reset()
	SaveSystem.begin_new_game(START_LEVEL_PATH)
	_change_scene_or_end_session(START_LEVEL_PATH)


## Continues from a save slot: opens its level; SaveSystem restores the saved state.
func load_game(slot: SaveSlotInfo) -> void:
	BattleFlow.reset()
	if not SaveSystem.begin_load(slot):
		return
	_change_scene_or_end_session(SaveSystem.get_active_level_path())


## Leaves the current game (unpausing first) and shows the title screen.
func go_to_title_screen() -> void:
	resume_game()
	SaveSystem.end_session()
	BattleFlow.reset()
	change_scene(TITLE_SCREEN_PATH)


## Freezes gameplay. Nodes with process_mode ALWAYS (menus) keep running.
func pause_game() -> void:
	get_tree().paused = true


func resume_game() -> void:
	get_tree().paused = false


func quit_game() -> void:
	get_tree().quit()


## Opens the scene at path (at the end of the frame). Logs and returns the error if it can't.
func change_scene(path: String) -> Error:
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("GameFlow: could not open '%s' (%s)." % [path, error_string(error)])
	return error


## Drops the just-started save session if its level cannot be opened.
func _change_scene_or_end_session(path: String) -> void:
	if change_scene(path) != OK:
		SaveSystem.end_session()
