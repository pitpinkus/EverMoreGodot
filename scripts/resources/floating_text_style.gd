class_name FloatingTextStyle
extends Resource
## Look and wording of battle floating text (data/vfx/floating_text_style.tres), used by
## FloatingTextSpawner.

@export_group("Colours")
@export var damage_color: Color = Color(1.0, 0.95, 0.9)
@export var crit_color: Color = Color(1.0, 0.8, 0.2)
@export var heal_color: Color = Color(0.45, 1.0, 0.5)
@export var miss_color: Color = Color(0.75, 0.78, 0.8)
@export var buff_color: Color = Color(0.45, 0.8, 1.0)
@export var debuff_color: Color = Color(1.0, 0.45, 0.45)
## Statuses applied or cured (their damage uses StatusEffectData.popup_color).
@export var status_color: Color = Color(1.0, 0.7, 0.35)

@export_group("Text")
## %d = HP lost.
@export var damage_format: String = "-%d"
## %d = HP gained.
@export var heal_format: String = "+%d"
## Put in front of the damage of a critical hit.
@export var crit_text: String = "Critical!"
## Joins crit_text and the damage text ("Critical! -20").
@export var crit_format: String = "%s %s"
@export var miss_text: String = "Miss"
## %s = status name.
@export var cured_format: String = "%s cured"
## Repeated once per stage after the stat abbreviation. The default project font has
## no arrow glyphs, so "+" / "-"; use "↑" / "↓" with a font that has them.
@export var stage_up_symbol: String = "+"
@export var stage_down_symbol: String = "-"
## Joins the stat abbreviation and the stage symbols ("DEF ++").
@export var stage_format: String = "%s %s"
## At most this many symbols for a big stage change.
@export_range(1, 6, 1) var max_stage_symbols: int = 3

@export_group("Motion and size")
## Size multiplier of critical-hit text.
@export_range(0.5, 3.0, 0.05) var crit_scale: float = 1.4
@export_range(0.0, 5.0, 0.05, "suffix:m") var rise_height: float = 0.8
@export_range(0.1, 5.0, 0.05, "suffix:s") var duration: float = 0.9
## Delay between popups over the same unit, so they don't overlap.
@export_range(0.0, 2.0, 0.05, "suffix:s") var stagger: float = 0.25
## Null = the text scene's own font.
@export var font: Font
@export_range(0, 32, 1) var outline_size: int = 12
