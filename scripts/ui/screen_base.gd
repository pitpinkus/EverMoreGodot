class_name ScreenBase
extends Control
## Base for full-screen menus. When shown it frees the mouse cursor and focuses a
## control; ui_cancel becomes back_requested. If keyboard/gamepad navigation
## happens while nothing inside has focus, focus is grabbed again.

signal back_requested
signal closed

const NAVIGATION_ACTIONS: Array[StringName] = [
	&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev", &"ui_accept",
]

## Control focused when the screen becomes visible.
@export var initial_focus: Control


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	InputDeviceTracker.device_changed.connect(_on_device_changed)
	if is_visible_in_tree():
		_on_visibility_changed()


## Shows the screen. Override to prepare content first, then call super().
func open() -> void:
	show()


## Hides the screen and emits closed.
func close() -> void:
	hide()
	closed.emit()


## Focuses the screen's initial control, if it can take focus right now.
func focus_initial() -> void:
	var target: Control = _get_initial_focus()
	if target != null and target.is_visible_in_tree():
		target.grab_focus()


## Override to pick the initial focus dynamically.
func _get_initial_focus() -> Control:
	return initial_focus


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()
	elif _is_navigation(event) and not _owns_focus():
		get_viewport().set_input_as_handled()
		focus_initial()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Deferred: children only count as visible once this signal has finished propagating.
		focus_initial.call_deferred()


func _on_device_changed(device: InputDeviceTracker.Device) -> void:
	if device == InputDeviceTracker.Device.GAMEPAD and is_visible_in_tree() and not _owns_focus():
		focus_initial()


func _owns_focus() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner != null and is_ancestor_of(focus_owner)


func _is_navigation(event: InputEvent) -> bool:
	for action: StringName in NAVIGATION_ACTIONS:
		if event.is_action_pressed(action, true):
			return true
	return false
