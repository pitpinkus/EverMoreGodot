class_name SpeciesData
extends GameDataEntry
## One kind of monster (data/monsters/*.tres): base stats, moves, catch rate, model, icon.

@export var element: BattleTypes.Element = BattleTypes.Element.FIRE

@export_group("Base stats")
@export_range(1, 255, 1) var base_hp: int = 50
@export_range(1, 255, 1) var base_attack: int = 50
@export_range(1, 255, 1) var base_defense: int = 50
@export_range(1, 255, 1) var base_speed: int = 50
@export_range(0, 100, 1, "suffix:%") var base_crit_rate: int = 5
## Extra damage of a critical hit, in percent.
@export_range(0, 255, 1, "suffix:%") var base_crit_mod: int = 50
@export_range(0, 100, 1) var base_dodge: int = 10

@export_group("Battle")
## Distance the monster may walk per turn.
@export_range(0.0, 30.0, 0.1, "suffix:m") var base_steps: float = 5.0
## Base chance to be caught (0..1) before HP and orb modifiers.
@export_range(0.0, 1.0, 0.01) var catch_rate: float = 0.5
@export var learnset: Array[LearnsetEntry] = []
## Hand-made portrait (turn timeline, party). Null = PortraitCache photographs the model.
@export var icon: Texture2D
## Model shown in battle and on overworld wild monsters. Its root must be a
## MonsterModel (inherit prefabs/characters/monster_model.tscn). Null = no model.
@export var model_scene: PackedScene


func get_base_stat(stat: BattleTypes.Stat) -> int:
	match stat:
		BattleTypes.Stat.HP:
			return base_hp
		BattleTypes.Stat.ATTACK:
			return base_attack
		BattleTypes.Stat.DEFENSE:
			return base_defense
		BattleTypes.Stat.SPEED:
			return base_speed
		BattleTypes.Stat.CRIT_RATE:
			return base_crit_rate
		BattleTypes.Stat.CRIT_MOD:
			return base_crit_mod
		BattleTypes.Stat.DODGE:
			return base_dodge
	return 0


## A new instance of model_scene, or null (with a warning) if there is none or its
## root is not a MonsterModel. The caller adds it to the tree.
func instantiate_model() -> MonsterModel:
	if model_scene == null:
		push_warning("SpeciesData '%s' has no model_scene." % id)
		return null
	var root: Node = model_scene.instantiate()
	var model: MonsterModel = root as MonsterModel
	if model == null:
		push_error("SpeciesData '%s': model_scene root is not a MonsterModel." % id)
		root.free()
	return model


## Moves learned at or below level, in learnset order (lowest level first).
func get_moves_up_to(level: int) -> Array[MoveData]:
	var entries: Array[LearnsetEntry] = []
	for entry: LearnsetEntry in learnset:
		if entry != null and entry.move != null and entry.level <= level:
			entries.append(entry)
	entries.sort_custom(func(a: LearnsetEntry, b: LearnsetEntry) -> bool: return a.level < b.level)
	var moves: Array[MoveData] = []
	for entry: LearnsetEntry in entries:
		if not moves.has(entry.move):
			moves.append(entry.move)
	return moves
