class_name BattleAIProfile
extends Resource
## How an AI-controlled side behaves in battle (data/battle/default_ai_profile.tres).

## Pause before each decision so the player can follow the enemy turn.
@export_range(0.0, 5.0, 0.05, "suffix:s") var think_delay: float = 0.9
## Below this fraction of max HP the AI prefers healing.
@export_range(0.0, 1.0, 0.01) var heal_threshold: float = 0.35
## The AI stops this fraction of its longest damaging range away from its target.
@export_range(0.1, 1.0, 0.01) var range_margin: float = 0.9
@export var use_stat_moves: bool = true
## The AI stops buffing itself once a stat reaches this stage.
@export_range(0, 6, 1) var max_self_stage: int = 2
