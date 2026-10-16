class_name ItemData
extends ActionData
## An inventory item (data/items/*.tres). usable_in = 0 makes it a key item.

enum UseContext { BATTLE = 1, OVERWORLD = 2 }

## Where the item can be used (UseContext flags).
@export_flags("Battle", "Overworld") var usable_in: int = UseContext.BATTLE | UseContext.OVERWORLD
@export var consumed_on_use: bool = true
@export_range(1, 999, 1) var max_stack: int = 99
## The bag tab it is listed under.
@export var pocket: ItemPocket


func is_usable_in(context: UseContext) -> bool:
	return usable_in & context != 0
