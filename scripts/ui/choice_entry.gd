class_name ChoiceEntry
extends RefCounted
## One row of a ChoiceListPanel: what it shows and what it stands for.

var text: String = ""
## Short extra info shown on the right of the row (count, accuracy, ...).
var detail: String = ""
## Shown while the row is focused or hovered.
var description: String = ""
var enabled: bool = true
## Shown instead of the description when a disabled row is pressed.
var disabled_reason: String = ""
## What the row stands for (an ItemData, a MonsterInstance, ...).
var payload: Variant


func _init(entry_text: String = "", entry_detail: String = "", entry_description: String = "",
		entry_payload: Variant = null) -> void:
	text = entry_text
	detail = entry_detail
	description = entry_description
	payload = entry_payload


## Marks the entry unavailable with reason.
func disable(reason: String) -> void:
	enabled = false
	disabled_reason = reason
