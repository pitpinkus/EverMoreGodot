class_name PauseMenu
extends ScreenBase
## In-game pause menu. The pause action opens it (pausing the tree) and closes it
## again when no submenu is open. Continue, Settings, Quit to title screen.
## The scene root must use process_mode ALWAYS so it works while paused.

@export_multiline var quit_message: String = "Quit to the title screen? Unsaved progress will be lost."

## Mouse mode before pausing, restored on resume.
var _resume_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _confirm_popup: ConfirmPopup = %ConfirmPopup
@onready var _switcher: SubmenuSwitcher = %SubmenuSwitcher


func _ready() -> void:
	super()
	_continue_button.pressed.connect(resume)
	_settings_button.pressed.connect(_switcher.open.bind(_settings_menu, _settings_button))
	_quit_button.pressed.connect(_confirm_popup.open.bind(quit_message))
	_confirm_popup.confirmed.connect(GameFlow.go_to_title_screen)
	back_requested.connect(resume)


## Pauses the game and shows the menu.
func open() -> void:
	_resume_mouse_mode = Input.mouse_mode
	GameFlow.pause_game()
	super()


## Hides the menu and unpauses the game.
func resume() -> void:
	close()
	GameFlow.resume_game()
	Input.mouse_mode = _resume_mouse_mode


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not visible:
			get_viewport().set_input_as_handled()
			open()
			return
		if not _switcher.is_open():
			get_viewport().set_input_as_handled()
			resume()
			return
	super(event)
