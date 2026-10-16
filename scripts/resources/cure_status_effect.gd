class_name CureStatusEffect
extends BattleEffect
## Removes one status from the affected unit, or all of them when status is null.

const CURED_FORMAT: String = "%s is no longer affected by %s."
const CURED_ALL_FORMAT: String = "%s is cured of all ailments."

## Status to remove; null removes every status.
@export var status: StatusEffectData


func can_apply(ctx: EffectContext) -> bool:
	if not _is_unit_alive(ctx):
		return false
	var holder: StatusHolderComponent = _get_unit(ctx).get_status_holder()
	return holder.has(status) if status != null else not holder.get_statuses().is_empty()


func _apply(ctx: EffectContext) -> void:
	var unit: BattleMonster = _get_unit(ctx)
	var holder: StatusHolderComponent = unit.get_status_holder()
	var monster_name: String = unit.instance.get_display_name()
	var cured: Array[StatusEffectData] = holder.get_statuses()
	if status != null:
		cured = [status]
		holder.remove(status)
		ctx.log_message(CURED_FORMAT % [monster_name, status.display_name])
	else:
		holder.clear()
		ctx.log_message(CURED_ALL_FORMAT % monster_name)
	for cured_status: StatusEffectData in cured:
		ctx.record(BattleEvent.status_cured(unit, cured_status))
