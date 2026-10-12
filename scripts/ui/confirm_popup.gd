class_name ConfirmPopup
extends Panel
## Modal yes/no question over a dimmed screen. Focus stays inside while open and
## returns to the control that had it when the popup closes.

signal confirmed
signal cancelled

var _opener: Control

@onready var _message: Label = %Message
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_trap_focus(_confirm_button, _cancel_button)
	_trap_focus(_cancel_button, _confirm_button)


func open(message: String) -> void:
	_opener = get_viewport().gui_get_focus_owner()
	_message.text = message
	show()
	_cancel_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Modal: nothing behind the popup reacts while it is open.
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()


func _on_confirm_pressed() -> void:
	_close()
	confirmed.emit()


func _on_cancel_pressed() -> void:
	_close()
	cancelled.emit()


func _close() -> void:
	hide()
	if is_instance_valid(_opener) and _opener.is_visible_in_tree():
		_opener.grab_focus()
	_opener = null


## Keeps keyboard/gamepad focus moving only between the two buttons.
func _trap_focus(button: Button, other: Button) -> void:
	var self_path: NodePath = button.get_path_to(button)
	var other_path: NodePath = button.get_path_to(other)
	button.focus_neighbor_top = self_path
	button.focus_neighbor_bottom = self_path
	button.focus_neighbor_left = other_path
	button.focus_neighbor_right = other_path
	button.focus_next = other_path
	button.focus_previous = other_path
