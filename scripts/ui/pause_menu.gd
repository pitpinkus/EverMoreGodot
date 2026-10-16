class_name PauseMenu
extends ScreenBase
## In-game pause menu. The pause action opens it and closes it again when no submenu
## is open. Continue, Save, Settings, Quit to title screen. Pausing the tree and
## restoring the mouse is done by its PauseWhileVisibleComponent child.
## The scene root must use process_mode ALWAYS so it works while paused.

@export_multiline var quit_message: String = "Quit to the title screen? Unsaved progress will be lost."
## Shown in %SaveStatusLabel after a successful save.
@export var saved_text: String = "Game saved"
## Shown in %SaveStatusLabel when saving fails.
@export var save_failed_text: String = "Save failed"

@onready var _continue_button: Button = %ContinueButton
@onready var _save_button: Button = %SaveButton
@onready var _save_status_label: Label = %SaveStatusLabel
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _confirm_popup: ConfirmPopup = %ConfirmPopup
@onready var _switcher: SubmenuSwitcher = %SubmenuSwitcher


func _ready() -> void:
	super()
	_continue_button.pressed.connect(resume)
	_save_button.pressed.connect(SaveSystem.save_current)
	SaveSystem.save_completed.connect(_on_save_completed)
	SaveSystem.save_failed.connect(_on_save_failed)
	_settings_button.pressed.connect(_switcher.open.bind(_settings_menu, _settings_button))
	_quit_button.pressed.connect(_confirm_popup.open.bind(quit_message))
	_confirm_popup.confirmed.connect(GameFlow.go_to_title_screen)
	back_requested.connect(resume)


## Shows the menu (which pauses the game).
func open() -> void:
	_save_button.disabled = not SaveSystem.can_save()
	# A disabled button must not take keyboard/gamepad focus; VBox order skips it.
	FocusUtils.set_focusable(_save_button, not _save_button.disabled)
	_save_status_label.text = ""
	super()


## Hides the menu (which unpauses the game).
func resume() -> void:
	close()


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


func _on_save_completed(_info: SaveSlotInfo) -> void:
	_save_status_label.text = saved_text


func _on_save_failed(_slot_id: String, _error: Error) -> void:
	_save_status_label.text = save_failed_text
