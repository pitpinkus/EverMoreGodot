class_name StatStageEffect
extends BattleEffect
## Raises or lowers one stat by some stages for a number of the owner's turns.

const ROSE_FORMAT: String = "%s's %s rose!"
const FELL_FORMAT: String = "%s's %s fell!"

## Any stat but HP (HP is never staged).
@export var stat: BattleTypes.Stat = BattleTypes.Stat.ATTACK
@export_range(-6, 6, 1) var stages: int = 1
@export_range(1, 20, 1, "suffix:turns") var duration: int = 3


func can_apply(ctx: EffectContext) -> bool:
	return _is_unit_alive(ctx) and stat != BattleTypes.Stat.HP and stages != 0


func _apply(ctx: EffectContext) -> void:
	var unit: BattleMonster = _get_unit(ctx)
	unit.get_stat_stages().add(stat, stages, duration)
	ctx.record(BattleEvent.stat_stage(unit, stat, stages))
	var text_format: String = ROSE_FORMAT if stages > 0 else FELL_FORMAT
	ctx.log_message(text_format % [unit.instance.get_display_name(), BattleTypes.get_stat_name(stat)])
