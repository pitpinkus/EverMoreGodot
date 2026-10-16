class_name BattleDecision
extends RefCounted
## What a battle controller wants its unit to do next. Controllers only return
## decisions; BattleManager validates and executes them.

enum Kind { MOVE, ACTION, FLEE, END_TURN }

var kind: Kind = Kind.END_TURN
## Destination of a MOVE.
var point: Vector3 = Vector3.ZERO
## Move or item of an ACTION.
var action: ActionData
## Target unit of an ACTION (the user itself for SELF actions).
var target: BattleMonster


static func move_to(destination: Vector3) -> BattleDecision:
	var decision: BattleDecision = BattleDecision.new()
	decision.kind = Kind.MOVE
	decision.point = destination
	return decision


static func use(used: ActionData, on: BattleMonster) -> BattleDecision:
	var decision: BattleDecision = BattleDecision.new()
	decision.kind = Kind.ACTION
	decision.action = used
	decision.target = on
	return decision


static func flee() -> BattleDecision:
	var decision: BattleDecision = BattleDecision.new()
	decision.kind = Kind.FLEE
	return decision


static func end_turn() -> BattleDecision:
	return BattleDecision.new()
