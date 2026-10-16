class_name FlatDamageEffect
extends BattleEffect
## Fixed damage that ignores stats and accuracy (e.g. Burn ticks).

## HP lost when percent_of_max_hp is 0.
@export_range(1, 999, 1) var amount: int = 1
## Fraction of the affected monster's max HP (e.g. 0.0625 = 1/16). Above 0 it replaces amount.
@export_range(0.0, 1.0, 0.0001) var percent_of_max_hp: float = 0.0


func can_apply(ctx: EffectContext) -> bool:
	return _is_unit_alive(ctx)


func _apply(ctx: EffectContext) -> void:
	var lost: int = amount
	if percent_of_max_hp > 0.0:
		lost = maxi(BattleFormulas.MIN_DAMAGE, floori(_get_instance(ctx).get_max_hp() * percent_of_max_hp))
	ctx.deal_damage(target_self, lost)
