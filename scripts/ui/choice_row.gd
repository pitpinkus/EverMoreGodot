class_name ChoiceRow
extends Button
## One row of a ChoiceListPanel. Shows a ChoiceEntry in its %Content (EntryRowContent:
## badge, name, detail); the Button's own text stays empty. Unavailable rows stay
## focusable (so their reason can be shown) and use the ListRowButtonUnavailable theme
## variation.

const AVAILABLE_VARIATION: StringName = &"ListRowButton"
const UNAVAILABLE_VARIATION: StringName = &"ListRowButtonUnavailable"

var entry: ChoiceEntry

@onready var _content: EntryRowContent = %Content


func set_entry(choice: ChoiceEntry) -> void:
	entry = choice
	_content.set_content(choice.text, choice.detail, choice.element, choice.enabled)
	theme_type_variation = AVAILABLE_VARIATION if choice.enabled else UNAVAILABLE_VARIATION
