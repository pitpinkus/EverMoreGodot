extends Node
## Autoload. Lists, writes and reads save games.
## Stub: saving is not implemented yet. Real saves will live in user://saves/,
## one file per slot, and list_saves() will read their headers.


## Every existing save slot, newest first. Empty until saving is implemented.
func list_saves() -> Array[SaveSlotInfo]:
	return []
