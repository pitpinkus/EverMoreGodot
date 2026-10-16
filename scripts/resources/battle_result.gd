class_name BattleResult
extends Resource
## How a battle ended, handed from the battle scene to BattleFlow.

@export var outcome: BattleTypes.Outcome = BattleTypes.Outcome.WON
## The monster caught when outcome is CAPTURED.
@export var captured: MonsterInstance
@export var encounter_id: StringName
