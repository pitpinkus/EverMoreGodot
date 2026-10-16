class_name BattleTargeting
extends RefCounted
## Read-only rules for who an action can be used on: target side, range, whether it
## would do something, and whether an item is usable. Owned by BattleManager.

var _roster: BattleRoster
var _resolver: ActionResolver
var _is_wild: bool


func _init(roster: BattleRoster, resolver: ActionResolver, is_wild: bool) -> void:
	_roster = roster
	_resolver = resolver
	_is_wild = is_wild


## Units action can be used on right now: right side, in range and where it would do something.
func get_valid_targets(unit: BattleMonster, action: ActionData) -> Array[BattleMonster]:
	var candidates: Array[BattleMonster] = []
	match action.target_kind:
		BattleTypes.TargetKind.SELF:
			candidates = [unit]
		BattleTypes.TargetKind.ENEMY:
			candidates = _roster.get_opponents(unit)
		BattleTypes.TargetKind.ALLY:
			candidates = _roster.get_allies(unit)
	var valid: Array[BattleMonster] = []
	for target: BattleMonster in candidates:
		var probe: EffectContext = _resolver.make_context(unit, target, action, _is_wild)
		if is_in_range(unit, target, action) and action.can_use_on(probe):
			valid.append(target)
	return valid


func is_in_range(unit: BattleMonster, target: BattleMonster, action: ActionData) -> bool:
	return unit == target \
			or BattleFormulas.flat_distance(unit.global_position, target.global_position) <= action.max_range


## Items the player can use in battle right now (held and battle-usable).
func can_use_item(unit: BattleMonster, item: ItemData) -> bool:
	return unit.side == BattleTypes.Side.PLAYER \
			and item.is_usable_in(ItemData.UseContext.BATTLE) \
			and PlayerProfile.inventory.get_count(item) > 0


## True if unit may use action on target: a move it knows or a usable item, on a valid target.
## Whether unit has already acted this turn is the BattleManager's check.
func is_action_allowed(unit: BattleMonster, action: ActionData, target: BattleMonster) -> bool:
	if action == null or target == null:
		return false
	if action is MoveData and not unit.instance.moves.has(action):
		return false
	if action is ItemData and not can_use_item(unit, action as ItemData):
		return false
	return get_valid_targets(unit, action).has(target)
