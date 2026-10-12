@abstract
class_name StateMachine
extends Node
## Generic finite state machine. Every State child is registered by its node name
## and can request transitions. Subclasses inject their dependencies into each
## state through _setup_state().

signal state_changed(from: StringName, to: StringName)

## Runs before the owning body's physics step (and its move_and_slide).
const PHYSICS_PRIORITY: int = -1

@export var initial_state: State

var _states: Dictionary[StringName, State] = {}
var _current_state: State


func _ready() -> void:
	process_physics_priority = PHYSICS_PRIORITY
	for child: Node in get_children():
		var state: State = child as State
		if state == null:
			continue
		_states[state.name] = state
		state.transition_requested.connect(transition_to)
		_setup_state(state)
	# Deferred: the owner's @onready vars are still null while children run _ready.
	_start.call_deferred()


func _process(delta: float) -> void:
	if _current_state != null:
		_current_state.update(delta)


func _physics_process(delta: float) -> void:
	if _current_state != null:
		_current_state.physics_update(delta)


func get_current_state() -> State:
	return _current_state


## Switches to the State child named state_name. Ignored if it is already active.
func transition_to(state_name: StringName) -> void:
	var next: State = _states.get(state_name) as State
	if next == null:
		push_error("StateMachine '%s' has no state named '%s'." % [name, state_name])
		return
	if next == _current_state:
		return
	var previous_name: StringName = &""
	if _current_state != null:
		previous_name = _current_state.name
		_current_state.exit()
	_current_state = next
	next.enter(previous_name)
	state_changed.emit(previous_name, state_name)


## Gives a freshly registered state whatever it needs from the machine's owner.
@abstract func _setup_state(state: State) -> void


func _start() -> void:
	if initial_state == null:
		push_error("StateMachine '%s' has no initial_state assigned." % name)
		return
	transition_to(initial_state.name)
