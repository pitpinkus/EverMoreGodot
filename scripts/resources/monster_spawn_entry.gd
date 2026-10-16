class_name MonsterSpawnEntry
extends Resource
## Recipe for a monster in an encounter or the starting party: species, level range,
## pick weight and optional fixed IVs.

@export var species: SpeciesData
@export_range(1, 100, 1) var min_level: int = 1
@export_range(1, 100, 1) var max_level: int = 1
## Relative chance to be picked from a RandomEncounter table.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
## Every IV gets this value; -1 = roll each IV randomly.
@export_range(-1, 99, 1) var fixed_iv: int = -1


## Builds a monster for every usable entry, in order; null and unusable entries are skipped.
static func build_all(entries: Array[MonsterSpawnEntry], rng: RandomNumberGenerator,
		rules: BattleRules) -> Array[MonsterInstance]:
	var monsters: Array[MonsterInstance] = []
	for entry: MonsterSpawnEntry in entries:
		if entry != null and entry.is_usable():
			monsters.append(entry.build(rng, rules))
	return monsters


## False if the entry cannot build a monster (no species set).
func is_usable() -> bool:
	return species != null


func build(rng: RandomNumberGenerator, rules: BattleRules) -> MonsterInstance:
	var level: int = rng.randi_range(min_level, maxi(min_level, max_level))
	var max_iv: int = rules.iv_max - 1
	var ivs: Dictionary[int, int] = {}
	for stat: int in BattleTypes.Stat.values():
		ivs[stat] = mini(fixed_iv, max_iv) if fixed_iv >= 0 else rng.randi_range(0, max_iv)
	return MonsterInstance.create(species, level, ivs, rules.max_known_moves)
