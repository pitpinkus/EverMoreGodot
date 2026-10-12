class_name PlayerStateMachine
extends StateMachine
## State machine for the player character. Receives intent from
## PlayerInputComponent (move_requested → set_move_intent, jump_requested →
## request_jump), shares it with its PlayerState children and relays their
## movement requests upward as signals for the Character to act on.

signal move_requested(direction: Vector3, running: bool)
signal jump_requested

## Read by the states for floor/velocity checks; never driven directly.
@export var character: Character

var _intent: PlayerIntent = PlayerIntent.new()


func _ready() -> void:
	if character == null:
		push_error("PlayerStateMachine '%s' has no character assigned." % name)
	super._ready()


func set_move_intent(direction: Vector3, running: bool) -> void:
	_intent.move_direction = direction
	_intent.running = running


func request_jump() -> void:
	_intent.request_jump()


func _setup_state(state: State) -> void:
	var player_state: PlayerState = state as PlayerState
	if player_state == null:
		push_error("PlayerStateMachine '%s': state '%s' is not a PlayerState." % [name, state.name])
		return
	player_state.setup(character, _intent)
	player_state.move_requested.connect(move_requested.emit)
	player_state.jump_requested.connect(jump_requested.emit)
