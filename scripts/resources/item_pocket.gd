class_name ItemPocket
extends GameDataEntry
## One pocket (tab) of the bag (data/items/pockets/*.tres). Every ItemData names its pocket.

@export var icon: Texture2D
## Tabs are shown from low to high order.
@export var order: int = 0
