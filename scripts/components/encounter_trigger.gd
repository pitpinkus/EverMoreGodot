@tool
class_name EncounterTrigger
extends Area3D
## Starts a battle (through BattleFlow) when the player is in this area: right on
## entering (a wild monster, a trainer's line of sight) or by chance while walking
## around inside (tall grass). With an encounter_id, the encounter is gone once won.
## Runs in the editor only to keep the %Shape box in sync with size.

signal encounter_triggered(encounter: Encounter)
## The encounter was already won earlier; the trigger is switched off.
signal cleared
## size was applied to %Shape (also in the editor), e.g. to fill a visual to match.
signal size_changed(size: Vector3)

enum Mode {
	## Start as soon as the player enters.
	ON_ENTER,
	## Roll encounter_chance every check_distance metres the player walks inside.
	RANDOM_WHILE_MOVING,
}

@export var mode: Mode = Mode.ON_ENTER
@export var encounter: Encounter
## Marked cleared when the player wins or captures; empty = repeatable.
@export var encounter_id: StringName
## Size of the %Shape box: the whole trigger zone, chosen per instance by the designer.
@export var size: Vector3 = Vector3(2.0, 2.0, 2.0):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()
@export_range(0.1, 50.0, 0.1, "suffix:m") var check_distance: float = 2.0
@export_range(0.0, 1.0, 0.01) var encounter_chance: float = 0.15
@export var player_group: StringName = &"player"

var _player: Node3D
var _last_position: Vector3 = Vector3.ZERO
var _walked: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _shape: CollisionShape3D = %Shape


func _ready() -> void:
	set_physics_process(false)
	_apply_size()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Deferred: a parent (EncounterNpc) sets encounter_id in its own _ready, after ours.
	_check_cleared.call_deferred()
	_adopt_overlapping_player()


func _physics_process(_delta: float) -> void:
	var position_now: Vector3 = _player.global_position
	var step: float = BattleFormulas.flat_distance(_last_position, position_now)
	_last_position = position_now
	# Walking during a battle's aftermath (grace period) doesn't count toward a roll.
	if BattleFlow.is_encounter_blocked():
		return
	_walked += step
	if _walked < check_distance:
		return
	_walked = 0.0
	if _rng.randf() < encounter_chance:
		_try_start()


func _apply_size() -> void:
	var box: BoxShape3D = _shape.shape as BoxShape3D
	if box == null:
		push_warning("EncounterTrigger '%s': %%Shape needs a BoxShape3D." % name)
		return
	box.size = size
	size_changed.emit(size)


## The player may already stand inside when the level loads (placed back where a
## battle started); body_entered is not guaranteed then, so pick them up after the
## first physics step. ON_ENTER triggers still need a fresh entry.
func _adopt_overlapping_player() -> void:
	if mode != Mode.RANDOM_WHILE_MOVING:
		return
	await get_tree().physics_frame
	if not monitoring or _player != null:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group(player_group):
			_on_body_entered(body)
			return


func _check_cleared() -> void:
	if BattleFlow.is_encounter_cleared(encounter_id):
		set_deferred("monitoring", false)
		cleared.emit()


func _try_start() -> void:
	if BattleFlow.is_encounter_blocked():
		return
	if BattleFlow.start_battle(encounter, encounter_id):
		set_physics_process(false)
		encounter_triggered.emit(encounter)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	if mode == Mode.ON_ENTER:
		_try_start()
		return
	_player = body
	_last_position = body.global_position
	_walked = 0.0
	set_physics_process(true)


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		set_physics_process(false)
