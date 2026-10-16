class_name EntryRowContent
extends HBoxContainer
## One list line (prefabs/ui/entry_row_content.tscn): [%ElementBadge][%NameLabel
## (expands, clips)][%DetailLabel]. Used inside ChoiceRow and for the move rows of the
## MonsterSummaryPanel. Unavailable entries grey the name via its theme variation.

const NAME_VARIATION: StringName = &"ListRowNameLabel"
const NAME_UNAVAILABLE_VARIATION: StringName = &"ListRowNameLabelUnavailable"

@onready var _element_badge: ElementBadge = %ElementBadge
@onready var _name_label: Label = %NameLabel
@onready var _detail_label: Label = %DetailLabel


## element is a BattleTypes.Element or ChoiceEntry.NO_ELEMENT (no badge).
func set_content(text: String, detail: String, element: int, enabled: bool) -> void:
	_name_label.text = text
	_name_label.theme_type_variation = NAME_VARIATION if enabled else NAME_UNAVAILABLE_VARIATION
	_detail_label.text = detail
	_element_badge.set_element(element)
