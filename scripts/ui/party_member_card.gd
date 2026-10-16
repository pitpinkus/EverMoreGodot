class_name PartyMemberCard
extends Button
## One party monster on the party screen (prefabs/ui/party_member_card.tscn): its
## %Portrait (MonsterPortrait), %ElementBadge and a MonsterStatusPanel (%StatusPanel).
## Focus and hover are handled by the PartyScreen.

var monster: MonsterInstance

@onready var _portrait: MonsterPortrait = %Portrait
@onready var _element_badge: ElementBadge = %ElementBadge
@onready var _status_panel: MonsterStatusPanel = %StatusPanel


func show_monster(party_monster: MonsterInstance) -> void:
	monster = party_monster
	_portrait.show_species(monster.species, monster.get_display_name())
	_element_badge.set_element(monster.species.element)
	_status_panel.show_monster(monster, [])
