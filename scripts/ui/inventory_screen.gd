class_name InventoryScreen
extends ScreenBase
## The overworld bag, a submenu of the pause menu (Bag tile, or the inventory action).
## Pick an item in the %Bag (pocket tabs), then the monster to use it on in
## %PartyList; the result is shown in %MessageLabel. ui_cancel steps back:
## party list -> bag -> closed.

const PARTY_TITLE_FORMAT: String = "Use %s on"

var _items: Array[ChoiceEntry] = []
var _party: Array[ChoiceEntry] = []
var _selected_item: ItemData

@onready var _bag: BagPanel = %Bag
@onready var _party_list: ChoiceListPanel = %PartyList
@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	super()
	_bag.choice_finished.connect(_on_item_chosen)
	_party_list.choice_finished.connect(_on_party_member_chosen)
	PlayerProfile.party_changed.connect(_on_profile_changed)
	back_requested.connect(close)
	hide()


func open() -> void:
	_message_label.text = ""
	_show_items()
	super()


func close() -> void:
	_bag.close()
	_party_list.close()
	super()


func _get_initial_focus() -> Control:
	var party_focus: Control = _party_list.get_focus_target()
	return party_focus if party_focus != null else _bag.get_focus_target()


func _show_items() -> void:
	_party_list.close()
	_items = ItemEntryBuilder.build(PlayerProfile.inventory, ItemData.UseContext.OVERWORLD)
	_bag.open(DataRegistry.get_pockets(), _items)


func _show_party(item: ItemData) -> void:
	_selected_item = item
	_party.clear()
	for monster: MonsterInstance in PlayerProfile.party:
		var entry: ChoiceEntry = ChoiceEntry.new(monster.get_display_name(), monster.get_hp_text(), "", monster)
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
