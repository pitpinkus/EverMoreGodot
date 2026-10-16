@abstract
class_name Encounter
extends Resource
## A battle that can be started from the overworld (data/encounters/*.tres).

## Battle map scene; null = the battle scene's default map.
@export var battle_map: PackedScene
## Wild monsters can be captured and fled from; trainers' cannot.
@export var is_wild: bool = true


## Builds the enemy side for one battle.
@abstract func build_enemy_team(rng: RandomNumberGenerator, rules: BattleRules) -> Array[MonsterInstance]
