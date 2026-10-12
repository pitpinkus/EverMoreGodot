class_name SaveSlotFiles
extends RefCounted
## Static helpers for the slot files in SAVE_DIR: which slots exist, where a slot's
## file is, free slot numbers, and housekeeping. Used by SaveSystem; holds no state.
## Each slot is one SaveGame file, named <slot_id>.<extension>, where the extension
## is SaveGame.ENCRYPTED_EXTENSION or SaveGame.READABLE_EXTENSION.

const SAVE_DIR: String = "user://saves/"
const SLOT_ID_FORMAT: String = "slot_%03d"
const FIRST_SLOT_NUMBER: int = 1


## Ids of every slot with a file in either format, each listed once.
static func get_existing_slot_ids() -> Array[String]:
	var slot_ids: Array[String] = []
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return slot_ids
	for file_name: String in DirAccess.get_files_at(SAVE_DIR):
		var slot_id: String = file_name.get_basename()
		if SaveGame.is_save_path(file_name) and not slot_ids.has(slot_id):
			slot_ids.append(slot_id)
	return slot_ids


## Lowest slot number whose file does not exist yet, in either format.
static func find_free_slot_number() -> int:
	var existing: Array[String] = get_existing_slot_ids()
	var number: int = FIRST_SLOT_NUMBER
	while existing.has(get_slot_id(number)):
		number += 1
	return number


static func get_slot_id(number: int) -> String:
	return SLOT_ID_FORMAT % number


static func get_slot_path(slot_id: String, extension: String) -> String:
	return SAVE_DIR + slot_id + "." + extension


## Extension new saves get: encrypted or readable.
static func get_write_extension(encrypt: bool) -> String:
	return SaveGame.ENCRYPTED_EXTENSION if encrypt else SaveGame.READABLE_EXTENSION


## Existing file of slot_id. If it exists in both formats, the newer save wins.
## password is needed to read encrypted headers.
static func find_slot_path(slot_id: String, password: String) -> String:
	var encrypted_path: String = get_slot_path(slot_id, SaveGame.ENCRYPTED_EXTENSION)
	var readable_path: String = get_slot_path(slot_id, SaveGame.READABLE_EXTENSION)
	var has_encrypted: bool = FileAccess.file_exists(encrypted_path)
	if not FileAccess.file_exists(readable_path):
		return encrypted_path
	if not has_encrypted:
		return readable_path
	push_warning("SaveSlotFiles: slot '%s' exists encrypted and readable; using the newer one." % slot_id)
	return readable_path if _get_saved_at(readable_path, password) >= _get_saved_at(encrypted_path, password) else encrypted_path


## After a save in the encrypt format, deletes the slot's file in the other format: it is an older version.
static func remove_other_format(slot_id: String, encrypt: bool) -> void:
	var other_path: String = get_slot_path(slot_id, get_write_extension(not encrypt))
	if not FileAccess.file_exists(other_path):
		return
	var error: Error = DirAccess.remove_absolute(other_path)
	if error != OK:
		push_warning("SaveSlotFiles: could not remove old '%s' (%s)." % [other_path, error_string(error)])


static func ensure_save_dir() -> Error:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return OK
	var error: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if error != OK:
		push_error("SaveSlotFiles: could not create '%s' (%s)." % [SAVE_DIR, error_string(error)])
	return error


## saved_at_unix of the file at path, or -1 if unreadable.
static func _get_saved_at(path: String, password: String) -> int:
	var info: SaveSlotInfo = SaveGame.read_info(path, password)
	return info.saved_at_unix if info != null else -1
