class_name StatusHolderComponent
extends Node
## Battle-only statuses (Burn, ...) of one unit and how many of the owner's turns
## each has left. Re-applying a stacking status adds turns, otherwise resets them.

signal statuses_changed(statuses: Array[StatusEffectData])

var _turns_left: Dictionary[StatusEffectData, int] = {}


## Applies status for turns. Returns true if it is new, false if it was refreshed.
func add(status: StatusEffectData, turns: int) -> bool:
	var is_new: bool = not _turns_left.has(status)
	if is_new or not status.stacks:
		_turns_left[status] = turns
	else:
		_turns_left[status] += turns
	statuses_changed.emit(get_statuses())
	return is_new


func remove(status: StatusEffectData) -> void:
	if _turns_left.erase(status):
		statuses_changed.emit(get_statuses())


func has(status: StatusEffectData) -> bool:
	return _turns_left.has(status)


## Active statuses in the order they were applied.
func get_statuses() -> Array[StatusEffectData]:
	var statuses: Array[StatusEffectData] = []
	statuses.assign(_turns_left.keys())
	return statuses


## Counts one owner turn down and removes statuses that ran out.
func tick() -> void:
	var expired: Array[StatusEffectData] = []
	for status: StatusEffectData in _turns_left:
		_turns_left[status] -= 1
		if _turns_left[status] <= 0:
			expired.append(status)
	for status: StatusEffectData in expired:
		_turns_left.erase(status)
	if not expired.is_empty():
		statuses_changed.emit(get_statuses())


func clear() -> void:
	if _turns_left.is_empty():
		return
	_turns_left.clear()
	statuses_changed.emit(get_statuses())
