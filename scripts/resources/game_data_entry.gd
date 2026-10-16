class_name GameDataEntry
extends Resource
## Base of every piece of content DataRegistry looks up by id (species, moves, items,
## statuses). It only holds the shared id and name, so the registry can index all kinds
## with one typed helper. This is why MoveData / ItemData are three levels deep
## (GameDataEntry > ActionData > MoveData): this level adds no behaviour.

## Unique within its kind (moves and items have separate id spaces). Saves store it.
@export var id: StringName
@export var display_name: String = ""
