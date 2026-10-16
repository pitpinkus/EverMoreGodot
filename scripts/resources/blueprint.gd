class_name Blueprint
extends Resource
## Recipe for one "New ..." entry of the editor's Evermore tools menu: which template
## to copy, where to save the copy, which GameDatabase list registers it and,
## optionally, an overworld NPC scene to create around it. Editor-only data
## (data/templates/), never loaded by the game.

## Menu text, e.g. "New Monster".
@export var label: String = ""
## Copied (with its built-in sub-resources) for every new entry.
@export var template: Resource
## Folder the copy is saved to as <id>.tres.
@export_dir var output_dir: String = ""
## GameDatabase array property the copy is appended to (species, moves, items).
## Empty = not registered (e.g. encounters).
@export var database_list: StringName

@export_group("NPC scene")
## When set, also creates an inherited scene of this prefab as <npc_scene_dir>/<id>.tscn.
@export var npc_base_scene: PackedScene
@export_dir var npc_scene_dir: String = ""
## Property of the NPC root that gets the new resource.
@export var npc_resource_property: StringName = &"encounter"
## Property of the NPC root that gets the new id (empty = none).
@export var npc_id_property: StringName = &"encounter_id"
