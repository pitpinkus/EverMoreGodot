class_name ElementBadge
extends PanelContainer
## Small coloured tag naming a BattleTypes.Element (prefabs/ui/element_badge.tscn).
## Its theme type variation is VARIATION_PREFIX + the element name (ElementBadgeFire,
## ...), so the colours live in the theme. Hidden for ChoiceEntry.NO_ELEMENT.
## set_element may be called before the badge is in the tree; it is applied in _ready.

const VARIATION_PREFIX: String = "ElementBadge"

var _element: int = ChoiceEntry.NO_ELEMENT

@onready var _label: Label = %Label


func _ready() -> void:
	_apply()


## Shows element (a BattleTypes.Element), or hides the badge for ChoiceEntry.NO_ELEMENT.
func set_element(element: int) -> void:
	_element = element
	if is_node_ready():
		_apply()


func _apply() -> void:
	visible = _element != ChoiceEntry.NO_ELEMENT
	if not visible:
		return
	var element_name: String = BattleTypes.get_element_name(_element as BattleTypes.Element)
	_label.text = element_name
	theme_type_variation = StringName(VARIATION_PREFIX + element_name)
