class_name DamageEffect
extends BattleEffect
## Attack damage from the user's Attack against the target's Defense, with crits
## and the ranged multiplier of indirect moves.

const CRIT_MESSAGE: String = "A critical hit!"

@export_range(1, 300, 1) var power: int = 40


func can_apply(ctx: EffectContext) -> bool:
	return _is_unit_alive(ctx) and ctx.user != null


func _apply(ctx: EffectContext) -> void:
	var attacker: BattleMonster = ctx.user
	var defender: BattleMonster = _get_unit(ctx)
	var crit: bool = ctx.roll_percent(attacker.get_stat(BattleTypes.Stat.CRIT_RATE))
	var ranged_mult: float = 1.0
	var move: MoveData = ctx.action as MoveData
	if move != null and not move.is_direct:
		ranged_mult = move.indirect_damage_multiplier
	var amount: int = BattleFormulas.damage(
		attacker.instance.level,
		power,
		attacker.get_stat(BattleTypes.Stat.ATTACK),
		defender.get_stat(BattleTypes.Stat.DEFENSE),
		crit,
		attacker.get_stat(BattleTypes.Stat.CRIT_MOD),
		ranged_mult,
		BattleFormulas.roll_variance(ctx.rng, ctx.rules))
	if crit:
		ctx.log_message(CRIT_MESSAGE)
	ctx.deal_damage(target_self, amount, crit)
