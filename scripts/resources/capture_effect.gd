class_name CaptureEffect
extends BattleEffect
## Tries to catch a wild enemy. Chance = catch_rate * catch_bonus, lowered by the
## target's remaining HP (rules.capture_hp_weight). Sets ctx.captured on success.

const CAUGHT_FORMAT: String = "Gotcha! %s was caught!"
const ESCAPED_FORMAT: String = "%s broke free!"

## Multiplies the species' catch rate (better orbs have more).
@export_range(0.0, 10.0, 0.05) var catch_bonus: float = 1.0


func can_apply(ctx: EffectContext) -> bool:
	return ctx.is_wild \
			and _is_unit_alive(ctx) \
			and _get_unit(ctx).side == BattleTypes.Side.ENEMY \
			and not PlayerProfile.is_party_full()


func _apply(ctx: EffectContext) -> void:
	var monster: MonsterInstance = _get_instance(ctx)
	var capture_chance: float = monster.species.catch_rate * catch_bonus \
			* (1.0 - monster.get_hp_ratio() * ctx.rules.capture_hp_weight)
	if ctx.rng.randf() < capture_chance:
		ctx.captured = true
		ctx.log_message(CAUGHT_FORMAT % monster.get_display_name())
	else:
		ctx.log_message(ESCAPED_FORMAT % monster.get_display_name())
