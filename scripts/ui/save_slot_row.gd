class_name SaveSlotRow
extends Button
## One save slot in the Load menu. Pressing it reports the slot.

signal slot_selected(info: SaveSlotInfo)

var _info: SaveSlotInfo

@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _playtime_label: Label = %PlaytimeLabel
@onready var _saved_at_label: Label = %SavedAtLabel


func _ready() -> void:
	pressed.connect(_on_pressed)


## Call after the row is in the tree.
func setup(info: SaveSlotInfo) -> void:
	_info = info
	_name_label.text = info.display_name
	_level_label.text = info.level_name
	_playtime_label.text = info.get_playtime_text()
	_saved_at_label.text = info.get_saved_at_text()


func _on_pressed() -> void:
	slot_selected.emit(_info)
