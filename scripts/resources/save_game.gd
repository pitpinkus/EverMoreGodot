class_name SaveGame
extends Resource
## One save slot's contents and its on-disk format. Knows nothing about scenes:
## SaveSystem fills state (SaveSystem.set_state) and progress (SaveSystem.save_progress)
## and calls write().
##
## Every file holds two sections, header then body:
##   header: { KEY_FORMAT_VERSION: int, KEY_INFO: SaveSlotInfo.to_dict() }
##   body:   { KEY_STATE: { &"<key>": plain-data }, KEY_PROGRESS: { &"<key>": plain-data } }
## Older formats are upgraded on read by _migrate().
## The file extension picks the encoding, for writing and reading alike:
##   ENCRYPTED_EXTENSION: FileAccess.open_encrypted_with_pass, one store_var per
##     section, read back with get_var(false).
##   READABLE_EXTENSION: UTF-8 text for debugging. Each section is a marker line
##     (HEADER_MARKER / BODY_MARKER) followed by var_to_str() of the value, with
##     LINE_PREFIX in front of every line. A value can't start a line itself, so it
##     can never be mistaken for a marker, even if it contains line breaks.

const FORMAT_VERSION: int = 2
const FIRST_FORMAT_VERSION: int = 1
## Format that split the body into state and progress.
const STATE_PROGRESS_FORMAT_VERSION: int = 2
## Appended to the target path while writing; renamed over the real file when complete.
const TEMP_SUFFIX: String = ".tmp"
const ENCRYPTED_EXTENSION: String = "sav"
const READABLE_EXTENSION: String = "txt"

const HEADER_MARKER: String = "[header]"
const BODY_MARKER: String = "[body]"
const LINE_PREFIX: String = "\t"
## str_to_var() would build Objects or load Resources (which can run code) from
## these constructors, so readable sections containing them are rejected unparsed.
const UNSAFE_TEXT_PATTERN: String = "(Object|Resource)\\s*\\("
## Variant types that are not plain data and can't be saved.
const UNSAFE_TYPES: Array[Variant.Type] = [TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID]

const KEY_FORMAT_VERSION: String = "format_version"
const KEY_INFO: String = "info"
const KEY_STATE: String = "state"
const KEY_PROGRESS: String = "progress"
## Format 1 body key; its dictionary became KEY_STATE in format 2.
const V1_KEY_DATA: String = "data"

## Compiled UNSAFE_TEXT_PATTERN, built once.
static var _unsafe_text_regex: RegEx = RegEx.create_from_string(UNSAFE_TEXT_PATTERN)

@export var info: SaveSlotInfo
## Snapshot state by key (SaveSystem.set_state). Plain data only (see is_plain_data).
@export var state: Dictionary[StringName, Variant] = {}
## Progress by key (SaveSystem.save_progress / unlock). Plain data only.
@export var progress: Dictionary[StringName, Variant] = {}


## True if value holds no Object, Callable, Signal or RID at any depth.
static func is_plain_data(value: Variant) -> bool:
	if UNSAFE_TYPES.has(typeof(value)):
		return false
	if value is Array:
		for item: Variant in value:
			if not is_plain_data(item):
				return false
	elif value is Dictionary:
		for item_key: Variant in value:
			if not is_plain_data(item_key) or not is_plain_data(value[item_key]):
				return false
	return true


## True if path has one of the save file extensions.
static func is_save_path(path: String) -> bool:
	return path.get_extension() in [ENCRYPTED_EXTENSION, READABLE_EXTENSION]


## Reads only the header of the save file at path. Null if unreadable, invalid or from a newer game version.
## password is only used for encrypted files.
static func read_info(path: String, password: String) -> SaveSlotInfo:
	var file: FileAccess = _open(path, FileAccess.READ, _is_readable(path), password)
	if file == null:
		return null
	var header: Dictionary = _read_header(file, path)
	if header.is_empty():
		return null
	return SaveSlotInfo.from_dict(header[KEY_INFO])


## Reads the whole save file at path. Null on any error. password is only used for encrypted files.
static func read(path: String, password: String) -> SaveGame:
	var file: FileAccess = _open(path, FileAccess.READ, _is_readable(path), password)
	if file == null:
		return null
	var header: Dictionary = _read_header(file, path)
	if header.is_empty():
		return null
	var body: Variant = _read_section(file, path, BODY_MARKER)
	if not body is Dictionary:
		push_warning("SaveGame: '%s' has no valid body; skipped." % path)
		return null
	var migrated: Dictionary = _migrate(body, header[KEY_FORMAT_VERSION])
	var save: SaveGame = SaveGame.new()
	save.info = SaveSlotInfo.from_dict(header[KEY_INFO])
	if not _read_keyed(migrated, KEY_STATE, save.state, path):
		return null
	if not _read_keyed(migrated, KEY_PROGRESS, save.progress, path):
		return null
	return save


## Writes this save to path, crash-safe: a temp file is written first, then renamed over path.
## The extension of path picks the encoding; password is only used for encrypted files.
func write(path: String, password: String) -> Error:
	if info == null:
		push_error("SaveGame: cannot write '%s' without info." % path)
		return ERR_INVALID_DATA
	var readable: bool = _is_readable(path)
	var temp_path: String = path + TEMP_SUFFIX
	var file: FileAccess = _open(temp_path, FileAccess.WRITE, readable, password)
	if file == null:
		return FileAccess.get_open_error()
	_write_section(file, readable, HEADER_MARKER, { KEY_FORMAT_VERSION: FORMAT_VERSION, KEY_INFO: info.to_dict() })
	_write_section(file, readable, BODY_MARKER, { KEY_STATE: state, KEY_PROGRESS: progress })
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		push_error("SaveGame: could not write '%s' (%s)." % [temp_path, error_string(error)])
		return error
	error = DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_error("SaveGame: could not replace '%s' (%s)." % [path, error_string(error)])
	return error


## Copies body[key] (a Dictionary, missing = empty) into target with StringName keys. False if invalid.
static func _read_keyed(body: Dictionary, key: String, target: Dictionary[StringName, Variant], path: String) -> bool:
	var stored: Variant = body.get(key, {})
	if not stored is Dictionary:
		push_warning("SaveGame: '%s' has an invalid '%s' entry; skipped." % [path, key])
		return false
	for item_key: Variant in stored:
		target[StringName(str(item_key))] = stored[item_key]
	return true


static func _is_readable(path: String) -> bool:
	return path.get_extension() == READABLE_EXTENSION


## Opens path as text (readable) or encrypted with password.
static func _open(path: String, flags: FileAccess.ModeFlags, readable: bool, password: String) -> FileAccess:
	var file: FileAccess
	if readable:
		file = FileAccess.open(path, flags)
	else:
		file = FileAccess.open_encrypted_with_pass(path, flags, password)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		push_error("SaveGame: could not open '%s' (%s)." % [path, error_string(error)])
	return file


static func _write_section(file: FileAccess, readable: bool, marker: String, value: Dictionary) -> void:
	if not readable:
		file.store_var(value)
		return
	file.store_line(marker)
	for line: String in var_to_str(value).split("\n"):
		file.store_line(LINE_PREFIX + line)


## Next section of file as a plain-data Variant, or null if missing, unsafe or invalid.
static func _read_section(file: FileAccess, path: String, marker: String) -> Variant:
	var value: Variant = _read_text_section(file, path, marker) if _is_readable(path) else file.get_var(false)
	if not is_plain_data(value):
		push_warning("SaveGame: '%s' section %s holds non-plain data; skipped." % [path, marker])
		return null
	return value


static func _read_text_section(file: FileAccess, path: String, marker: String) -> Variant:
	var marker_line: String = file.get_line()
	while marker_line.is_empty() and not file.eof_reached():
		marker_line = file.get_line()
	if marker_line != marker:
		push_warning("SaveGame: '%s' is missing the %s line." % [path, marker])
		return null
	var lines: PackedStringArray = []
	while not file.eof_reached():
		var line_start: int = file.get_position()
		var line: String = file.get_line()
		if not line.begins_with(LINE_PREFIX):
			file.seek(line_start)
			break
		lines.append(line.substr(LINE_PREFIX.length()))
	var text: String = "\n".join(lines)
	if _unsafe_text_regex.search(text) != null:
		push_warning("SaveGame: '%s' section %s contains an Object or Resource constructor; skipped." % [path, marker])
		return null
	return str_to_var(text)


## Reads and validates the header. Empty if invalid or written by a newer format.
static func _read_header(file: FileAccess, path: String) -> Dictionary:
	var header: Variant = _read_section(file, path, HEADER_MARKER)
	if not header is Dictionary \
			or not header.get(KEY_FORMAT_VERSION) is int \
			or not header.get(KEY_INFO) is Dictionary:
		push_warning("SaveGame: '%s' has no valid header; skipped." % path)
		return {}
	var version: int = header[KEY_FORMAT_VERSION]
	if version > FORMAT_VERSION:
		push_warning("SaveGame: '%s' uses format %d, newer than supported %d; skipped." % [path, version, FORMAT_VERSION])
		return {}
	if version < FIRST_FORMAT_VERSION:
		push_warning("SaveGame: '%s' has invalid format version %d; skipped." % [path, version])
		return {}
	return header


## Upgrades a body written by format from_version to FORMAT_VERSION, one step per version.
static func _migrate(body: Dictionary, from_version: int) -> Dictionary:
	var migrated: Dictionary = body
	if from_version < STATE_PROGRESS_FORMAT_VERSION:
		migrated = { KEY_STATE: body.get(V1_KEY_DATA, {}), KEY_PROGRESS: {} }
	return migrated
