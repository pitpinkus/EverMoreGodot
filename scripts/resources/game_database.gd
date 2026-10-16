class_name GameDatabase
extends Resource
## Lists every piece of game content so DataRegistry can find it by id
## (data/game_database.tres). New content must be added here.

@export var rules: BattleRules
@export var species: Array[SpeciesData] = []
@export var moves: Array[MoveData] = []
@export var items: Array[ItemData] = []
@export var statuses: Array[StatusEffectData] = []
