class_name PauseMenu
extends ScreenBase
## In-game pause menu: a grid of tiles (Party, Bag, Save, Options, Quit to Title,
## Continue). Party, Bag and Options open submenus in place of the grid. The pause
## action opens it and closes it again when no submenu is open; the inventory action
## opens it straight on the Bag (and closes it from there). field_tiles_enabled = false
## (battle) hides Party, Bag and Save and ignores the inventory action.
## Pausing the tree and restoring the mouse is done by its PauseWhileVisibleComponent
## child. The scene root must use process_mode ALWAYS so it works while paused.

@export_multiline var quit_message: String = "Quit to the title screen? Unsaved progress will be lost."
## Shown in %SaveStatusLabel after a successful save.
@export var saved_text: String = "Game saved"
## Shown in %SaveStatusLabel when saving fails.
@export var save_failed_text: String = "Save failed"
## Party, Bag and Save tiles (overworld only).
@export var field_tiles_enabled: bool = true

@onready var _party_tile: Button = %PartyTile
@onready var _bag_tile: Button = %BagTile
@onready var _save_tile: Button = %SaveTile
@onready var _options_tile: Button = %OptionsTile
@onready var _quit_tile: Button = %QuitTile
@onready var _continue_tile: Button = %ContinueTile
@onready var _tiles: GridContainer = %Tiles
@onready var _save_status_label: Label = %SaveStatusLabel
@onready var _party_screen: PartyScreen = %PartyScreen
@onready var _bag_screen: InventoryScreen = %BagScreen
@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _confirm_popup: ConfirmPopup = %ConfirmPopup
@onready var _switcher: SubmenuSwitcher = %SubmenuSwitcher


func _ready() -> void:
	super()
	_continue_tile.pressed.connect(resume)
	_save_tile.pressed.connect(SaveSystem.save_current)
	SaveSystem.save_completed.connect(_on_save_completed)
	SaveSystem.save_failed.connect(_on_save_failed)
	_party_tile.pressed.connect(_switcher.open.bind(_party_screen, _party_tile))
	_bag_tile.pressed.connect(_switcher.open.bind(_bag_screen, _bag_tile))
	_options_tile.pressed.connect(_switcher.open.bind(_settings_menu, _options_tile))
	_quit_tile.pressed.connect(_confirm_popup.open.bind(quit_message))
	_confirm_popup.confirmed.connect(GameFlow.go_to_title_screen)
	back_requested.connect(resume)
	for tile: Button in [_party_tile, _bag_tile, _save_tile]:
		tile.visible = field_tiles_enabled


## Shows the menu (which pauses the game).
func open() -> void:
	_save_tile.disabled = not SaveSystem.can_save()
	# A disabled tile must not take keyboard/gamepad focus.
	FocusUtils.set_focusable(_save_tile, _save_tile.visible and not _save_tile.disabled)
	_link_tile_focus()
	_save_status_label.text = ""
	super()


## Opens the menu straight on the Bag.
func open_bag() -> void:
	open()
	_switcher.open(_bag_screen, _bag_tile)


## Hides the menu (which unpauses the game).
func resume() -> void:
	close()


## The first tile shown: Party, or Options when the field tiles are hidden.
func _get_initial_focus() -> Control:
	return _party_tile if field_tiles_enabled else _options_tile


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
	elif field_tiles_enabled and event.is_action_pressed("inventory"):
		if not visible and not get_tree().paused:
			get_viewport().set_input_as_handled()
			open_bag()
			return
		if _bag_screen.visible:
			get_viewport().set_input_as_handled()
			_bag_screen.close()
			resume()
			return
	super(event)


## Arrow / stick neighbours over the shown tiles, skipping ones that can't take focus.
func _link_tile_focus() -> void:
	var shown: Array[Control] = []
	for tile: Button in [_party_tile, _bag_tile, _save_tile, _options_tile, _quit_tile, _continue_tile]:
		if tile.visible:
			shown.append(tile)
	FocusUtils.wrap_grid(shown, _tiles.columns)


func _on_save_completed(_info: SaveSlotInfo) -> void:
	_save_status_label.text = saved_text


func _on_save_failed(_slot_id: String, _error: Error) -> void:
	_save_status_label.text = save_failed_text
