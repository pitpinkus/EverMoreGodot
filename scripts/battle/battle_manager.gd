class_name BattleManager
extends Node
## Runs one battle: turns come from a CTB timeline (TurnScheduler), so faster units act
## more often and Speed changes shift the order at once. Each turn the
## unit's controller returns decisions (move, action, flee, end turn) which are
## validated and executed here, the only place that changes the battle. A unit may
## walk within its step budget and act once; its turn ends on END_TURN, when it has
## acted and has almost no steps left, or when the battle is over.
## Read-only queries are for controllers and UI: get_roster() for who is in the battle,
## get_targeting() for who an action can be used on, get_navigator() for walk paths and
## reach, plus the turn state below.

signal turn_started(unit: BattleMonster)
signal turn_ended(unit: BattleMonster)
signal message_logged(text: String)
signal unit_fainted(unit: BattleMonster)
signal battle_ended(result: BattleResult)
## Visible results of an action or status tick, for floating text.
signal events_recorded(events: Array[BattleEvent])
## The upcoming turn order may have changed; ask predict_turns. Emitted once per frame at most.
signal timeline_changed

const FAINTED_FORMAT: String = "%s fainted!"
const FLED_MESSAGE: String = "Got away safely!"
const FLEE_FAILED_MESSAGE: String = "Couldn't get away!"

@export var player_controller: BattleController
@export var ai_controller: BattleController
## Plays action and status VFX. Null = no VFX (e.g. headless tests).
@export var vfx_player: ActionVfxPlayer
## Paths for MOVE decisions; rebaked around the other living units each turn.
@export var navigator: BattleNavigator

var _setup: BattleSetup
var _rules: BattleRules
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _resolver: ActionResolver
var _sequence: ActionSequence
var _scheduler: TurnScheduler
## The unit whose turn it is, or null between turns.
var _current: BattleMonster
var _timeline_change_queued: bool = false
var _roster: BattleRoster
var _targeting: BattleTargeting
var _acted: Dictionary[BattleMonster, bool] = {}
var _result: BattleResult
## Units that fainted since the last _log_all; announced after the messages that caused it.
var _new_faints: Array[BattleMonster] = []
## A unit fainted since the navmesh was last baked, so it no longer blocks paths.
var _navigation_dirty: bool = false


## Starts the battle loop with units already placed in the scene. Ends with battle_ended.
func start(setup: BattleSetup, player_units: Array[BattleMonster], enemy_units: Array[BattleMonster]) -> void:
	if player_controller == null or ai_controller == null or navigator == null:
		push_error("BattleManager '%s' needs both controllers and the navigator assigned." % name)
		return
	_setup = setup
	_rules = DataRegistry.get_rules()
	_resolver = ActionResolver.new(_rules, _rng)
	_sequence = ActionSequence.new(_resolver, vfx_player)
	_sequence.events_recorded.connect(events_recorded.emit)
	_sequence.messages_logged.connect(_log_all)
	_roster = BattleRoster.new(player_units, enemy_units)
	_targeting = BattleTargeting.new(_roster, _resolver, setup.is_wild)
	_result = null
	_scheduler = TurnScheduler.new(_rules, _rng.randi())
	_scheduler.order_changed.connect(_queue_timeline_changed)
	for unit: BattleMonster in _roster.get_all_units():
		unit.fainted.connect(_on_unit_fainted)
		if unit.is_alive():
			_scheduler.add(unit)
	_run_battle()


func get_roster() -> BattleRoster:
	return _roster


func get_targeting() -> BattleTargeting:
	return _targeting


func get_navigator() -> BattleNavigator:
	return navigator


func has_acted(unit: BattleMonster) -> bool:
	return _acted.get(unit, false)


func steps_left(unit: BattleMonster) -> float:
	return unit.get_step_budget().get_remaining()


func can_flee() -> bool:
	return _setup.is_wild


func get_rules() -> BattleRules:
	return _rules


## The unit whose turn is running, or null between turns.
func get_current_unit() -> BattleMonster:
	return _current


## The next count turns as things stand, the unit acting now first.
func predict_turns(count: int) -> Array[BattleMonster]:
	return _scheduler.predict(count, _current)


func _run_battle() -> void:
	_check_battle_over()
	while _result == null:
		var unit: BattleMonster = _scheduler.pop_next()
		if unit == null:
			push_error("BattleManager: the turn timeline is empty but the battle is not over.")
			break
		_current = unit
		await _run_turn(unit)
		_current = null
		if unit.is_alive():
			_scheduler.reschedule(unit)
		_queue_timeline_changed()
	battle_ended.emit(_result)


func _run_turn(unit: BattleMonster) -> void:
	_acted[unit] = false
	unit.begin_turn()
	turn_started.emit(unit)
	_queue_timeline_changed()
	if _sequence.run_status_ticks(unit):
		await _wait_action_delay()
	_check_battle_over()
	var controller: BattleController = player_controller if unit.side == BattleTypes.Side.PLAYER else ai_controller
	if _result == null and unit.is_alive():
		await _prepare_navigation(unit)
		controller.begin_turn(unit, self)
	while _result == null and unit.is_alive():
		if _navigation_dirty:
			await _prepare_navigation(unit)
		var decision: BattleDecision = await controller.decide(unit, self)
		if decision == null or decision.kind == BattleDecision.Kind.END_TURN:
			break
		if not await _execute(unit, decision):
			push_warning("BattleManager: invalid decision %s for '%s'; ending its turn." \
					% [BattleDecision.Kind.find_key(decision.kind), unit.instance.get_display_name()])
			break
		_check_battle_over()
		if has_acted(unit) and steps_left(unit) < _rules.min_move_distance:
			break
	turn_ended.emit(unit)


## Validates and runs decision. False if it was not allowed.
func _execute(unit: BattleMonster, decision: BattleDecision) -> bool:
	match decision.kind:
		BattleDecision.Kind.MOVE:
			var path: PackedVector3Array = navigator.get_path_within(unit.global_position, decision.point,
					steps_left(unit))
			if BattleNavigator.path_length(path) < _rules.min_move_distance:
				return false
			await unit.move_along(path)
			return true
		BattleDecision.Kind.ACTION:
			if not _is_action_allowed(unit, decision.action, decision.target):
				return false
			await _execute_action(unit, decision.action, decision.target)
			return true
		BattleDecision.Kind.FLEE:
			if not can_flee():
				return false
			await _try_flee(unit)
			return true
	return false


## Bakes the walkable area around every living unit except unit. Await it.
func _prepare_navigation(unit: BattleMonster) -> void:
	_navigation_dirty = false
	await navigator.prepare_turn(unit, _roster.get_blockers(unit))


func _is_action_allowed(unit: BattleMonster, action: ActionData, target: BattleMonster) -> bool:
	return not has_acted(unit) and _targeting.is_action_allowed(unit, action, target)


func _execute_action(unit: BattleMonster, action: ActionData, target: BattleMonster) -> void:
	_acted[unit] = true
	if target != unit:
		unit.face_towards(target.global_position)
	var ctx: EffectContext = await _sequence.run_action(unit, action, target, _setup.is_wild)
	var item: ItemData = action as ItemData
	if item != null and item.consumed_on_use:
		PlayerProfile.inventory.remove(item)
	if ctx.captured:
		_scheduler.remove(target)
		_queue_timeline_changed()
		_finish(BattleTypes.Outcome.CAPTURED, target.instance)
	await _wait_action_delay()


func _try_flee(unit: BattleMonster) -> void:
	_acted[unit] = true
	if _rng.randf() < _rules.flee_chance:
		message_logged.emit(FLED_MESSAGE)
		_finish(BattleTypes.Outcome.FLED)
	else:
		message_logged.emit(FLEE_FAILED_MESSAGE)
	await _wait_action_delay()


## Ends the battle once one side has no unit left standing.
func _check_battle_over() -> void:
	if _result != null:
		return
	if _roster.is_defeated(BattleTypes.Side.ENEMY):
		_finish(BattleTypes.Outcome.WON)
	elif _roster.is_defeated(BattleTypes.Side.PLAYER):
		_finish(BattleTypes.Outcome.LOST)


func _finish(outcome: BattleTypes.Outcome, captured: MonsterInstance = null) -> void:
	if _result != null:
		return
	_result = BattleResult.new()
	_result.outcome = outcome
	_result.captured = captured
	_result.encounter_id = _setup.encounter_id


## Logs messages, then announces and animates the faints they caused.
func _log_all(messages: Array[String]) -> void:
	for text: String in messages:
		message_logged.emit(text)
	for unit: BattleMonster in _new_faints:
		message_logged.emit(FAINTED_FORMAT % unit.instance.get_display_name())
		unit_fainted.emit(unit)
		unit.play_faint()
	_new_faints.clear()


func _wait_action_delay() -> void:
	await get_tree().create_timer(_rules.action_delay, false).timeout


## Coalesces timeline changes into one timeline_changed at the end of the frame.
func _queue_timeline_changed() -> void:
	if _timeline_change_queued:
		return
	_timeline_change_queued = true
	_emit_timeline_changed.call_deferred()


func _emit_timeline_changed() -> void:
	_timeline_change_queued = false
	timeline_changed.emit()


func _on_unit_fainted(unit: BattleMonster) -> void:
	_new_faints.append(unit)
	_navigation_dirty = true
	_scheduler.remove(unit)
	_queue_timeline_changed()
