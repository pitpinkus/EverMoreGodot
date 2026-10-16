class_name ChoiceRow
extends Button
## One row of a ChoiceListPanel. Shows a ChoiceEntry: text on the button, detail in
## %DetailLabel. Unavailable rows stay focusable (so their reason can be shown) and
## use the ListRowButtonUnavailable theme variation.

const AVAILABLE_VARIATION: StringName = &"ListRowButton"
const UNAVAILABLE_VARIATION: StringName = &"ListRowButtonUnavailable"

var entry: ChoiceEntry

@onready var _detail_label: Label = %DetailLabel


func set_entry(choice: ChoiceEntry) -> void:
	entry = choice
	text = choice.text
	_detail_label.text = choice.detail
	theme_type_variation = AVAILABLE_VARIATION if choice.enabled else UNAVAILABLE_VARIATION
