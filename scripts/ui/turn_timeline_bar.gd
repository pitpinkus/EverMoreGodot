class_name TurnTimelineBar
extends PanelContainer
## The upcoming turn order as a column of TurnSlots in %Slots, the unit acting now
## first (in a bigger current_slot_scene slot). Slot nodes are created once and reused.
## Display only (no focus, no mouse).

@export var slot_scene: PackedScene
## Scene of the first slot (the unit acting now or next). Null = slot_scene.
@export var current_slot_scene: PackedScene
## How many upcoming turns are shown.
@export_range(1, 20, 1) var slot_count: int = 8

var _slots: Array[TurnSlot] = []

@onready var _slot_container: Container = %Slots


func _ready() -> void:
	if slot_scene == null:
		push_error("TurnTimelineBar '%s' has no slot_scene assigned." % name)
		return
	for index: int in slot_count:
		var scene: PackedScene = current_slot_scene if index == 0 and current_slot_scene != null else slot_scene
		var slot: TurnSlot = scene.instantiate() as TurnSlot
		_slot_container.add_child(slot)
		slot.hide()
		_slots.append(slot)


## Shows units in order; unused slots are hidden. The first slot is highlighted only
## when it is acting (a unit that fainted on its own turn is no longer listed).
func set_order(units: Array[BattleMonster], acting: BattleMonster) -> void:
	for index: int in _slots.size():
		var slot: TurnSlot = _slots[index]
		slot.visible = index < units.size()
		if slot.visible:
			slot.set_unit(units[index], index == 0 and units[index] == acting)


## Number of turns this bar can show.
func get_length() -> int:
	return slot_count
