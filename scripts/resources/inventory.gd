class_name Inventory
extends Resource
## The player's items and how many of each. One inventory for battle and overworld.
## Saved as { item id: count } with to_dict() / from_dict(). Emits Resource.changed
## (emit_changed) whenever a count changes.

## Count per item, in the order items were first added. Never holds counts <= 0.
var counts: Dictionary[ItemData, int] = {}


## Builds an inventory from to_dict() output; unknown ids are skipped.
static func from_dict(data: Dictionary) -> Inventory:
	var inventory: Inventory = Inventory.new()
	for item_id: Variant in data:
		var item: ItemData = DataRegistry.get_item(StringName(str(item_id)))
		var count: Variant = data[item_id]
		if item != null and count is int:
			inventory.add(item, count)
	return inventory


## Adds up to amount (capped at item.max_stack). Returns how many were added.
func add(item: ItemData, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return 0
	var current: int = get_count(item)
	var added: int = mini(amount, item.max_stack - current)
	if added <= 0:
		return 0
	counts[item] = current + added
	emit_changed()
	return added


## Removes amount if that many are held. False (and nothing removed) otherwise.
func remove(item: ItemData, amount: int = 1) -> bool:
	var current: int = get_count(item)
	if amount <= 0 or current < amount:
		return false
	if current == amount:
		counts.erase(item)
	else:
		counts[item] = current - amount
	emit_changed()
	return true


func get_count(item: ItemData) -> int:
	return counts.get(item, 0)


## Held items, in the order they were first added.
func get_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	items.assign(counts.keys())
	return items


## Plain-data copy for saving.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for item: ItemData in counts:
		data[String(item.id)] = counts[item]
	return data
