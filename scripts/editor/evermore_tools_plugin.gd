@tool
extends EditorPlugin
## Editor-only. Adds Project > Tools > Evermore with one "New ..." entry per Blueprint
## in the catalog; each asks for a name, creates the content with BlueprintCreator,
## then rescans the FileSystem dock and opens the result.

const CATALOG_PATH: String = "res://data/templates/blueprint_catalog.tres"
const MENU_NAME: String = "Evermore"
const BlueprintCreator := preload("res://scripts/editor/blueprint_creator.gd")
const BlueprintNameDialog := preload("res://scripts/editor/blueprint_name_dialog.gd")

var _menu: PopupMenu
var _dialog: BlueprintNameDialog
var _creator: BlueprintCreator = BlueprintCreator.new()
var _catalog: BlueprintCatalog


func _enter_tree() -> void:
	_menu = PopupMenu.new()
	_menu.about_to_popup.connect(_rebuild_menu)
	_menu.id_pressed.connect(_on_menu_id_pressed)
	add_tool_submenu_item(MENU_NAME, _menu)
	_dialog = BlueprintNameDialog.new()
	_dialog.name_confirmed.connect(_on_name_confirmed)
	EditorInterface.get_base_control().add_child(_dialog)
	_rebuild_menu()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)
	_dialog.queue_free()


## The catalog is re-read on every open so edits to it show up without a restart.
func _rebuild_menu() -> void:
	_menu.clear()
	_catalog = load(CATALOG_PATH) as BlueprintCatalog
	if _catalog == null:
		push_error("Evermore tools: '%s' is missing or not a BlueprintCatalog." % CATALOG_PATH)
		return
	for index: int in _catalog.blueprints.size():
		var blueprint: Blueprint = _catalog.blueprints[index]
		if blueprint != null:
			_menu.add_item(blueprint.label, index)


func _on_menu_id_pressed(index: int) -> void:
	_dialog.open(_catalog.blueprints[index], _catalog.database)


func _on_name_confirmed(blueprint: Blueprint, id: String, display_name: String) -> void:
	var created: PackedStringArray = _creator.create(blueprint, _catalog.database, id, display_name)
	if created.is_empty():
		return
	EditorInterface.get_resource_filesystem().scan()
	var main_path: String = created[created.size() - 1]
	EditorInterface.select_file(main_path)
	if main_path.ends_with(BlueprintCreator.SCENE_EXTENSION):
		EditorInterface.open_scene_from_path(main_path)
	else:
		EditorInterface.edit_resource(load(main_path))
