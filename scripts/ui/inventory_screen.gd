class_name InventoryScreen
extends ScreenBase
## Overworld inventory. The inventory action opens it (only while the game is not
## paused) and closes it again. Pick an item in %ItemList, then the monster to use it
## on in %PartyList; the result is shown in %MessageLabel. ui_cancel steps back:
## party list -> item list -> closed. Pausing is done by its PauseWhileVisibleComponent.

const ITEMS_TITLE: String = "Items"
const PARTY_TITLE_FORMAT: String = "Use %s on"
const HP_FORMAT: String = "HP %d / %d"

var _items: Array[ChoiceEntry] = []
var _party: Array[ChoiceEntry] = []
var _selected_item: ItemData

@onready var _item_list: ChoiceListPanel = %ItemList
@onready var _party_list: ChoiceListPanel = %PartyList
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	_item_list.choice_finished.connect(_on_item_chosen)
	_party_list.choice_finished.connect(_on_party_member_chosen)
	PlayerProfile.party_changed.connect(_on_profile_changed)
	back_requested.connect(close)
	hide()


func open() -> void:
	_message_label.text = ""
	_show_items()
	super()


func close() -> void:
	_item_list.close()
	_party_list.close()
	super()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			get_viewport().set_input_as_handled()
			close()
		elif not get_tree().paused:
			get_viewport().set_input_as_handled()
			open()
		return
	super(event)


func _get_initial_focus() -> Control:
	var party_focus: Control = _party_list.get_focus_target()
	return party_focus if party_focus != null else _item_list.get_focus_target()


func _show_items() -> void:
	_party_list.close()
	_items = ItemEntryBuilder.build(PlayerProfile.inventory, ItemData.UseContext.OVERWORLD)
	_item_list.open(ITEMS_TITLE, _items)


func _show_party(item: ItemData) -> void:
	_selected_item = item
	_party.clear()
	for monster: MonsterInstance in PlayerProfile.party:
		var entry: ChoiceEntry = ChoiceEntry.new(monster.get_display_name(),
				HP_FORMAT % [monster.current_hp, monster.get_max_hp()], "", monster)
		if not PlayerProfile.can_use_item_outside_battle(item, monster):
			entry.disable(PlayerProfile.MESSAGE_NO_EFFECT)
		_party.append(entry)
	_party_list.open(PARTY_TITLE_FORMAT % item.display_name, _party)


func _on_item_chosen(index: int) -> void:
	if index < 0:
		close()
		return
	_show_party(_items[index].payload as ItemData)


func _on_party_member_chosen(index: int) -> void:
	if index >= 0:
		var monster: MonsterInstance = _party[index].payload as MonsterInstance
		_message_label.text = "\n".join(PlayerProfile.use_item_outside_battle(_selected_item, monster))
	_show_items()


## The profile was reset or loaded: lists built from the old party/inventory are stale.
func _on_profile_changed() -> void:
	if visible:
		_show_items()
