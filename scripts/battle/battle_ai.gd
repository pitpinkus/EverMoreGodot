class_name BattleAI
extends BattleController
## Enemy controller. Each decision, in priority order:
## 1. Low on HP: use a heal move on itself (or the weakest ally in range).
## 2. Use the damaging move with the best power * accuracy on the weakest target in range.
## 3. Nothing to hit: raise its own stats with a self stat move (up to max_self_stage).
## 4. Not moved yet: walk towards the nearest opponent, stopping inside attack range.
## 5. End the turn.
## It can move and then attack (or attack and then move) in the same turn.

@export var profile: BattleAIProfile

var _has_moved: bool = false


func _ready() -> void:
	if profile == null:
		push_error("BattleAI '%s' has no BattleAIProfile assigned." % name)
		profile = BattleAIProfile.new()


func begin_turn(_unit: BattleMonster, _battle: BattleManager) -> void:
	_has_moved = false


func decide(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	await get_tree().create_timer(profile.think_delay, false).timeout
	if not battle.has_acted(unit):
		var decision: BattleDecision = _pick_action(unit, battle)
		if decision != null:
			return decision
	if not _has_moved:
		_has_moved = true
		var destination: Vector3 = _pick_destination(unit, battle)
		if BattleFormulas.flat_distance(unit.global_position, destination) >= battle.get_rules().min_move_distance:
			return BattleDecision.move_to(destination)
	return BattleDecision.end_turn()


## Steps 1-3 of the priority list; null if no action is worth using now.
func _pick_action(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	var moves: Array[MoveData] = unit.instance.moves
	if unit.instance.get_hp_ratio() < profile.heal_threshold:
		for move: MoveData in moves:
			if _is_heal(move):
				var heal_targets: Array[BattleMonster] = battle.get_valid_targets(unit, move)
				if not heal_targets.is_empty():
					return BattleDecision.use(move, unit if heal_targets.has(unit) else _weakest(heal_targets))
	var best_move: MoveData = null
	var best_score: float = 0.0
	for move: MoveData in moves:
		var score: float = _get_power(move) * move.get_accuracy()
		if score > best_score and not battle.get_valid_targets(unit, move).is_empty():
			best_move = move
			best_score = score
	if best_move != null:
		return BattleDecision.use(best_move, _weakest(battle.get_valid_targets(unit, best_move)))
	if profile.use_stat_moves:
		for move: MoveData in moves:
			if _raises_own_stat_below(move, unit, profile.max_self_stage) \
					and battle.get_valid_targets(unit, move).has(unit):
				return BattleDecision.use(move, unit)
	return null


## A point towards the nearest opponent, at max damaging range * range_margin from it.
func _pick_destination(unit: BattleMonster, battle: BattleManager) -> Vector3:
	var opponents: Array[BattleMonster] = battle.get_opponents(unit)
	if opponents.is_empty():
		return unit.global_position
	var nearest: BattleMonster = opponents[0]
	for opponent: BattleMonster in opponents:
		if BattleFormulas.flat_distance(unit.global_position, opponent.global_position) \
				< BattleFormulas.flat_distance(unit.global_position, nearest.global_position):
			nearest = opponent
	var attack_range: float = 0.0
	for move: MoveData in unit.instance.moves:
		if _get_power(move) > 0:
			attack_range = maxf(attack_range, move.max_range)
	var away: Vector3 = BattleFormulas.flat_offset(nearest.global_position, unit.global_position)
	var destination: Vector3 = nearest.global_position + away.normalized() * attack_range * profile.range_margin
	return unit.get_step_budget().clamp_destination(destination)


## Total DamageEffect power of move (0 = not a damaging move).
static func _get_power(move: MoveData) -> int:
	var power: int = 0
	for effect: BattleEffect in move.effects:
		if effect is DamageEffect and not effect.target_self:
			power += (effect as DamageEffect).power
	return power


static func _is_heal(move: MoveData) -> bool:
	return move.effects.any(func(effect: BattleEffect) -> bool: return effect is HealEffect)


## True if move raises a stat of its user that is still below max_stage.
static func _raises_own_stat_below(move: MoveData, unit: BattleMonster, max_stage: int) -> bool:
	for effect: BattleEffect in move.effects:
		var stage_effect: StatStageEffect = effect as StatStageEffect
		if stage_effect != null and stage_effect.target_self and stage_effect.stages > 0 \
				and unit.get_stat_stages().get_stage(stage_effect.stat) < max_stage:
			return true
	return false


## The target with the lowest current HP.
static func _weakest(targets: Array[BattleMonster]) -> BattleMonster:
	var weakest: BattleMonster = targets[0]
	for target: BattleMonster in targets:
		if target.instance.current_hp < weakest.instance.current_hp:
			weakest = target
	return weakest
