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


## Vertical list wiring: hovering a control focuses it, and focus moves down/up through
## controls (in order) with wrap-around. Does nothing for an empty list.
static func setup_vertical_list(controls: Array[Control]) -> void:
	if controls.is_empty():
		return
	for control: Control in controls:
		control.mouse_entered.connect(control.grab_focus)
	wrap_vertical(controls)


## Grid wiring for cells laid out row by row in columns: left / right go to the next
## focusable cell in reading order, up / down to the cell above / below (wrapping) or,
## if that one can't take focus, the focusable cell nearest to it. Tab order follows
## reading order.
static func wrap_grid(cells: Array[Control], columns: int) -> void:
	var count: int = cells.size()
	var focusable: Array[Control] = []
	focusable.assign(cells.filter(func(cell: Control) -> bool: return cell.focus_mode != Control.FOCUS_NONE))
	for index: int in count:
		var cell: Control = cells[index]
		if not focusable.has(cell):
			continue
		cell.focus_neighbor_left = cell.get_path_to(_step_to_focusable(cells, focusable, index, -1))
		cell.focus_neighbor_right = cell.get_path_to(_step_to_focusable(cells, focusable, index, 1))
		cell.focus_neighbor_top = cell.get_path_to(_vertical_target(cells, focusable, index, -columns))
		cell.focus_neighbor_bottom = cell.get_path_to(_vertical_target(cells, focusable, index, columns))
		cell.focus_next = cell.focus_neighbor_right
		cell.focus_previous = cell.focus_neighbor_left


## The cell step (± columns) away from index, or the focusable cell nearest to it in
## reading order (never index itself unless nothing else can take focus).
static func _vertical_target(cells: Array[Control], focusable: Array[Control], index: int, step: int) -> Control:
	var count: int = cells.size()
	var target: int = posmod(index + step, count)
	var best: Control = cells[index]
	var best_distance: int = count
	for candidate: int in count:
		var distance: int = absi(candidate - target)
		if candidate != index and focusable.has(cells[candidate]) and distance < best_distance:
			best = cells[candidate]
			best_distance = distance
	return best


## The first focusable cell found stepping step cells at a time from index (wrapping).
static func _step_to_focusable(cells: Array[Control], focusable: Array[Control], index: int, step: int) -> Control:
	var count: int = cells.size()
	var next: int = index
	for _attempt: int in count:
		next = posmod(next + step, count)
		if focusable.has(cells[next]):
			return cells[next]
	return cells[index]
