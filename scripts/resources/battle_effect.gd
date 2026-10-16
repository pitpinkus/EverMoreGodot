@abstract
class_name BattleEffect
extends Resource
## One composable piece of what a move, item or status does (damage, heal, buff, ...).
## Listed on ActionData.effects and StatusEffectData.turn_start_effects; all behaviour
## lives in subclasses, data in .tres. The accuracy roll happens once per action
## (ActionResolver), not here; chance is this effect's own extra roll.

## Affect the user instead of the target.
@export var target_self: bool = false
## Chance in percent that this effect happens once the action hit.
@export_range(0, 100, 1, "suffix:%") var chance: int = 100


## Applies every effect in effects that can still do something, in order.
static func apply_all(effects: Array[BattleEffect], ctx: EffectContext) -> void:
	for effect: BattleEffect in effects:
		if effect != null and effect.can_apply(ctx):
			effect.apply(ctx)


## True if at least one effect in effects would do something in ctx.
static func any_can_apply(effects: Array[BattleEffect], ctx: EffectContext) -> bool:
	return effects.any(func(effect: BattleEffect) -> bool: return effect != null and effect.can_apply(ctx))


## Rolls chance, then runs the effect.
func apply(ctx: EffectContext) -> void:
	if ctx.roll_percent(chance):
		_apply(ctx)


## False if the effect would do nothing (e.g. healing a monster at full HP).
func can_apply(_ctx: EffectContext) -> bool:
	return true


## True if the effect also works on a MonsterInstance outside battle (no units).
func works_outside_battle() -> bool:
	return false


@abstract func _apply(ctx: EffectContext) -> void


## The affected battle unit, or null outside battle.
func _get_unit(ctx: EffectContext) -> BattleMonster:
	return ctx.get_unit(target_self)


func _get_instance(ctx: EffectContext) -> MonsterInstance:
	return ctx.get_instance(target_self)


## True in battle while the affected unit is still standing.
func _is_unit_alive(ctx: EffectContext) -> bool:
	var unit: BattleMonster = _get_unit(ctx)
	return ctx.in_battle and unit != null and unit.is_alive()
