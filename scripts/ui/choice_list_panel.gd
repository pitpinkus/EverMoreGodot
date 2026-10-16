class_name ChoiceListPanel
extends PanelContainer
## The shared list widget (battle moves/items, inventory, party picker). open() fills
## it with ChoiceEntry rows; the player picks one with ui_accept/click or backs out
## with ui_cancel, then choice_finished fires once. Focus and hover both show the
## row's description; pressing an unavailable row shows why it is unavailable.

## Picked row index, or -1 if cancelled.
signal choice_finished(index: int)

@export var row_scene: PackedScene

var _rows: Array[ChoiceRow] = []

@onready var _title_label: Label = %TitleLabel
@onready var _rows_box: Container = %Rows
@onready var _description_label: Label = %DescriptionLabel
@onready var _empty_label: Control = %EmptyLabel


func _ready() -> void:
	if row_scene == null:
		push_error("ChoiceListPanel '%s' has no row_scene assigned." % name)
	hide()


## Shows entries under title and focuses the first row.
func open(title: String, entries: Array[ChoiceEntry]) -> void:
	_title_label.text = title
	_clear_rows()
	for index: int in entries.size():
		var row: ChoiceRow = row_scene.instantiate() as ChoiceRow
		_rows_box.add_child(row)
		row.set_entry(entries[index])
		row.pressed.connect(_on_row_pressed.bind(index))
		row.focus_entered.connect(_show_description.bind(entries[index].description))
		_rows.append(row)
	var controls: Array[Control] = []
	controls.assign(_rows)
	FocusUtils.setup_vertical_list(controls)
	_empty_label.visible = _rows.is_empty()
	_description_label.text = ""
	show()
	if not _rows.is_empty():
		_rows[0].grab_focus.call_deferred()


## The control that should hold focus (first row), or null if the list is empty or hidden.
func get_focus_target() -> Control:
	return _rows[0] if visible and not _rows.is_empty() else null


## Hides the list without emitting choice_finished.
func close() -> void:
	hide()
	_clear_rows()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(-1)


func _on_row_pressed(index: int) -> void:
	var entry: ChoiceEntry = _rows[index].entry
	if entry.enabled:
		_finish(index)
	else:
		_show_description(entry.disabled_reason)


func _finish(index: int) -> void:
	close()
	choice_finished.emit(index)


func _show_description(text: String) -> void:
	_description_label.text = text


func _clear_rows() -> void:
	for row: ChoiceRow in _rows:
		row.queue_free()
	_rows.clear()
