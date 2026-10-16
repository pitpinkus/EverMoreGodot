class_name ApplyStatusEffect
extends BattleEffect
## Gives the affected unit a status (e.g. Burn) for some of its turns.

const APPLIED_FORMAT: String = "%s is afflicted by %s!"
const REFRESHED_FORMAT: String = "%s's %s lasts longer!"

@export var status: StatusEffectData
@export_range(1, 20, 1, "suffix:turns") var duration: int = 3


func can_apply(ctx: EffectContext) -> bool:
	return status != null and _is_unit_alive(ctx)


func _apply(ctx: EffectContext) -> void:
	var unit: BattleMonster = _get_unit(ctx)
	var is_new: bool = unit.get_status_holder().add(status, duration)
	ctx.record(BattleEvent.status_applied(unit, status))
	var text_format: String = APPLIED_FORMAT if is_new else REFRESHED_FORMAT
	ctx.log_message(text_format % [unit.instance.get_display_name(), status.display_name])
