@tool
extends ConfirmationDialog
## Editor-only. Asks for the display name and id of new content made from a
## Blueprint. One-off editor UI built in code (not game UI, so no theme/prefab).
## The id follows the name until edited; OK stays disabled while the id is invalid.

signal name_confirmed(blueprint: Blueprint, id: String, display_name: String)

const BlueprintCreator := preload("res://scripts/editor/blueprint_creator.gd")

var _creator: BlueprintCreator = BlueprintCreator.new()
var _blueprint: Blueprint
var _database: GameDatabase
var _id_edited: bool = false
var _name_edit: LineEdit = LineEdit.new()
var _id_edit: LineEdit = LineEdit.new()
var _problem_label: Label = Label.new()


func _init() -> void:
	var fields: VBoxContainer = VBoxContainer.new()
	_add_field(fields, "Display name", _name_edit)
	_add_field(fields, "Id (snake_case, file name)", _id_edit)
	fields.add_child(_problem_label)
	add_child(fields)
	register_text_enter(_name_edit)
	register_text_enter(_id_edit)
	_name_edit.text_changed.connect(_on_name_changed)
	_id_edit.text_changed.connect(_on_id_changed)
	confirmed.connect(_on_confirmed)


## Shows the dialog for blueprint; new entries are checked against database.
func open(blueprint: Blueprint, database: GameDatabase) -> void:
	_blueprint = blueprint
	_database = database
	_id_edited = false
	title = blueprint.label
	_name_edit.text = ""
	_id_edit.text = ""
	_validate()
	popup_centered()
	_name_edit.grab_focus()


func _add_field(parent: Container, caption: String, edit: LineEdit) -> void:
	var label: Label = Label.new()
	label.text = caption
	parent.add_child(label)
	parent.add_child(edit)


func _validate() -> void:
	_problem_label.text = _creator.validate_id(_blueprint, _database, _id_edit.text)
	get_ok_button().disabled = not _problem_label.text.is_empty()


func _on_name_changed(new_text: String) -> void:
	if not _id_edited:
		_id_edit.text = new_text.strip_edges().to_snake_case().replace(" ", "_")
	_validate()


func _on_id_changed(_new_text: String) -> void:
	_id_edited = true
	_validate()


func _on_confirmed() -> void:
	var display_name: String = _name_edit.text.strip_edges()
	if display_name.is_empty():
		display_name = _id_edit.text.capitalize()
	name_confirmed.emit(_blueprint, _id_edit.text, display_name)
