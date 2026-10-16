class_name BattleMonster
extends Character
## A monster on the battlefield: a Character driven by a battle controller, wrapping
## the MonsterInstance it fights for. Battle-only state lives in its components
## (step budget, stat stages, statuses); HP lives on the instance and is relayed here.
## Its species' MonsterModel plays walk / idle while moving, attack on a lunge, hit
## when HP drops and faint when it faints.

signal hp_changed(current: int, maximum: int)
signal statuses_changed(statuses: Array[StatusEffectData])
## HP reached 0. The unit stays in the tree (hidden after play_faint) so references stay valid.
signal fainted(unit: BattleMonster)

## Length of the shrink animation when fainting.
@export_range(0.0, 3.0, 0.05, "suffix:s") var faint_duration: float = 0.6
## Scale the model shrinks to before it is hidden.
@export_range(0.0, 1.0, 0.01) var faint_scale: float = 0.05
## How far the model darts towards its target in a melee lunge.
@export_range(0.0, 3.0, 0.05, "suffix:m") var lunge_distance: float = 0.6
## Length of the whole lunge (out and back).
@export_range(0.05, 2.0, 0.05, "suffix:s") var lunge_duration: float = 0.25

var instance: MonsterInstance
var side: BattleTypes.Side = BattleTypes.Side.PLAYER

## The species model in %Visual, or null if the species has none.
var _model: MonsterModel
var _last_hp: int = 0
var _walking: bool = false

@onready var _step_budget: StepBudgetComponent = %StepBudgetComponent
@onready var _stat_stages: StatStagesComponent = %StatStagesComponent
@onready var _status_holder: StatusHolderComponent = %StatusHolderComponent
@onready var _selection_ring: Node3D = %SelectionRing
@onready var _fx_anchor: Marker3D = %FxAnchor
@onready var _body_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	super._ready()
	_status_holder.statuses_changed.connect(statuses_changed.emit)
	_step_budget.move_requested.connect(_on_move_requested)
	set_selected(false)


## Binds the monster this unit fights for and its side, and shows the species model.
func setup(monster: MonsterInstance, unit_side: BattleTypes.Side) -> void:
	if instance != null:
		instance.hp_changed.disconnect(_on_instance_hp_changed)
	instance = monster
	side = unit_side
	instance.hp_changed.connect(_on_instance_hp_changed)
	_last_hp = instance.current_hp
	for child: Node in _visual.get_children():
		child.queue_free()
	_model = instance.species.instantiate_model()
	if _model != null:
		_visual.add_child(_model)


## stat after battle stat stages (HP is never staged).
func get_stat(stat: BattleTypes.Stat) -> int:
	return get_projected_stat(stat, 0)


## stat as it will be once turns_ahead more of this unit's turns have started (stat
## buffs count down at turn start). Used to predict the turn timeline.
func get_projected_stat(stat: BattleTypes.Stat, turns_ahead: int) -> int:
	var value: int = instance.get_base_stat(stat)
	if stat == BattleTypes.Stat.HP:
		return value
	return BattleFormulas.staged(value, _stat_stages.get_stage(stat, turns_ahead), DataRegistry.get_rules())


func is_alive() -> bool:
	return instance != null and not instance.is_fainted()


## Start of this unit's turn: refills the step budget and counts stat buffs down.
## Statuses are ticked by ActionResolver.tick_status (their effects need a context).
func begin_turn() -> void:
	_step_budget.reset(instance.species.base_steps)
	_stat_stages.tick()


## Walks along path (from BattleNavigator) within the step budget. Await it.
func move_along(path: PackedVector3Array) -> void:
	await _step_budget.move_along(path)


func set_selected(selected: bool) -> void:
	_selection_ring.visible = selected


## Plays the model's faint clip (or shrinks the model if it has none), then hides the
## unit and takes it out of collisions. Await it.
func play_faint() -> void:
	set_selected(false)
	if _model != null and _model.has_clip(MonsterModel.CLIP_FAINT):
		await _model.play_once(MonsterModel.CLIP_FAINT, false)
	else:
		var tween: Tween = create_tween()
		tween.tween_property(_visual, "scale", Vector3.ONE * faint_scale, faint_duration)
		await tween.finished
	hide()
	collision_layer = 0
	collision_mask = 0


## Where effects and floating text appear on this unit (%FxAnchor).
func get_fx_point() -> Vector3:
	return _fx_anchor.global_position


## Darts the model towards toward and back while its attack clip plays. Await it:
## returns at the lunge's peak (the moment of impact); the way back plays on.
func play_lunge(toward: Vector3) -> void:
	if _model != null:
		_model.play_once(MonsterModel.CLIP_ATTACK)
	var rest: Vector3 = _visual.position
	var offset: Vector3 = BattleFormulas.flat_offset(global_position, toward).normalized() * lunge_distance
	var peak: Vector3 = rest + global_basis.inverse() * offset
	var half: float = lunge_duration / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "position", peak, half).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_visual, "position", rest, half).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.step_finished


## Horizontal radius of the unit's collision body (0 with a warning for shapes without one).
func get_body_radius() -> float:
	var shape: Shape3D = _body_shape.shape
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).radius
	if shape is CylinderShape3D:
		return (shape as CylinderShape3D).radius
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius
	push_warning("BattleMonster '%s': can't read a radius from its collision shape." % name)
	return 0.0


func get_step_budget() -> StepBudgetComponent:
	return _step_budget


func get_stat_stages() -> StatStagesComponent:
	return _stat_stages


func get_status_holder() -> StatusHolderComponent:
	return _status_holder


func _on_instance_hp_changed(current: int, maximum: int) -> void:
	var dropped: bool = current < _last_hp
	_last_hp = current
	hp_changed.emit(current, maximum)
	if dropped and current > 0 and _model != null:
		_model.play_once(MonsterModel.CLIP_HIT)
	if current <= 0:
		fainted.emit(self)


## Step budget walking: walk clip while moving, idle once stopped.
func _on_move_requested(direction: Vector3, _running: bool) -> void:
	var walking: bool = not direction.is_zero_approx()
	if walking != _walking and _model != null:
		_model.set_walking(walking)
	_walking = walking
