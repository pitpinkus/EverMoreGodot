class_name SettingsMenu
extends ScreenBase
## Tabbed settings screen. Edits a copy of SettingsManager.current; changes take
## effect only on Apply. Every descendant SettingRow edits the GameSettings
## property named by its setting_key; ControlsPanel edits the input overrides.

const RESOLUTION_KEY: StringName = &"resolution"
const WINDOW_MODE_KEY: StringName = &"window_mode"
const MAX_FPS_KEY: StringName = &"max_fps"
const QUALITY_KEY: StringName = &"quality_preset"

@export_multiline var reset_message: String = "Reset all settings to their defaults?"
@export_multiline var discard_message: String = "Discard unsaved changes?"

var _pending: GameSettings
var _rows: Array[SettingRow] = []
var _dirty: bool = false
## Runs when the confirm popup is confirmed.
var _confirm_action: Callable

@onready var _tabs: TabContainer = %Tabs
@onready var _controls_panel: ControlsPanel = %ControlsPanel
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _apply_button: Button = %ApplyButton
@onready var _confirm_popup: ConfirmPopup = %ConfirmPopup


func _ready() -> void:
	super()
	_collect_rows(self)
	for row: SettingRow in _rows:
		row.value_changed.connect(_on_row_value_changed)
	_fill_display_options()
	_controls_panel.bindings_changed.connect(_on_bindings_changed)
	_tabs.tab_changed.connect(_on_tab_changed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_apply_button.pressed.connect(_on_apply_pressed)
	_confirm_popup.confirmed.connect(_on_popup_confirmed)
	back_requested.connect(_on_back_pressed)


## Shows the menu with a fresh copy of the current settings.
func open() -> void:
	_pending = SettingsManager.current.duplicate(true) as GameSettings
	_refresh_rows()
	_set_dirty(false)
	_tabs.current_tab = 0
	_update_footer_neighbors()
	super()


func _get_initial_focus() -> Control:
	var focus: Control = _find_focusable(_tabs.get_current_tab_control(), false)
	return focus if focus != null else _back_button


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_tab_next"):
		get_viewport().set_input_as_handled()
		_switch_tab(1)
	elif is_visible_in_tree() and event.is_action_pressed("ui_tab_prev"):
		get_viewport().set_input_as_handled()
		_switch_tab(-1)
	else:
		super(event)


func _collect_rows(node: Node) -> void:
	for child: Node in node.get_children():
		if child is SettingRow:
			_rows.append(child)
		_collect_rows(child)


func _find_row(key: StringName) -> SettingRow:
	for row: SettingRow in _rows:
		if row.setting_key == key:
			return row
	return null


func _fill_display_options() -> void:
	var options: DisplayOptions = SettingsManager.display_options
	_set_row_options(RESOLUTION_KEY, options.get_resolution_labels(), options.resolutions)
	_set_row_options(MAX_FPS_KEY, options.get_fps_labels(), Array(options.fps_caps))
	_set_row_options(QUALITY_KEY, options.get_quality_labels(), [])


func _set_row_options(key: StringName, labels: PackedStringArray, values: Array) -> void:
	var row: OptionSettingRow = _find_row(key) as OptionSettingRow
	if row == null:
		push_warning("SettingsMenu: no OptionSettingRow with setting_key '%s'." % key)
		return
	row.set_options(labels, values)


func _refresh_rows() -> void:
	for row: SettingRow in _rows:
		row.set_value(_pending.get(row.setting_key))
	_update_resolution_enabled()
	_controls_panel.load_from(_pending)


func _update_resolution_enabled() -> void:
	var row: SettingRow = _find_row(RESOLUTION_KEY)
	if row != null:
		row.set_disabled(_pending.window_mode != GameSettings.WindowMode.WINDOWED)


func _set_dirty(dirty: bool) -> void:
	_dirty = dirty
	_apply_button.disabled = not dirty
	FocusUtils.set_focusable(_apply_button, dirty)


func _switch_tab(direction: int) -> void:
	_tabs.current_tab = wrapi(_tabs.current_tab + direction, 0, _tabs.get_tab_count())
	focus_initial()


## First (or last) visible control inside node that takes keyboard focus.
func _find_focusable(node: Node, from_end: bool) -> Control:
	var children: Array[Node] = node.get_children()
	if from_end:
		children.reverse()
	for child: Node in children:
		var control: Control = child as Control
		if control == null or not control.visible:
			continue
		if control.focus_mode == Control.FOCUS_ALL:
			return control
		var nested: Control = _find_focusable(control, from_end)
		if nested != null:
			return nested
	return null


## Pressing up from the footer goes to the last control of the current tab.
func _update_footer_neighbors() -> void:
	var target: Control = _find_focusable(_tabs.get_current_tab_control(), true)
	for button: Button in [_reset_button, _back_button, _apply_button]:
		button.focus_neighbor_top = NodePath() if target == null else button.get_path_to(target)


func _ask(message: String, action: Callable) -> void:
	_confirm_action = action
	_confirm_popup.open(message)


func _reset_to_defaults() -> void:
	_pending = SettingsManager.get_defaults()
	_refresh_rows()
	_set_dirty(true)


func _on_row_value_changed(key: StringName, value: Variant) -> void:
	if _pending.get(key) == null:
		push_warning("SettingsMenu: GameSettings has no setting '%s'." % key)
		return
	_pending.set(key, value)
	_set_dirty(true)
	if key == WINDOW_MODE_KEY:
		_update_resolution_enabled()


func _on_bindings_changed(action: StringName, events: Array[InputEvent]) -> void:
	InputBindings.set_override(_pending.input_overrides, action, events)
	_set_dirty(true)


func _on_tab_changed(_tab: int) -> void:
	_update_footer_neighbors()


func _on_apply_pressed() -> void:
	SettingsManager.apply(_pending)
	SettingsManager.save()
	_set_dirty(false)
	_back_button.grab_focus()


func _on_reset_pressed() -> void:
	_ask(reset_message, _reset_to_defaults)


func _on_back_pressed() -> void:
	if _dirty:
		_ask(discard_message, close)
	else:
		close()


func _on_popup_confirmed() -> void:
	_confirm_action.call()
