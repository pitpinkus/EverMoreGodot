class_name EncounterNpc
extends Node3D
## Someone (or something) in the overworld that starts a battle when the player
## walks into its %EncounterTrigger: a wild monster, a trainer. Optionally disappears
## once its encounter has been won.

@export var encounter: Encounter
## Marked cleared when the player wins or captures; empty = repeatable.
@export var encounter_id: StringName
@export var despawn_when_cleared: bool = true

@onready var _trigger: EncounterTrigger = %EncounterTrigger


func _ready() -> void:
	_trigger.encounter = encounter
	_trigger.encounter_id = encounter_id
	_trigger.cleared.connect(_on_cleared)


func _on_cleared() -> void:
	if despawn_when_cleared:
		queue_free()
