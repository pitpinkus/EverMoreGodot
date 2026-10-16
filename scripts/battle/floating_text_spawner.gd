class_name FloatingTextSpawner
extends Node3D
## Turns BattleEvents into floating text over the affected units. The only place that
## decides a popup's text, colour and size (from style). Popups over the same unit are
## staggered so they don't overlap.

@export var style: FloatingTextStyle
## A FloatingText scene.
@export var text_scene: PackedScene


func _ready() -> void:
	if style == null or text_scene == null:
		push_error("FloatingTextSpawner '%s' needs style and text_scene." % name)


## Shows one popup per event over its target.
func show_events(events: Array[BattleEvent]) -> void:
	if style == null or text_scene == null:
		return
	var shown_per_unit: Dictionary[BattleMonster, int] = {}
	for event: BattleEvent in events:
		var index: int = shown_per_unit.get(event.target, 0)
		shown_per_unit[event.target] = index + 1
		_spawn(event, index * style.stagger)


func _spawn(event: BattleEvent, delay: float) -> void:
	var color: Color = style.damage_color
	var text: String = ""
	var size_scale: float = 1.0
	match event.kind:
		BattleEvent.Kind.DAMAGE:
			text = style.damage_format % event.amount
			if event.status != null:
				color = event.status.popup_color
			if event.crit:
				text = style.crit_format % [style.crit_text, text]
				color = style.crit_color
				size_scale = style.crit_scale
		BattleEvent.Kind.HEAL:
			text = style.heal_format % event.amount
			color = style.heal_color
		BattleEvent.Kind.MISS:
			text = style.miss_text
			color = style.miss_color
		BattleEvent.Kind.STAT_STAGE:
			var symbol: String = style.stage_up_symbol if event.stages > 0 else style.stage_down_symbol
			var count: int = mini(absi(event.stages), style.max_stage_symbols)
			text = style.stage_format % [BattleTypes.get_stat_abbreviation(event.stat), symbol.repeat(count)]
			color = style.buff_color if event.stages > 0 else style.debuff_color
		BattleEvent.Kind.STATUS_APPLIED:
			text = event.status.get_applied_label()
			color = style.status_color
		BattleEvent.Kind.STATUS_CURED:
			text = style.cured_format % event.status.display_name
			color = style.status_color
	var popup: FloatingText = text_scene.instantiate() as FloatingText
	add_child(popup)
	popup.global_position = event.target.get_fx_point()
	if style.font != null:
		popup.font = style.font
	popup.outline_size = style.outline_size
	popup.play(text, color, size_scale, style.rise_height, style.duration, delay)
