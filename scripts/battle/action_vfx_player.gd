class_name ActionVfxPlayer
extends Node3D
## Plays how actions and status ticks look. The only place that spawns battle VFX;
## spawned effects become its children (they free themselves). Actions without their
## own ActionVfx use default_offensive_vfx (target_kind ENEMY) or default_support_vfx
## (SELF / ALLY).

@export var default_offensive_vfx: ActionVfx
@export var default_support_vfx: ActionVfx
## How far beside and past the target a missed projectile flies.
@export_range(0.0, 10.0, 0.1, "suffix:m") var miss_offset: float = 1.5


## user uses action on target. Await it: returns at the moment of impact (after the
## cast, lunge and projectile), so the caller applies the effects right then.
func play_action(user: BattleMonster, target: BattleMonster, action: ActionData, hit: bool) -> void:
	var vfx: ActionVfx = _get_vfx(action)
	if vfx == null:
		return
	_spawn(vfx.cast_vfx, user.get_fx_point())
	if vfx.cast_delay > 0.0:
		await get_tree().create_timer(vfx.cast_delay, false).timeout
	if target != user:
		if vfx.lunge:
			await user.play_lunge(target.global_position)
		if vfx.projectile != null:
			var aim: Vector3 = target.get_fx_point() if hit else _get_miss_point(user, target)
			var projectile: Projectile = vfx.projectile.instantiate() as Projectile
			add_child(projectile)
			await projectile.fly(user.get_fx_point(), aim)
	if hit:
		_spawn(vfx.impact_vfx, target.get_fx_point())


## Spawns scene (e.g. a status tick effect) at unit. Null scene = nothing.
func play_at(unit: BattleMonster, scene: PackedScene) -> void:
	_spawn(scene, unit.get_fx_point())


func _get_vfx(action: ActionData) -> ActionVfx:
	if action.vfx != null:
		return action.vfx
	return default_offensive_vfx if action.target_kind == BattleTypes.TargetKind.ENEMY else default_support_vfx


## A point beside and behind target as seen from user, for projectiles that miss.
func _get_miss_point(user: BattleMonster, target: BattleMonster) -> Vector3:
	var forward: Vector3 = BattleFormulas.flat_offset(user.global_position, target.global_position).normalized()
	var side: Vector3 = forward.cross(Vector3.UP)
	return target.get_fx_point() + (forward + side) * miss_offset


func _spawn(scene: PackedScene, point: Vector3) -> void:
	if scene == null:
		return
	var effect: Node3D = scene.instantiate() as Node3D
	add_child(effect)
	effect.global_position = point
