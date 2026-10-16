class_name ActionResolver
extends RefCounted
## Runs moves, items and status ticks through the shared effect pipeline and returns
## the resulting EffectContext (messages, events, hit, captured). Using an action is
## split in begin (announce + accuracy roll) and finish (effects) so the VFX can play
## in between. Knows nothing about turns.

const USED_FORMAT: String = "%s used %s!"
const MISSED_FORMAT: String = "%s missed!"
const STATUS_FORMAT: String = "%s suffers from %s."

var _rules: BattleRules
var _rng: RandomNumberGenerator


func _init(rules: BattleRules, rng: RandomNumberGenerator) -> void:
	_rules = rules
	_rng = rng


## A probe context for checks (can_use_on) that rolls nothing.
func make_context(user: BattleMonster, target: BattleMonster, action: ActionData, is_wild: bool) -> EffectContext:
	return EffectContext.for_battle(user, target, action, _rules, _rng, is_wild)


## user starts using action on target: announces it and makes the one accuracy roll
## (ctx.hit; a miss is recorded on the target). Nothing is applied until finish.
func begin(user: BattleMonster, action: ActionData, target: BattleMonster, is_wild: bool) -> EffectContext:
	var ctx: EffectContext = make_context(user, target, action, is_wild)
	ctx.log_message(USED_FORMAT % [user.instance.get_display_name(), action.display_name])
	if action.rolls_accuracy() and target != user:
		var chance: float = BattleFormulas.hit_chance(action.get_accuracy(), target.get_stat(BattleTypes.Stat.DODGE), _rules)
		ctx.hit = ctx.roll_percent(chance)
	if not ctx.hit:
		ctx.record(BattleEvent.miss(target))
	return ctx


## Applies every effect of the begun action that applies; a miss applies none.
func finish(ctx: EffectContext) -> void:
	if ctx.hit:
		ctx.action.apply_effects(ctx)
	else:
		ctx.log_message(MISSED_FORMAT % ctx.user.instance.get_display_name())


## Runs status's turn-start effects on unit (its damage is tagged with status).
func tick_status(unit: BattleMonster, status: StatusEffectData) -> EffectContext:
	var ctx: EffectContext = make_context(unit, unit, null, false)
	ctx.source_status = status
	ctx.log_message(STATUS_FORMAT % [unit.instance.get_display_name(), status.display_name])
	BattleEffect.apply_all(status.turn_start_effects, ctx)
	return ctx


## After all of unit's statuses ticked: counts them down and drops the ones that ran out.
func end_status_ticks(unit: BattleMonster) -> void:
	unit.get_status_holder().tick()
