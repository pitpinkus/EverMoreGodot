class_name RandomEncounter
extends Encounter
## One monster picked from a weighted table (e.g. tall grass).

@export var table: Array[MonsterSpawnEntry] = []


func build_enemy_team(rng: RandomNumberGenerator, rules: BattleRules) -> Array[MonsterInstance]:
	var enemies: Array[MonsterInstance] = []
	var candidates: Array[MonsterSpawnEntry] = []
	var weights: PackedFloat32Array = []
	for entry: MonsterSpawnEntry in table:
		if entry != null and entry.is_usable() and entry.weight > 0.0:
			candidates.append(entry)
			weights.append(entry.weight)
	if candidates.is_empty():
		push_warning("RandomEncounter '%s': table has no usable entries." % resource_path)
		return enemies
	enemies.append(candidates[rng.rand_weighted(weights)].build(rng, rules))
	return enemies
