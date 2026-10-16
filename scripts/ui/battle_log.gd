class_name BattleLog
extends PanelContainer
## The last few battle messages, newest at the bottom (%LogLabel).

@export_range(1, 20, 1) var max_lines: int = 4

var _lines: PackedStringArray = []

@onready var _log_label: Label = %LogLabel


func _ready() -> void:
	_log_label.text = ""


func add_message(text: String) -> void:
	_lines.append(text)
	if _lines.size() > max_lines:
		_lines = _lines.slice(_lines.size() - max_lines)
	_log_label.text = "\n".join(_lines)
