class_name RebindRow
extends HBoxContainer
## One rebindable action: its name plus a keyboard/mouse and a gamepad RebindButton.

signal binding_changed(action: StringName, events: Array[InputEvent])

var _action: RebindableAction
var _events: Array[InputEvent] = []

@onready var _action_label: Label = %ActionLabel
@onready var _keyboard_button: RebindButton = %KeyboardButton
@onready var _gamepad_button: RebindButton = %GamepadButton


func _ready() -> void:
	_keyboard_button.binding_captured.connect(_on_binding_captured.bind(false))
	_gamepad_button.binding_captured.connect(_on_binding_captured.bind(true))


## Call after the row is in the tree.
func setup(action: RebindableAction, events: Array[InputEvent]) -> void:
	_action = action
	_action_label.text = action.display_name
	set_events(events)


func set_events(events: Array[InputEvent]) -> void:
	_events = events.duplicate()
	_keyboard_button.show_event(InputBindings.get_first_event(_events, false))
	_gamepad_button.show_event(InputBindings.get_first_event(_events, true))


func _on_binding_captured(event: InputEvent, is_gamepad: bool) -> void:
	binding_changed.emit(_action.action, InputBindings.replace_event(_events, event, is_gamepad))
