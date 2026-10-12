@abstract
class_name State
extends Node
## One state of a StateMachine. The machine calls the hooks below; a state never
## switches itself directly but asks its machine via transition_requested.

## Ask the owning StateMachine to switch to the state node named `to`.
signal transition_requested(to: StringName)


## Called when this state becomes active. previous is the name of the old state
## (empty for the initial state).
func enter(_previous: StringName) -> void:
	pass


## Called right before another state becomes active.
func exit() -> void:
	pass


## Called every idle frame while active.
func update(_delta: float) -> void:
	pass


## Called every physics frame while active.
func physics_update(_delta: float) -> void:
	pass
