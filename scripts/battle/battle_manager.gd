class_name BattleManager
extends Node
## Runs one battle: turns come from a CTB timeline (TurnScheduler), so faster units act
## more often and Speed changes shift the order at once. Each turn the
## unit's controller returns decisions (move, action, flee, end turn) which are
## validated and executed here, the only place that changes the battle. A unit may
## walk within its step budget and act once; its turn ends on END_TURN, when it has
## acted and has almost no steps left, or when the battle is over.
## Read-only queries (get_units, get_valid_targets, ...) are for controllers and UI.

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

var _setup: BattleSetup
var _rules: BattleRules
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _resolver: ActionResolver
var _sequence: ActionSequence
var _scheduler: TurnScheduler
## The unit whose turn it is, or null between turns.
var _current: BattleMonster
var _timeline_change_queued: bool = false
var _player_units: Array[BattleMonster] = []
var _enemy_units: Array[BattleMonster] = []
var _acted: Dictionary[BattleMonster, bool] = {}
var _result: BattleResult
## Units that fainted since the last _log_all; announced after the messages that caused it.
var _new_faints: Array[BattleMonster] = []


## Starts the battle loop with units already placed in the scene. Ends with battle_ended.
func start(setup: BattleSetup, player_units: Array[BattleMonster], enemy_units: Array[BattleMonster]) -> void:
	if player_controller == null or ai_controller == null:
		push_error("BattleManager '%s' needs both controllers assigned." % name)
		return
	_setup = setup
	_rules = DataRegistry.get_rules()
	_resolver = ActionResolver.new(_rules, _rng)
	_sequence = ActionSequence.new(_resolver, vfx_player)
	_sequence.events_recorded.connect(events_recorded.emit)
	_sequence.messages_logged.connect(_log_all)
	_player_units = player_units
	_enemy_units = enemy_units
	_result = null
	_scheduler = TurnScheduler.new(_rules, _rng.randi())
	_scheduler.order_changed.connect(_queue_timeline_changed)
	for unit: BattleMonster in _get_all_units():
		unit.fainted.connect(_on_unit_fainted)
		if unit.is_alive():
			_scheduler.add(unit)
	_run_battle()


## Living units of side, in their original order.
func get_units(side: BattleTypes.Side) -> Array[BattleMonster]:
	var all_units: Array[BattleMonster] = _player_units if side == BattleTypes.Side.PLAYER else _enemy_units
	var alive: Array[BattleMonster] = []
	alive.assign(all_units.filter(func(unit: BattleMonster) -> bool: return unit.is_alive()))
	return alive


func get_opponents(unit: BattleMonster) -> Array[BattleMonster]:
	return get_units(BattleTypes.Side.ENEMY if unit.side == BattleTypes.Side.PLAYER else BattleTypes.Side.PLAYER)


## Living units on unit's side, unit included.
func get_allies(unit: BattleMonster) -> Array[BattleMonster]:
	return get_units(unit.side)


## Units action can be used on right now: right side, in range and where it would do something.
func get_valid_targets(unit: BattleMonster, action: ActionData) -> Array[BattleMonster]:
	var candidates: Array[BattleMonster] = []
	match action.target_kind:
		BattleTypes.TargetKind.SELF:
			candidates = [unit]
		BattleTypes.TargetKind.ENEMY:
			candidates = get_opponents(unit)
		BattleTypes.TargetKind.ALLY:
			candidates = get_allies(unit)
	var valid: Array[BattleMonster] = []
	for target: BattleMonster in candidates:
		var probe: EffectContext = _resolver.make_context(unit, target, action, is_wild())
		if is_in_range(unit, target, action) and action.can_use_on(probe):
			valid.append(target)
	return valid


func is_in_range(unit: BattleMonster, target: BattleMonster, action: ActionData) -> bool:
	return unit == target or BattleFormulas.flat_distance(unit.global_position, target.global_position) <= action.max_range


func has_acted(unit: BattleMonster) -> bool:
	return _acted.get(unit, false)


func steps_left(unit: BattleMonster) -> float:
	return unit.get_step_budget().get_remaining()


func is_wild() -> bool:
	return _setup.is_wild


func can_flee() -> bool:
	return _setup.is_wild


## Items the player can use in battle right now (held and battle-usable).
func can_use_item(unit: BattleMonster, item: ItemData) -> bool:
	return unit.side == BattleTypes.Side.PLAYER \
			and item.is_usable_in(ItemData.UseContext.BATTLE) \
			and PlayerProfile.inventory.get_count(item) > 0


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
		controller.begin_turn(unit, self)
	while _result == null and unit.is_alive():
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
			if minf(steps_left(unit), BattleFormulas.flat_distance(unit.global_position, decision.point)) < _rules.min_move_distance:
				return false
			await unit.move_to(decision.point)
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


func _is_action_allowed(unit: BattleMonster, action: ActionData, target: BattleMonster) -> bool:
	if action == null or target == null or has_acted(unit):
		return false
	if action is MoveData and not unit.instance.moves.has(action):
		return false
	if action is ItemData and not can_use_item(unit, action as ItemData):
		return false
	return get_valid_targets(unit, action).has(target)


func _execute_action(unit: BattleMonster, action: ActionData, target: BattleMonster) -> void:
	_acted[unit] = true
	if target != unit:
		unit.face_towards(target.global_position)
	var ctx: EffectContext = await _sequence.run_action(unit, action, target, is_wild())
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
	if get_units(BattleTypes.Side.ENEMY).is_empty():
		_finish(BattleTypes.Outcome.WON)
	elif get_units(BattleTypes.Side.PLAYER).is_empty():
		_finish(BattleTypes.Outcome.LOST)


func _finish(outcome: BattleTypes.Outcome, captured: MonsterInstance = null) -> void:
	if _result != null:
		return
	_result = BattleResult.new()
	_result.outcome = outcome
	_result.captured = captured
	_result.encounter_id = _setup.encounter_id


## Every unit of both sides (player side first), fainted ones included.
func _get_all_units() -> Array[BattleMonster]:
	var units: Array[BattleMonster] = _player_units.duplicate()
	units.append_array(_enemy_units)
	return units


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
	_scheduler.remove(unit)
	_queue_timeline_changed()
