extends Node
## Autoload. Moves the game between its top-level states (title screen, playing, quit).

const START_LEVEL_PATH: String = "res://levels/test_overworld.tscn"
const TITLE_SCREEN_PATH: String = "res://ui/screens/title_screen.tscn"


## Starts a new game at START_LEVEL_PATH.
## Hook: once saving exists, SaveSystem creates the new save slot here.
func start_new_game() -> void:
	_change_scene(START_LEVEL_PATH)


## Continues from a save slot.
## Hook: SaveSystem will restore the slot's level, spawn point and state here;
## until then every slot opens START_LEVEL_PATH.
func load_game(slot: SaveSlotInfo) -> void:
	if slot == null:
		push_error("GameFlow: load_game() called without a save slot.")
		return
	_change_scene(START_LEVEL_PATH)


## Leaves the current game (unpausing first) and shows the title screen.
func go_to_title_screen() -> void:
	resume_game()
	_change_scene(TITLE_SCREEN_PATH)


## Freezes gameplay. Nodes with process_mode ALWAYS (menus) keep running.
func pause_game() -> void:
	get_tree().paused = true


func resume_game() -> void:
	get_tree().paused = false


func quit_game() -> void:
	get_tree().quit()


func _change_scene(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("GameFlow: could not open '%s' (%s)." % [path, error_string(error)])
