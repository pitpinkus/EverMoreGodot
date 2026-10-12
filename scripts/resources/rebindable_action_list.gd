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
