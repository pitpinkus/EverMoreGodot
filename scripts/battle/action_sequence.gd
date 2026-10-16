class_name ActionSequence
extends RefCounted
## The order in which an action or a status tick unfolds on screen: announce, VFX up to
## the impact, apply the effects, then report events (floating text) and messages
## (battle log). Owned by BattleManager, which relays its signals. Works without an
## ActionVfxPlayer (headless): the VFX step is skipped.

signal events_recorded(events: Array[BattleEvent])
signal messages_logged(messages: Array[String])

var _resolver: ActionResolver
var _vfx_player: ActionVfxPlayer


func _init(resolver: ActionResolver, vfx_player: ActionVfxPlayer) -> void:
	_resolver = resolver
	_vfx_player = vfx_player


## user uses action on target. Await it. The returned context tells e.g. whether the
## target was captured.
func run_action(user: BattleMonster, action: ActionData, target: BattleMonster, is_wild: bool) -> EffectContext:
	var ctx: EffectContext = _resolver.begin(user, action, target, is_wild)
	messages_logged.emit(ctx.take_messages())
	if _vfx_player != null:
		await _vfx_player.play_action(user, target, action, ctx.hit)
	_resolver.finish(ctx)
	_report(ctx)
	return ctx


## Start of unit's turn: each status plays its tick VFX and runs its effects, then the
## statuses count down. True if unit had any status (something was shown).
func run_status_ticks(unit: BattleMonster) -> bool:
	var statuses: Array[StatusEffectData] = unit.get_status_holder().get_statuses()
	for status: StatusEffectData in statuses:
		if not unit.is_alive():
			break
		if _vfx_player != null:
			_vfx_player.play_at(unit, status.tick_vfx)
		_report(_resolver.tick_status(unit, status))
	_resolver.end_status_ticks(unit)
	return not statuses.is_empty()


func _report(ctx: EffectContext) -> void:
	events_recorded.emit(ctx.events)
	messages_logged.emit(ctx.take_messages())
