class_name MonsterPortrait
extends PanelContainer
## A monster's face in a frame (prefabs/ui/monster_portrait.tscn): the species portrait
## from PortraitCache in %Icon, or the monster's first letter in %Initial until (or
## unless) there is one. Swaps the face in when PortraitCache finishes it.
## Used by TurnSlot and PartyMemberCard.

## Size of the face (and of the letter shown instead).
@export var portrait_size: Vector2 = Vector2(36.0, 36.0)
## Theme type variation of the first-letter fallback.
@export var initial_variation: StringName = &"TurnSlotInitial"

var _species: SpeciesData
var _display_name: String = ""

@onready var _icon: TextureRect = %Icon
@onready var _initial: Label = %Initial


func _ready() -> void:
	_icon.custom_minimum_size = portrait_size
	_initial.custom_minimum_size = portrait_size
	_initial.theme_type_variation = initial_variation
	PortraitCache.portrait_ready.connect(_on_portrait_ready)
	_refresh()


## Shows species' portrait, falling back to display_name's first letter. May be called
## before the portrait is in the tree.
func show_species(species: SpeciesData, display_name: String) -> void:
	_species = species
	_display_name = display_name
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_initial.text = _display_name.left(1).to_upper()
	_show(PortraitCache.get_portrait(_species) if _species != null else null)


func _show(texture: Texture2D) -> void:
	_icon.texture = texture
	_icon.visible = texture != null
	_initial.visible = texture == null


func _on_portrait_ready(species_id: StringName, texture: Texture2D) -> void:
	if _species != null and _species.id == species_id:
		_show(texture)
