class_name TurnSlot
extends PanelContainer
## One unit on the turn timeline: its %Portrait (MonsterPortrait) and name. The panel's
## theme variation shows the unit's side and whether it is acting now. Display only.

const VARIATIONS: Dictionary[BattleTypes.Side, StringName] = {
	BattleTypes.Side.PLAYER: &"TurnSlotPlayer",
	BattleTypes.Side.ENEMY: &"TurnSlotEnemy",
}
const CURRENT_VARIATIONS: Dictionary[BattleTypes.Side, StringName] = {
	BattleTypes.Side.PLAYER: &"TurnSlotPlayerCurrent",
	BattleTypes.Side.ENEMY: &"TurnSlotEnemyCurrent",
}

@onready var _portrait: MonsterPortrait = %Portrait
@onready var _name_label: Label = %NameLabel


## Shows unit; is_current marks the unit whose turn it is.
func set_unit(unit: BattleMonster, is_current: bool) -> void:
	var display_name: String = unit.instance.get_display_name()
	_portrait.show_species(unit.instance.species, display_name)
	_name_label.text = display_name
	theme_type_variation = CURRENT_VARIATIONS[unit.side] if is_current else VARIATIONS[unit.side]
