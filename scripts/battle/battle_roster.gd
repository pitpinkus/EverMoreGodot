class_name BattleRoster
extends RefCounted
## Who is in the battle: the units of each side, in their original order. Living-unit
## queries skip fainted units. Owned by BattleManager; read-only for controllers and UI.

var _player_units: Array[BattleMonster] = []
var _enemy_units: Array[BattleMonster] = []


func _init(player_units: Array[BattleMonster], enemy_units: Array[BattleMonster]) -> void:
	_player_units = player_units
	_enemy_units = enemy_units


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


## Every other living unit, allies included: the units that block unit's path.
func get_blockers(unit: BattleMonster) -> Array[BattleMonster]:
	var blockers: Array[BattleMonster] = get_units(BattleTypes.Side.PLAYER)
	blockers.append_array(get_units(BattleTypes.Side.ENEMY))
	blockers.erase(unit)
	return blockers


## Every unit of both sides (player side first), fainted ones included.
func get_all_units() -> Array[BattleMonster]:
	var units: Array[BattleMonster] = _player_units.duplicate()
	units.append_array(_enemy_units)
	return units


## True once side has no unit left standing.
func is_defeated(side: BattleTypes.Side) -> bool:
	return get_units(side).is_empty()
