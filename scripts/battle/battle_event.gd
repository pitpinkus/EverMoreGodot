class_name BattleEvent
extends RefCounted
## One visible result of an action or status tick on a unit (damage, heal, miss, stat
## change, status gained or lost). Recorded on the EffectContext and shown as floating
## text by FloatingTextSpawner; the battle log keeps using the context's messages.

enum Kind { DAMAGE, HEAL, MISS, STAT_STAGE, STATUS_APPLIED, STATUS_CURED }

var kind: Kind = Kind.DAMAGE
var target: BattleMonster
## HP lost (DAMAGE) or gained (HEAL).
var amount: int = 0
var crit: bool = false
## STAT_STAGE: the stat and how many stages it moved (negative = lowered).
var stat: BattleTypes.Stat = BattleTypes.Stat.HP
var stages: int = 0
## STATUS_APPLIED / STATUS_CURED: the status. DAMAGE: the status that caused it (Burn
## tick), null for attacks.
var status: StatusEffectData


static func damage(on: BattleMonster, lost: int, is_crit: bool, source_status: StatusEffectData) -> BattleEvent:
	var event: BattleEvent = _make(Kind.DAMAGE, on)
	event.amount = lost
	event.crit = is_crit
	event.status = source_status
	return event


static func heal(on: BattleMonster, gained: int) -> BattleEvent:
	var event: BattleEvent = _make(Kind.HEAL, on)
	event.amount = gained
	return event


static func miss(on: BattleMonster) -> BattleEvent:
	return _make(Kind.MISS, on)


static func stat_stage(on: BattleMonster, changed_stat: BattleTypes.Stat, stage_change: int) -> BattleEvent:
	var event: BattleEvent = _make(Kind.STAT_STAGE, on)
	event.stat = changed_stat
	event.stages = stage_change
	return event


static func status_applied(on: BattleMonster, applied: StatusEffectData) -> BattleEvent:
	var event: BattleEvent = _make(Kind.STATUS_APPLIED, on)
	event.status = applied
	return event


static func status_cured(on: BattleMonster, cured: StatusEffectData) -> BattleEvent:
	var event: BattleEvent = _make(Kind.STATUS_CURED, on)
	event.status = cured
	return event


static func _make(event_kind: Kind, on: BattleMonster) -> BattleEvent:
	var event: BattleEvent = BattleEvent.new()
	event.kind = event_kind
	event.target = on
	return event
