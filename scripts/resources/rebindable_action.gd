class_name RebindableAction
extends Resource
## An InputMap action the player may rebind, with its name in the controls menu and
## the game contexts it is used in. Actions that share no context may share inputs.

## Default context bit (see contexts).
const CONTEXT_OVERWORLD: int = 1

@export var action: StringName = &""
@export var display_name: String = ""
## Where the action is used, as bit flags: 1 = Overworld, 2 = Battle (3 = both).
## Two actions only conflict if they share a context.
@export_flags("Overworld", "Battle") var contexts: int = CONTEXT_OVERWORLD
## Heading shown above this action in the controls menu when it differs from the previous action's.
@export var section: String = ""


## True if both actions are used in at least one common context.
func shares_context_with(other: RebindableAction) -> bool:
	return contexts & other.contexts != 0
