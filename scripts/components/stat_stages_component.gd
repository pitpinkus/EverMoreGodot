class_name StatStagesComponent
extends Node
## Battle-only stat buffs/debuffs of one unit. Every buff keeps its own duration in
## the owner's turns; the stage of a stat is the sum of its active buffs (clamped
## later by BattleRules when the multiplier is applied). HP is never staged.

signal stages_changed

## One active buff: stages on stat for turns_left more owner turns.
class StageBuff:
	extends RefCounted
	var stat: BattleTypes.Stat
	var stages: int
	var turns_left: int

	func _init(buff_stat: BattleTypes.Stat, buff_stages: int, turns: int) -> void:
		stat = buff_stat
		stages = buff_stages
		turns_left = turns


var _buffs: Array[StageBuff] = []


func add(stat: BattleTypes.Stat, stages: int, turns: int) -> void:
	if stat == BattleTypes.Stat.HP or stages == 0 or turns <= 0:
		return
	_buffs.append(StageBuff.new(stat, stages, turns))
	stages_changed.emit()


## Sum of the active buffs on stat (not clamped). With ticks_ahead > 0: the sum once
## that many more owner turns have started (buffs that run out by then left out).
func get_stage(stat: BattleTypes.Stat, ticks_ahead: int = 0) -> int:
	var total: int = 0
	for buff: StageBuff in _buffs:
		if buff.stat == stat and buff.turns_left > ticks_ahead:
			total += buff.stages
	return total


## Counts one owner turn down and drops buffs that ran out.
func tick() -> void:
	var remaining: Array[StageBuff] = []
	for buff: StageBuff in _buffs:
		buff.turns_left -= 1
		if buff.turns_left > 0:
			remaining.append(buff)
	var expired: bool = remaining.size() != _buffs.size()
	_buffs = remaining
	if expired:
		stages_changed.emit()


func clear() -> void:
	if _buffs.is_empty():
		return
	_buffs.clear()
	stages_changed.emit()
