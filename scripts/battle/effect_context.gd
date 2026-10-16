class_name EffectContext
extends RefCounted
## Everything a BattleEffect needs to run: who uses what on whom, the rules and the
## random source. Effects write their results here (messages, events, hit, captured).
## The same context type is used in battle (units set) and in the overworld (units
## null, only monster instances set).

const DAMAGE_FORMAT: String = "%s: -%d HP"
const HEAL_FORMAT: String = "%s: +%d HP"

## The units involved; null outside battle.
var user: BattleMonster
var target: BattleMonster
## The monsters involved. Always set (in battle they are user.instance / target.instance).
var user_instance: MonsterInstance
var target_instance: MonsterInstance
var action: ActionData
var rules: BattleRules
var rng: RandomNumberGenerator
## The opposing side is wild (can be captured, can be fled from).
var is_wild: bool = false
var in_battle: bool = false
## Player-facing lines produced while resolving, in order.
var messages: Array[String] = []
## What happened to units, for floating text. Battle only (see record).
var events: Array[BattleEvent] = []
## The status whose tick is running (its damage shows in the status colour); null for actions.
var source_status: StatusEffectData
## Set by CaptureEffect when the target was caught.
var captured: bool = false
## Result of the accuracy roll (true when the action does not roll accuracy).
var hit: bool = true


static func for_battle(battle_user: BattleMonster, battle_target: BattleMonster, used: ActionData,
		battle_rules: BattleRules, random: RandomNumberGenerator, wild: bool) -> EffectContext:
	var ctx: EffectContext = EffectContext.new()
	ctx.user = battle_user
	ctx.target = battle_target
	ctx.user_instance = battle_user.instance if battle_user != null else null
	ctx.target_instance = battle_target.instance if battle_target != null else null
	ctx.action = used
	ctx.rules = battle_rules
	ctx.rng = random
	ctx.is_wild = wild
	ctx.in_battle = true
	return ctx


## Outside battle the chosen monster is both user and target, so self-targeted
## effects on items affect the monster the player picked.
static func for_overworld(monster: MonsterInstance, used: ActionData, battle_rules: BattleRules) -> EffectContext:
	var ctx: EffectContext = EffectContext.new()
	ctx.user_instance = monster
	ctx.target_instance = monster
	ctx.action = used
	ctx.rules = battle_rules
	ctx.rng = RandomNumberGenerator.new()
	return ctx


func log_message(text: String) -> void:
	messages.append(text)


## Adds event; ignored outside battle or without a unit.
func record(event: BattleEvent) -> void:
	if in_battle and event.target != null:
		events.append(event)


## The messages logged so far; the context starts a fresh list.
func take_messages() -> Array[String]:
	var taken: Array[String] = messages
	messages = []
	return taken


## True with probability percent / 100.
func roll_percent(percent: float) -> bool:
	if percent >= BattleFormulas.PERCENT:
		return true
	return rng.randf() * BattleFormulas.PERCENT < percent


## The user when self_target, else the target. Null outside battle.
func get_unit(self_target: bool) -> BattleMonster:
	return user if self_target else target


func get_instance(self_target: bool) -> MonsterInstance:
	return user_instance if self_target else target_instance


## Damages the user (self_target) or target, logs and records the HP lost. Returns HP actually lost.
func deal_damage(self_target: bool, amount: int, crit: bool = false) -> int:
	var monster: MonsterInstance = get_instance(self_target)
	var lost: int = monster.apply_damage(amount)
	log_message(DAMAGE_FORMAT % [monster.get_display_name(), lost])
	record(BattleEvent.damage(get_unit(self_target), lost, crit, source_status))
	return lost


## Heals the user (self_target) or target, logs and records the HP gained. Returns HP actually gained.
func restore_hp(self_target: bool, amount: int) -> int:
	var monster: MonsterInstance = get_instance(self_target)
	var gained: int = monster.heal(amount)
	log_message(HEAL_FORMAT % [monster.get_display_name(), gained])
	record(BattleEvent.heal(get_unit(self_target), gained))
	return gained
