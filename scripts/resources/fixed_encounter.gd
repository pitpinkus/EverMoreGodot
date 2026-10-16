class_name FixedEncounter
extends Encounter
## Always the same team (a trainer, or a specific wild monster).

@export var team: Array[MonsterSpawnEntry] = []


func build_enemy_team(rng: RandomNumberGenerator, rules: BattleRules) -> Array[MonsterInstance]:
	return MonsterSpawnEntry.build_all(team, rng, rules)


## The species of the first usable team entry (the monster you meet first).
func get_preview_species() -> SpeciesData:
	for entry: MonsterSpawnEntry in team:
		if entry != null and entry.is_usable():
			return entry.species
	return null
