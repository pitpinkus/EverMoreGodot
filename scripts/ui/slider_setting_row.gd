class_name SliderSettingRow
extends SettingRow
## Setting row edited with an HSlider (float values).

const PERCENT_FACTOR: float = 100.0

@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.05
## Shows 0..1 values as 0%..100% instead of the raw number.
@export var display_as_percent: bool = false

@onready var _slider: HSlider = %Slider
@onready var _value_label: Label = %ValueLabel


func _ready() -> void:
	super()
	_slider.min_value = min_value
	_slider.max_value = max_value
	_slider.step = step
	_slider.value_changed.connect(_on_slider_value_changed)
	_update_value_label()


func set_value(value: Variant) -> void:
	_slider.set_value_no_signal(float(value))
	_update_value_label()


func set_disabled(disabled: bool) -> void:
	_slider.editable = not disabled
	FocusUtils.set_focusable(_slider, not disabled)


func _on_slider_value_changed(value: float) -> void:
	_update_value_label()
	_emit_value(value)


func _update_value_label() -> void:
	if display_as_percent:
		_value_label.text = "%d%%" % roundi(_slider.value * PERCENT_FACTOR)
	else:
		_value_label.text = str(snappedf(_slider.value, step))
