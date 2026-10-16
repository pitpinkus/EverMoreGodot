@tool
extends RefCounted
## Editor-only. Makes new content from a Blueprint: copies its template under a new
## snake_case id, saves it, registers it in the GameDatabase and, for NPC blueprints,
## creates an inherited scene of the NPC prefab that uses it. Knows nothing about
## editor UI, so it can also be driven from a script.

const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
const RESOURCE_EXTENSION: String = ".tres"
const SCENE_EXTENSION: String = ".tscn"

var _id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)


## Why id can't be used for blueprint, or "" if it can.
func validate_id(blueprint: Blueprint, database: GameDatabase, id: String) -> String:
	if _id_regex.search(id) == null:
		return "Use snake_case: lowercase letters, digits and _, starting with a letter."
	var paths: PackedStringArray = [get_resource_path(blueprint, id)]
	if blueprint.npc_base_scene != null:
		paths.append(get_scene_path(blueprint, id))
	for path: String in paths:
		if FileAccess.file_exists(path):
			return "%s already exists." % path
	for entry: Resource in _get_database_list(blueprint, database):
		if entry != null and entry.get(&"id") == StringName(id):
			return "The database already has '%s' in %s." % [id, blueprint.database_list]
	return ""


func get_resource_path(blueprint: Blueprint, id: String) -> String:
	return blueprint.output_dir.path_join(id + RESOURCE_EXTENSION)


func get_scene_path(blueprint: Blueprint, id: String) -> String:
	return blueprint.npc_scene_dir.path_join(id + SCENE_EXTENSION)


## Creates everything blueprint describes for id. Returns the created file paths
## (resource first, then the NPC scene if any); empty if something failed (logged).
func create(blueprint: Blueprint, database: GameDatabase, id: String, display_name: String) -> PackedStringArray:
	var created: PackedStringArray = []
	var problem: String = validate_id(blueprint, database, id)
	if not problem.is_empty():
		push_error("Blueprint '%s': %s" % [blueprint.label, problem])
		return created
	if blueprint.template == null:
		push_error("Blueprint '%s' has no template." % blueprint.label)
		return created
	var resource: Resource = blueprint.template.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
	if &"id" in resource:
		resource.set(&"id", StringName(id))
	if &"display_name" in resource:
		resource.set(&"display_name", display_name)
	var resource_path: String = get_resource_path(blueprint, id)
	if not _save_as(resource, resource_path):
		return created
	created.append(resource_path)
	if not blueprint.database_list.is_empty() and not _register(blueprint, database, resource):
		return created
	if blueprint.npc_base_scene != null:
		var scene_path: String = get_scene_path(blueprint, id)
		if _create_npc_scene(blueprint, id, resource, scene_path):
			created.append(scene_path)
	return created


## The GameDatabase array blueprint registers in, or null if there is none.
func _find_database_list(blueprint: Blueprint, database: GameDatabase) -> Variant:
	if blueprint.database_list.is_empty() or database == null:
		return null
	var list: Variant = database.get(blueprint.database_list)
	return list if list is Array else null


func _get_database_list(blueprint: Blueprint, database: GameDatabase) -> Array:
	var list: Variant = _find_database_list(blueprint, database)
	return list if list != null else []


func _register(blueprint: Blueprint, database: GameDatabase, resource: Resource) -> bool:
	var list: Variant = _find_database_list(blueprint, database)
	if list == null:
		push_error("Blueprint '%s': GameDatabase has no list '%s'." % [blueprint.label, blueprint.database_list])
		return false
	(list as Array).append(resource)
	return _save(database)


## Writes an inherited scene of the NPC prefab (its root is instance= the prefab, so
## prefab changes still apply) that only overrides the new resource and id, then
## checks that it loads as a scene inheriting the prefab.
func _create_npc_scene(blueprint: Blueprint, id: String, resource: Resource, path: String) -> bool:
	var base_path: String = blueprint.npc_base_scene.resource_path
	var lines: PackedStringArray = [
		"[gd_scene format=3]",
		"",
		"[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]" % base_path,
		"[ext_resource type=\"Resource\" path=\"%s\" id=\"2_resource\"]" % resource.resource_path,
		"",
		"[node name=\"%s\" instance=ExtResource(\"1_base\")]" % id.to_pascal_case(),
		"%s = ExtResource(\"2_resource\")" % blueprint.npc_resource_property,
	]
	if not blueprint.npc_id_property.is_empty():
		lines.append("%s = %s" % [blueprint.npc_id_property, var_to_str(StringName(id))])
	lines.append("")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Blueprint: could not write '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string("\n".join(lines))
	file.close()
	var scene: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	var base_state: SceneState = scene.get_state().get_base_scene_state() if scene != null else null
	if base_state == null or base_state.get_path() != base_path:
		push_error("Blueprint '%s': %s does not load as a scene inheriting %s." % [blueprint.label, path, base_path])
		return false
	return true


## Saves resource as path and makes path its own, so later references (database,
## NPC scene) point to the file instead of embedding a copy.
func _save_as(resource: Resource, path: String) -> bool:
	resource.take_over_path(path)
	return _save(resource)


func _save(resource: Resource) -> bool:
	var error: Error = ResourceSaver.save(resource)
	if error != OK:
		push_error("Blueprint: could not save '%s' (%s)." % [resource.resource_path, error_string(error)])
		return false
	return true
