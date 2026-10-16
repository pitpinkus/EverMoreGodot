class_name PartyScreen
extends ScreenBase
## Read-only view of the party (ui/screens/party_screen.tscn), a submenu of the pause
## menu: one PartyMemberCard per monster in %Cards; the focused (or hovered) card's
## details fill %Summary. ui_cancel closes it. Choosing a card does nothing yet.

@export var card_scene: PackedScene

var _cards: Array[PartyMemberCard] = []

@onready var _cards_box: Container = %Cards
@onready var _summary: MonsterSummaryPanel = %Summary


func _ready() -> void:
	super()
	if card_scene == null:
		push_error("PartyScreen '%s' has no card_scene assigned." % name)
	back_requested.connect(close)
	hide()


func open() -> void:
	_build_cards()
	super()


func _get_initial_focus() -> Control:
	return _cards[0] if not _cards.is_empty() else null


func _build_cards() -> void:
	for card: PartyMemberCard in _cards:
		_cards_box.remove_child(card)
		card.queue_free()
	_cards.clear()
	if card_scene == null:
		return
	for party_monster: MonsterInstance in PlayerProfile.party:
		var card: PartyMemberCard = card_scene.instantiate() as PartyMemberCard
		_cards_box.add_child(card)
		card.show_monster(party_monster)
		card.focus_entered.connect(_summary.show_monster.bind(party_monster))
		_cards.append(card)
	var controls: Array[Control] = []
	controls.assign(_cards)
	FocusUtils.setup_vertical_list(controls)
	if not _cards.is_empty():
		_summary.show_monster(_cards[0].monster)
	_summary.visible = not _cards.is_empty()
