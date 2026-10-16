@abstract
class_name BattleController
extends Node
## Chooses what the units of one side do (player input or AI). A controller never
## changes the battle itself: it reads the BattleManager's query methods and returns
## BattleDecisions, which the manager executes.


## Called once when one of this controller's units starts its turn.
func begin_turn(_unit: BattleMonster, _battle: BattleManager) -> void:
	pass


## The next thing unit should do. May await (input, think delay). Called repeatedly
## during a turn until it returns END_TURN or the turn ends on its own.
@abstract func decide(unit: BattleMonster, battle: BattleManager) -> BattleDecision
