class_name TitleScreen
extends ScreenBase
## Title screen: Start, Load, Settings, Quit. Load and Settings open embedded
## submenus through the SubmenuSwitcher.

## OS feature tag of web exports, where quitting is not possible.
const WEB_FEATURE: String = "web"

@onready var _start_button: Button = %StartButton
@onready var _load_button: Button = %LoadButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _load_menu: LoadMenu = %LoadMenu
@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _switcher: SubmenuSwitcher = %SubmenuSwitcher


func _ready() -> void:
	super()
	_start_button.pressed.connect(GameFlow.start_new_game)
	_load_button.pressed.connect(_switcher.open.bind(_load_menu, _load_button))
	_settings_button.pressed.connect(_switcher.open.bind(_settings_menu, _settings_button))
	_quit_button.pressed.connect(GameFlow.quit_game)
	if OS.has_feature(WEB_FEATURE):
		_hide_quit_button()


## Quit can't work on the web; hide it and close the focus wrap around it.
func _hide_quit_button() -> void:
	_quit_button.hide()
	_start_button.focus_neighbor_top = _start_button.get_path_to(_settings_button)
	_settings_button.focus_neighbor_bottom = _settings_button.get_path_to(_start_button)
