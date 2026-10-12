class_name SettingRow
extends HBoxContainer
## One labelled setting bound to a GameSettings property by setting_key.
## Subclasses (inherited scenes) add the input control and convert its value.

signal value_changed(key: StringName, value: Variant)

## Name of the GameSettings property this row edits.
@export var setting_key: StringName = &""
@export var label_text: String = ""

@onready var _label: Label = %Label


func _ready() -> void:
	_label.text = label_text


## Shows value without emitting value_changed. Override in subclasses.
func set_value(_value: Variant) -> void:
	push_error("SettingRow '%s' does not implement set_value()." % name)


## Override in subclasses.
func set_disabled(_disabled: bool) -> void:
	push_error("SettingRow '%s' does not implement set_disabled()." % name)


func _emit_value(value: Variant) -> void:
	value_changed.emit(setting_key, value)
