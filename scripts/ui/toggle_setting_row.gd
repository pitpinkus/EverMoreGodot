class_name ToggleSettingRow
extends SettingRow
## Setting row edited with a CheckButton (bool values).

@onready var _toggle: CheckButton = %Toggle


func _ready() -> void:
	super()
	_toggle.toggled.connect(_emit_value)


func set_value(value: Variant) -> void:
	_toggle.set_pressed_no_signal(bool(value))


func set_disabled(disabled: bool) -> void:
	_toggle.disabled = disabled
	FocusUtils.set_focusable(_toggle, not disabled)
