class_name MonsterInstance
extends Resource
## One owned or wild monster: species, level, IVs, current HP and known moves.
## HP carries over between battles; statuses and stat stages are battle-only (on BattleMonster).
## Saved as plain data with to_dict() / from_dict() (ids resolved through DataRegistry).

signal hp_changed(current: int, maximum: int)

const KEY_SPECIES: String = "species"
const KEY_NICKNAME: String = "nickname"
const KEY_LEVEL: String = "level"
const KEY_IVS: String = "ivs"
const KEY_CURRENT_HP: String = "current_hp"
const KEY_MOVES: String = "moves"

@export var species: SpeciesData
## Empty = use the species name.
@export var nickname: String = ""
@export_range(1, 100, 1) var level: int = 1
## Individual values by BattleTypes.Stat. Missing stats count as 0.
@export var ivs: Dictionary[int, int] = {}
@export var current_hp: int = 0
@export var moves: Array[MoveData] = []


## A new monster at full HP knowing the last max_moves moves of its learnset up to level.
static func create(monster_species: SpeciesData, monster_level: int, monster_ivs: Dictionary[int, int],
		max_moves: int) -> MonsterInstance:
	var monster: MonsterInstance = MonsterInstance.new()
	monster.species = monster_species
	monster.level = monster_level
	monster.ivs = monster_ivs.duplicate()
	var learned: Array[MoveData] = monster_species.get_moves_up_to(monster_level)
	monster.moves.assign(learned.slice(maxi(0, learned.size() - max_moves)))
	monster.current_hp = monster.get_max_hp()
	return monster


## Rebuilds a monster from to_dict() output. Null if the species is unknown.
static func from_dict(data: Dictionary) -> MonsterInstance:
	var found: SpeciesData = DataRegistry.get_species(StringName(str(data.get(KEY_SPECIES, ""))))
	if found == null:
		return null
	var monster: MonsterInstance = MonsterInstance.new()
	monster.species = found
	monster.nickname = str(data.get(KEY_NICKNAME, ""))
	monster.level = maxi(1, int(data.get(KEY_LEVEL, 1)))
	var stored_ivs: Variant = data.get(KEY_IVS, {})
	if stored_ivs is Dictionary:
		for stat: Variant in stored_ivs:
			monster.ivs[int(stat)] = int(stored_ivs[stat])
	var stored_moves: Variant = data.get(KEY_MOVES, [])
	if stored_moves is Array:
		for move_id: Variant in stored_moves:
			var move: MoveData = DataRegistry.get_move(StringName(str(move_id)))
			if move != null:
				monster.moves.append(move)
	monster.current_hp = clampi(int(data.get(KEY_CURRENT_HP, monster.get_max_hp())), 0, monster.get_max_hp())
	return monster


## Plain-data copy for saving.
func to_dict() -> Dictionary:
	var move_ids: Array[String] = []
	for move: MoveData in moves:
		move_ids.append(String(move.id))
	return {
		KEY_SPECIES: String(species.id),
		KEY_NICKNAME: nickname,
		KEY_LEVEL: level,
		KEY_IVS: ivs.duplicate(),
		KEY_CURRENT_HP: current_hp,
		KEY_MOVES: move_ids,
	}


func get_display_name() -> String:
	return nickname if not nickname.is_empty() else species.display_name


## stat at the current level, before battle stat stages.
func get_base_stat(stat: BattleTypes.Stat) -> int:
	return BattleFormulas.stat_value(species.get_base_stat(stat), ivs.get(stat, 0), level, stat == BattleTypes.Stat.HP)


func get_max_hp() -> int:
	return get_base_stat(BattleTypes.Stat.HP)


## current_hp / max HP in 0..1.
func get_hp_ratio() -> float:
	return float(current_hp) / maxi(1, get_max_hp())


func is_fainted() -> bool:
	return current_hp <= 0


## Adds up to amount HP (capped at max). Returns the HP actually gained.
func heal(amount: int) -> int:
	return _set_hp(current_hp + maxi(0, amount))


## Removes up to amount HP (not below 0). Returns the HP actually lost.
func apply_damage(amount: int) -> int:
	return -_set_hp(current_hp - maxi(0, amount))


func restore_full() -> void:
	_set_hp(get_max_hp())


## Sets HP clamped to 0..max, emits hp_changed if it changed; returns the change.
func _set_hp(value: int) -> int:
	var previous: int = current_hp
	current_hp = clampi(value, 0, get_max_hp())
	if current_hp != previous:
		hp_changed.emit(current_hp, get_max_hp())
	return current_hp - previous
