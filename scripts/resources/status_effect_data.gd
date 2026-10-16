class_name StatusEffectData
extends GameDataEntry
## A battle-only status such as Burn (data/status_effects/*.tres).

@export var element: BattleTypes.Element = BattleTypes.Element.FIRE
## Re-applying adds to the remaining turns instead of resetting them.
@export var stacks: bool = false
## Run on the owner (self and target) at the start of each of its turns.
@export var turn_start_effects: Array[BattleEffect] = []

@export_group("Presentation")
## Played on the owner each time the status ticks (ActionVfxPlayer.play_at). Null = none.
@export var tick_vfx: PackedScene
## Colour of the floating numbers for damage this status deals.
@export var popup_color: Color = Color.WHITE
## Floating text when the status is applied. Empty = display_name.
@export var applied_label: String = ""


func get_applied_label() -> String:
	return applied_label if not applied_label.is_empty() else display_name
