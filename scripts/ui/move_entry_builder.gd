class_name MoveEntryBuilder
extends RefCounted
## Builds move list rows ("Pow 40 · Acc 95% · Range 6 m" with an element badge),
## shared by the battle Fight list and the monster summary.

const DETAIL_FORMAT: String = "Pow %s · Acc %s · Range %.0f m"
const ACCURACY_FORMAT: String = "%d%%"
## Shown for power / accuracy that don't apply (status moves, never-miss moves).
const NO_VALUE: String = "-"


## One entry per move (payload = MoveData, element = its element).
static func build(moves: Array[MoveData]) -> Array[ChoiceEntry]:
	var entries: Array[ChoiceEntry] = []
	for move: MoveData in moves:
		var entry: ChoiceEntry = ChoiceEntry.new(move.display_name, get_detail(move), move.description, move)
		entry.element = move.element
		entries.append(entry)
	return entries


## Power, accuracy and range of move in one line.
static func get_detail(move: MoveData) -> String:
	var power: int = move.get_power()
	var power_text: String = str(power) if power > 0 else NO_VALUE
	var accuracy_text: String = ACCURACY_FORMAT % move.get_accuracy() if move.rolls_accuracy() else NO_VALUE
	return DETAIL_FORMAT % [power_text, accuracy_text, move.max_range]
