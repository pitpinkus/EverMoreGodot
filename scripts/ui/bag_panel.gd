class_name BagPanel
extends VBoxContainer
## The bag (prefabs/ui/bag_panel.tscn): a %PocketTabs TabBar above a ChoiceListPanel
## (%ItemList) showing the items of the selected pocket. Tabs switch with
## ui_tab_prev / ui_tab_next (Q/E, LB/RB) or a click. Used by the overworld bag and the
## battle Bag. Entries come from ItemEntryBuilder (payload = ItemData); the answer is
## choice_finished with the index into the entries given to open(), or -1 if cancelled.
## Hides itself once answered.

signal choice_finished(entry_index: int)

var _pockets: Array[ItemPocket] = []
var _entries: Array[ChoiceEntry] = []
## Index into _entries for every row currently in the list.
var _shown: Array[int] = []
## Kept between opens, so the bag reopens on the pocket last used (if it still has items).
var _pocket_index: int = 0

@onready var _tabs: TabBar = %PocketTabs
@onready var _item_list: ChoiceListPanel = %ItemList


func _ready() -> void:
	_tabs.tab_changed.connect(_on_tab_changed)
	_item_list.choice_finished.connect(_on_item_chosen)
	hide()


## Shows entries sorted into one tab per pocket and focuses the first row. Opens on the
## pocket last used, or the first pocket with items if that one is empty.
func open(pockets: Array[ItemPocket], entries: Array[ChoiceEntry]) -> void:
	_pockets = pockets
	_entries = entries
	_pocket_index = _pick_start_pocket()
	# Rebuilding the tabs emits tab_changed; the list is built once below instead.
	_tabs.set_block_signals(true)
	_tabs.clear_tabs()
	for pocket: ItemPocket in pockets:
		_tabs.add_tab(pocket.display_name, pocket.icon)
	if not pockets.is_empty():
		_tabs.current_tab = _pocket_index
	_tabs.set_block_signals(false)
	show()
	_show_pocket()


## Hides the bag without emitting choice_finished.
func close() -> void:
	_item_list.close()
	hide()


## The control that should hold focus, or null.
func get_focus_target() -> Control:
	return _item_list.get_focus_target() if visible else null


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _pockets.is_empty():
		return
	var step: int = 0
	if event.is_action_pressed("ui_tab_next"):
		step = 1
	elif event.is_action_pressed("ui_tab_prev"):
		step = -1
	if step != 0:
		get_viewport().set_input_as_handled()
		_tabs.current_tab = wrapi(_tabs.current_tab + step, 0, _pockets.size())


func _show_pocket() -> void:
	var pocket: ItemPocket = _pockets[_pocket_index] if not _pockets.is_empty() else null
	_shown = _get_entry_indices(pocket)
	var rows: Array[ChoiceEntry] = []
	for index: int in _shown:
		rows.append(_entries[index])
	_item_list.open(pocket.display_name if pocket != null else "", rows)


## The remembered pocket if it has entries, else the first pocket that has some.
func _pick_start_pocket() -> int:
	var remembered: int = clampi(_pocket_index, 0, maxi(0, _pockets.size() - 1))
	if _pockets.is_empty() or not _get_entry_indices(_pockets[remembered]).is_empty():
		return remembered
	for index: int in _pockets.size():
		if not _get_entry_indices(_pockets[index]).is_empty():
			return index
	return remembered


## Indices into _entries of the items in pocket.
func _get_entry_indices(pocket: ItemPocket) -> Array[int]:
	var indices: Array[int] = []
	for index: int in _entries.size():
		var item: ItemData = _entries[index].payload as ItemData
		if item != null and item.pocket == pocket:
			indices.append(index)
	return indices


func _on_tab_changed(tab: int) -> void:
	_pocket_index = tab
	if visible:
		_show_pocket()


func _on_item_chosen(index: int) -> void:
	hide()
	choice_finished.emit(_shown[index] if index >= 0 else -1)
