class_name FocusUtils
extends RefCounted
## Static focus helpers shared by UI scripts.


## Lets control take keyboard/gamepad focus or not. A control that loses focusability
## while focused hands focus to the next valid control, so focus never sits on a
## disabled control.
static func set_focusable(control: Control, focusable: bool) -> void:
	if focusable:
		control.focus_mode = Control.FOCUS_ALL
		return
	var had_focus: bool = control.has_focus()
	control.focus_mode = Control.FOCUS_NONE
	if not had_focus:
		return
	var next: Control = control.find_next_valid_focus()
	if next != null and next != control:
		next.grab_focus()
	else:
		control.release_focus()


## Links controls (in order) so focus moves down/up through them and wraps from the
## last back to the first (Tab / Shift+Tab follow the same order).
static func wrap_vertical(controls: Array[Control]) -> void:
	var count: int = controls.size()
	for index: int in count:
		var control: Control = controls[index]
		var next: Control = controls[(index + 1) % count]
		var previous: Control = controls[(index - 1 + count) % count]
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_next = control.focus_neighbor_bottom
		control.focus_previous = control.focus_neighbor_top
