class_name ItemEntryBuilder
extends RefCounted
## Builds the item list rows shared by the battle item menu and the inventory screen.

const COUNT_FORMAT: String = "x%d"
const NOT_HERE_REASON: String = "This can't be used here."


## One entry per held item (payload = ItemData). Items not usable in context stay
## listed but disabled.
static func build(inventory: Inventory, context: ItemData.UseContext) -> Array[ChoiceEntry]:
	var entries: Array[ChoiceEntry] = []
	for item: ItemData in inventory.get_items():
		var entry: ChoiceEntry = ChoiceEntry.new(item.display_name, COUNT_FORMAT % inventory.get_count(item),
				item.description, item)
		if not item.is_usable_in(context):
			entry.disable(NOT_HERE_REASON)
		entries.append(entry)
	return entries
