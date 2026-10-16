class_name ActionData
extends GameDataEntry
## Something a monster can do to a target: the shared base of MoveData and ItemData.
## What it does is the list of effects; the same pipeline runs in battle and overworld.

@export_multiline var description: String = ""
@export var icon: Texture2D
@export var target_kind: BattleTypes.TargetKind = BattleTypes.TargetKind.ENEMY
## Furthest distance from user to target. (Named max_range because range() is a built-in.)
@export_range(0.0, 50.0, 0.1, "suffix:m") var max_range: float = 2.0
@export var effects: Array[BattleEffect] = []
## How using it looks in battle. Null = ActionVfxPlayer's default for its target kind.
@export var vfx: ActionVfx


## True if using this rolls accuracy against the target's Dodge.
func rolls_accuracy() -> bool:
	return false


## Accuracy in percent before the target's Dodge.
func get_accuracy() -> int:
	return roundi(BattleFormulas.PERCENT)


## Applies every effect that can still do something, in order.
func apply_effects(ctx: EffectContext) -> void:
	BattleEffect.apply_all(effects, ctx)


## True if at least one effect would do something in ctx.
func can_use_on(ctx: EffectContext) -> bool:
	return BattleEffect.any_can_apply(effects, ctx)
