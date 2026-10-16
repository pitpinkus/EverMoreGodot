class_name BattleRules
extends Resource
## Game-wide battle tunables (data/battle/battle_rules.tres).

@export_group("Stat stages")
## Multiplier per stage from -max_stage to +max_stage (2 * max_stage + 1 values).
@export var stage_multipliers: Array[float] = [0.20, 0.35, 0.50, 0.65, 0.75, 0.90, 1.00, 1.25, 1.50, 1.75, 2.00, 2.25, 2.50]
@export_range(1, 12, 1) var max_stage: int = 6

@export_group("Accuracy and damage")
## How much of the target's Dodge is subtracted from accuracy.
@export_range(0.0, 2.0, 0.05) var dodge_effectiveness: float = 0.5
@export_range(0.0, 100.0, 1.0, "suffix:%") var min_hit_chance: float = 5.0
@export_range(0.0, 100.0, 1.0, "suffix:%") var max_hit_chance: float = 100.0
## Lowest random damage multiplier (highest is 1.0).
@export_range(0.0, 1.0, 0.01) var damage_variance_min: float = 0.85

@export_group("Monsters")
## IVs are rolled in 0 .. iv_max - 1.
@export_range(1, 100, 1) var iv_max: int = 24
@export_range(1, 8, 1) var max_known_moves: int = 4
@export_range(1, 12, 1) var max_party_size: int = 6
@export_range(1, 6, 1) var max_units_per_side: int = 2

@export_group("Flee and capture")
@export_range(0.0, 1.0, 0.01) var flee_chance: float = 1.0
## How strongly the target's remaining HP lowers the capture chance (0 = not at all).
@export_range(0.0, 1.0, 0.01) var capture_hp_weight: float = 0.7

@export_group("Turn flow")
## A turn ends automatically after acting once fewer steps than this remain.
@export_range(0.0, 5.0, 0.05, "suffix:m") var min_move_distance: float = 0.25
## Pause after each action so the player can read the result.
@export_range(0.0, 5.0, 0.05, "suffix:s") var action_delay: float = 0.6

@export_group("Turn timeline")
## Wait after a turn is turn_base_delay / Speed * jitter (timeline units; only ratios matter).
@export_range(1.0, 100000.0, 1.0) var turn_base_delay: float = 1000.0
## Random factor on every wait, rolled in turn_jitter_min .. turn_jitter_max.
@export_range(0.1, 2.0, 0.01) var turn_jitter_min: float = 0.85
@export_range(0.1, 2.0, 0.01) var turn_jitter_max: float = 1.15
## Speed below this counts as this when working out the wait (avoids dividing by 0).
@export_range(1, 100, 1) var min_turn_speed: int = 1


## Stat multiplier for stage, clamped to -max_stage .. +max_stage.
func get_stage_multiplier(stage: int) -> float:
	var index: int = clamp_stage(stage) + max_stage
	if index < 0 or index >= stage_multipliers.size():
		push_error("BattleRules: stage_multipliers needs %d values." % (2 * max_stage + 1))
		return 1.0
	return stage_multipliers[index]


func clamp_stage(stage: int) -> int:
	return clampi(stage, -max_stage, max_stage)
