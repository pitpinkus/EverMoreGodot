class_name HealEffect
extends BattleEffect
## Restores HP. Works outside battle unless it scales with the user's level.

enum Mode {
	## amount HP.
	FLAT,
	## amount * max HP (1.0 = full heal).
	PERCENT_MAX_HP,
	## BattleFormulas.heal_by_power(user level, amount); battle only.
	POWER_SCALED,
}

const MIN_HEAL: int = 1

@export var mode: Mode = Mode.FLAT
@export_range(0.0, 999.0, 0.01) var amount: float = 20.0


func can_apply(ctx: EffectContext) -> bool:
	if mode == Mode.POWER_SCALED and not ctx.in_battle:
		return false
	var monster: MonsterInstance = _get_instance(ctx)
	return monster != null and not monster.is_fainted() and monster.current_hp < monster.get_max_hp()


func works_outside_battle() -> bool:
	return mode != Mode.POWER_SCALED


func _apply(ctx: EffectContext) -> void:
	var monster: MonsterInstance = _get_instance(ctx)
	var healed: int = 0
	match mode:
		Mode.FLAT:
			healed = roundi(amount)
		Mode.PERCENT_MAX_HP:
			healed = maxi(MIN_HEAL, floori(monster.get_max_hp() * amount))
		Mode.POWER_SCALED:
			healed = BattleFormulas.heal_by_power(ctx.user_instance.level, roundi(amount))
	ctx.restore_hp(target_self, healed)
