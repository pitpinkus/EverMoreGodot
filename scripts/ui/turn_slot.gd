class_name TurnSlot
extends PanelContainer
## One unit on the turn timeline: species icon (or the coloured first letter of its name
## when the species has none) and name. The panel's theme variation shows the unit's
## side and whether it is acting now. Display only.

const VARIATIONS: Dictionary[BattleTypes.Side, StringName] = {
	BattleTypes.Side.PLAYER: &"TurnSlotPlayer",
	BattleTypes.Side.ENEMY: &"TurnSlotEnemy",
}
const CURRENT_VARIATIONS: Dictionary[BattleTypes.Side, StringName] = {
	BattleTypes.Side.PLAYER: &"TurnSlotPlayerCurrent",
	BattleTypes.Side.ENEMY: &"TurnSlotEnemyCurrent",
}

@onready var _icon: TextureRect = %Icon
@onready var _initial: Label = %Initial
@onready var _name_label: Label = %NameLabel


## Shows unit; is_current marks the unit whose turn it is.
func set_unit(unit: BattleMonster, is_current: bool) -> void:
	var display_name: String = unit.instance.get_display_name()
	var icon: Texture2D = unit.instance.species.icon
	_icon.texture = icon
	_icon.visible = icon != null
	_initial.visible = icon == null
	_initial.text = display_name.left(1).to_upper()
	_name_label.text = display_name
	theme_type_variation = CURRENT_VARIATIONS[unit.side] if is_current else VARIATIONS[unit.side]
