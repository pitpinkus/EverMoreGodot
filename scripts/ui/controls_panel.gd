class_name ControlsPanel
extends VBoxContainer
## Lists every action of action_list as a RebindRow, with a heading wherever the
## action's section changes. Binding an input that another listed action of a shared
## context (overworld / battle) already uses removes it from that action; inputs of
## the list's reserved actions are refused. Changes are reported with bindings_changed;
## nothing is applied here.

signal bindings_changed(action: StringName, events: Array[InputEvent])

@export var action_list: RebindableActionList
## Scene instanced once per action; its root must be a RebindRow.
@export var row_scene: PackedScene
## Theme type variation of the section headings inserted between rows.
@export var section_variation: StringName = &"SectionLabel"

var _rows: Dictionary[StringName, RebindRow] = {}
var _action_names: Array[StringName] = []
var _overrides: Dictionary[StringName, Array] = {}

@onready var _rows_box: VBoxContainer = %Rows
@onready var _reset_controls_button: Button = %ResetControlsButton


func _ready() -> void:
	_reset_controls_button.pressed.connect(_on_reset_controls_pressed)
	if action_list == null or row_scene == null:
		push_error("ControlsPanel '%s' needs action_list and row_scene." % name)
		return
	_action_names = action_list.get_action_names()
	var section: String = ""
	for entry: RebindableAction in action_list.actions:
		if entry.section != section:
			section = entry.section
			_add_section_label(section)
		var row: RebindRow = row_scene.instantiate() as RebindRow
		if row == null:
			push_error("ControlsPanel '%s': row_scene root is not a RebindRow." % name)
			return
		_rows_box.add_child(row)
		row.setup(entry, InputBindings.get_events(_overrides, entry.action))
		row.binding_changed.connect(_on_row_binding_changed)
		_rows[entry.action] = row


## Shows the bindings stored in settings.
func load_from(settings: GameSettings) -> void:
	_overrides = settings.input_overrides.duplicate(true)
	for action: StringName in _rows:
		_rows[action].set_events(InputBindings.get_events(_overrides, action))


func _on_row_binding_changed(action: StringName, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		if InputBindings.find_conflict(_overrides, event, action_list.reserved_actions, action) != &"":
			# Refused: the row goes back to showing its previous bindings.
			_rows[action].set_events(InputBindings.get_events(_overrides, action))
			return
	for event: InputEvent in events:
		var other: StringName = InputBindings.find_conflict(_overrides, event,
				action_list.get_conflict_candidates(action), action)
		if other != &"":
			_change_binding(other, InputBindings.remove_event(InputBindings.get_events(_overrides, other), event))
	_change_binding(action, events)


func _on_reset_controls_pressed() -> void:
	for action: StringName in _action_names:
		_change_binding(action, InputBindings.get_default_events(action))


func _add_section_label(text: String) -> void:
	var label: Label = Label.new()
	label.theme_type_variation = section_variation
	label.text = text
	_rows_box.add_child(label)


func _change_binding(action: StringName, events: Array[InputEvent]) -> void:
	InputBindings.set_override(_overrides, action, events)
	_rows[action].set_events(events)
	bindings_changed.emit(action, events)
