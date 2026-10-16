class_name EncounterNpc
extends Node3D
## Someone (or something) in the overworld that starts a battle when the player
## walks into its %EncounterTrigger: a wild monster, a trainer. Optionally disappears
## once its encounter has been won. With show_encounter_species it shows the model of
## the encounter's preview species in %Visual (wild monsters).

@export var encounter: Encounter
## Marked cleared when the player wins or captures; empty = repeatable.
@export var encounter_id: StringName
@export var despawn_when_cleared: bool = true
## Put the encounter's preview species model into %Visual.
@export var show_encounter_species: bool = false

@onready var _trigger: EncounterTrigger = %EncounterTrigger


func _ready() -> void:
	_trigger.encounter = encounter
	_trigger.encounter_id = encounter_id
	_trigger.cleared.connect(_on_cleared)
	if show_encounter_species:
		_show_species_model()


func _show_species_model() -> void:
	var species: SpeciesData = encounter.get_preview_species() if encounter != null else null
	if species == null:
		push_warning("EncounterNpc '%s': show_encounter_species is on but the encounter has no preview species." % name)
		return
	var model: MonsterModel = species.instantiate_model()
	if model != null:
		(%Visual as Node3D).add_child(model)


func _on_cleared() -> void:
	if despawn_when_cleared:
		queue_free()
