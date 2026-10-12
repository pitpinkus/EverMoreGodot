class_name OptionSettingRow
extends SettingRow
## Setting row edited with an OptionButton. Each item maps to a value; with no
## explicit values the item index is the value (fits enum settings).

## Static item labels (index = value). Leave empty to fill with set_options().
@export var option_labels: PackedStringArray = PackedStringArray()

var _values: Array = []

@onready var _options: OptionButton = %Options


func _ready() -> void:
	super()
	_options.item_selected.connect(_on_item_selected)
	if not option_labels.is_empty():
		set_options(option_labels, [])


## Replaces the items. values[i] belongs to labels[i]; pass [] to use indices as values.
func set_options(labels: PackedStringArray, values: Array) -> void:
	if not values.is_empty() and values.size() != labels.size():
		push_error("OptionSettingRow '%s': %d labels but %d values." % [name, labels.size(), values.size()])
		return
	_values = values.duplicate()
	_options.clear()
	for label: String in labels:
		_options.add_item(label)


func set_value(value: Variant) -> void:
	var index: int = int(value) if _values.is_empty() else _values.find(value)
	if index < 0 or index >= _options.item_count:
		push_warning("OptionSettingRow '%s': value %s is not one of the options." % [name, value])
		index = -1
	_options.select(index)


func set_disabled(disabled: bool) -> void:
	_options.disabled = disabled
	FocusUtils.set_focusable(_options, not disabled)


func _on_item_selected(index: int) -> void:
	_emit_value(index if _values.is_empty() else _values[index])
