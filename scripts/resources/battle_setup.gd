class_name BattleSetup
extends Resource
## Everything the battle scene needs to start one battle, built by BattleFlow.

@export var enemy_team: Array[MonsterInstance] = []
## Null = the battle scene's default map.
@export var battle_map: PackedScene
@export var is_wild: bool = true
## Id of the encounter that started the battle; empty = repeatable.
@export var encounter_id: StringName
## Where the player goes back to after winning, fleeing or capturing.
@export var return_point: RespawnPoint


## A setup with encounter's enemy team, map and wildness (no id or return point yet).
static func from_encounter(encounter: Encounter, rng: RandomNumberGenerator, rules: BattleRules) -> BattleSetup:
	var setup: BattleSetup = BattleSetup.new()
	setup.enemy_team = encounter.build_enemy_team(rng, rules)
	setup.battle_map = encounter.battle_map
	setup.is_wild = encounter.is_wild
	return setup
