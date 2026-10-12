class_name LoadMenu
extends ScreenBase
## Lists the save slots from SaveSystem; choosing one loads it through GameFlow.

## Scene instanced once per save slot; its root must be a SaveSlotRow.
@export var slot_row_scene: PackedScene
@export_multiline var empty_text: String = "No saved games"

@onready var _slot_list: VBoxContainer = %SlotList
@onready var _empty_label: Label = %EmptyLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	super()
	_empty_label.text = empty_text
	_back_button.pressed.connect(close)
	back_requested.connect(close)


## Rebuilds the slot list, then shows the menu.
func open() -> void:
	_rebuild_slots()
	super()


func _get_initial_focus() -> Control:
	if _slot_list.get_child_count() > 0:
		return _slot_list.get_child(0) as Control
	return _back_button


func _rebuild_slots() -> void:
	for child: Node in _slot_list.get_children():
		_slot_list.remove_child(child)
		child.queue_free()
	var saves: Array[SaveSlotInfo] = SaveSystem.list_saves()
	_empty_label.visible = saves.is_empty()
	if slot_row_scene == null:
		if not saves.is_empty():
			push_error("LoadMenu '%s' has no slot_row_scene assigned." % name)
		return
	for info: SaveSlotInfo in saves:
		var row: SaveSlotRow = slot_row_scene.instantiate() as SaveSlotRow
		if row == null:
			push_error("LoadMenu '%s': slot_row_scene root is not a SaveSlotRow." % name)
			return
		_slot_list.add_child(row)
		row.setup(info)
		row.slot_selected.connect(GameFlow.load_game)
