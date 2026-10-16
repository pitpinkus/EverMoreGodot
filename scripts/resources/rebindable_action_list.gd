class_name RebindableActionList
extends Resource
## Ordered list of actions shown in the controls settings.

@export var actions: Array[RebindableAction] = []
## Actions that are not rebindable and whose inputs may not be taken by listed actions.
@export var reserved_actions: Array[StringName] = []


func get_action_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: RebindableAction in actions:
		names.append(entry.action)
	return names


## Listed actions (other than action) that share a context with action, so may not share its inputs.
func get_conflict_candidates(action: StringName) -> Array[StringName]:
	var source: RebindableAction = _find(action)
	var names: Array[StringName] = []
	if source == null:
		return names
	for entry: RebindableAction in actions:
		if entry != source and entry.shares_context_with(source):
			names.append(entry.action)
	return names


func _find(action: StringName) -> RebindableAction:
	for entry: RebindableAction in actions:
		if entry.action == action:
			return entry
	return null
