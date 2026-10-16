class_name FixedEncounter
extends Encounter
## Always the same team (a trainer, or a specific wild monster).

@export var team: Array[MonsterSpawnEntry] = []


func build_enemy_team(rng: RandomNumberGenerator, rules: BattleRules) -> Array[MonsterInstance]:
	return MonsterSpawnEntry.build_all(team, rng, rules)
