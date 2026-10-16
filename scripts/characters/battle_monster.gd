class_name BattleMonster
extends Character
## A monster on the battlefield: a Character driven by a battle controller, wrapping
## the MonsterInstance it fights for. Battle-only state lives in its components
## (step budget, stat stages, statuses); HP lives on the instance and is relayed here.

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

@onready var _step_budget: StepBudgetComponent = %StepBudgetComponent
@onready var _stat_stages: StatStagesComponent = %StatStagesComponent
@onready var _status_holder: StatusHolderComponent = %StatusHolderComponent
@onready var _selection_ring: Node3D = %SelectionRing
@onready var _fx_anchor: Marker3D = %FxAnchor


func _ready() -> void:
	super._ready()
	_status_holder.statuses_changed.connect(statuses_changed.emit)
	set_selected(false)


## Binds the monster this unit fights for and its side, and shows the species model.
func setup(monster: MonsterInstance, unit_side: BattleTypes.Side) -> void:
	if instance != null:
		instance.hp_changed.disconnect(_on_instance_hp_changed)
	instance = monster
	side = unit_side
	instance.hp_changed.connect(_on_instance_hp_changed)
	for child: Node in _visual.get_children():
		child.queue_free()
	if instance.species.model_scene != null:
		_visual.add_child(instance.species.model_scene.instantiate())
	else:
		push_warning("BattleMonster: species '%s' has no model_scene." % instance.species.id)


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


## Walks towards point within the step budget. Await it.
func move_to(point: Vector3) -> void:
	await _step_budget.move_to(point)


func set_selected(selected: bool) -> void:
	_selection_ring.visible = selected


## Shrinks the model, then hides the unit and takes it out of collisions. Await it.
func play_faint() -> void:
	set_selected(false)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "scale", Vector3.ONE * faint_scale, faint_duration)
	await tween.finished
	hide()
	collision_layer = 0
	collision_mask = 0


## Where effects and floating text appear on this unit (%FxAnchor).
func get_fx_point() -> Vector3:
	return _fx_anchor.global_position


## Darts the model towards toward and back. Await it: returns at the lunge's peak (the
## moment of impact); the way back plays on.
func play_lunge(toward: Vector3) -> void:
	var rest: Vector3 = _visual.position
	var offset: Vector3 = BattleFormulas.flat_offset(global_position, toward).normalized() * lunge_distance
	var peak: Vector3 = rest + global_basis.inverse() * offset
	var half: float = lunge_duration / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "position", peak, half).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_visual, "position", rest, half).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.step_finished


func get_step_budget() -> StepBudgetComponent:
	return _step_budget


func get_stat_stages() -> StatStagesComponent:
	return _stat_stages


func get_status_holder() -> StatusHolderComponent:
	return _status_holder


func _on_instance_hp_changed(current: int, maximum: int) -> void:
	hp_changed.emit(current, maximum)
	if current <= 0:
		fainted.emit(self)
