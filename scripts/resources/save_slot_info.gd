class_name SaveSlotInfo
extends Resource
## Summary of one save slot, as shown in the Load menu. Filled by SaveSystem and
## stored as the header of each save file (see to_dict / from_dict).

const SECONDS_PER_MINUTE: int = 60
const SECONDS_PER_HOUR: int = 3600

const KEY_SLOT_ID: String = "slot_id"
const KEY_DISPLAY_NAME: String = "display_name"
const KEY_LEVEL_NAME: String = "level_name"
const KEY_LEVEL_PATH: String = "level_path"
const KEY_PLAYTIME_SECONDS: String = "playtime_seconds"
const KEY_SAVED_AT_UNIX: String = "saved_at_unix"

@export var slot_id: String = ""
@export var display_name: String = ""
@export var level_name: String = ""
## Scene file of the level the slot was saved in.
@export_file("*.tscn") var level_path: String = ""
@export_range(0.0, 1.0e7, 1.0, "or_greater", "suffix:s") var playtime_seconds: float = 0.0
## Unix time (UTC) when the slot was saved.
@export var saved_at_unix: int = 0


## Builds a SaveSlotInfo from to_dict() output. Missing or mistyped keys keep their defaults.
static func from_dict(data: Dictionary) -> SaveSlotInfo:
	var info: SaveSlotInfo = SaveSlotInfo.new()
	info.slot_id = _get_typed(data, KEY_SLOT_ID, info.slot_id)
	info.display_name = _get_typed(data, KEY_DISPLAY_NAME, info.display_name)
	info.level_name = _get_typed(data, KEY_LEVEL_NAME, info.level_name)
	info.level_path = _get_typed(data, KEY_LEVEL_PATH, info.level_path)
	info.playtime_seconds = _get_typed(data, KEY_PLAYTIME_SECONDS, info.playtime_seconds)
	info.saved_at_unix = _get_typed(data, KEY_SAVED_AT_UNIX, info.saved_at_unix)
	return info


## Plain-data copy for writing to a save file (no objects).
func to_dict() -> Dictionary:
	return {
		KEY_SLOT_ID: slot_id,
		KEY_DISPLAY_NAME: display_name,
		KEY_LEVEL_NAME: level_name,
		KEY_LEVEL_PATH: level_path,
		KEY_PLAYTIME_SECONDS: playtime_seconds,
		KEY_SAVED_AT_UNIX: saved_at_unix,
	}


## Playtime as H:MM:SS.
func get_playtime_text() -> String:
	var total: int = floori(playtime_seconds)
	return "%d:%02d:%02d" % [
		floori(total / float(SECONDS_PER_HOUR)),
		floori((total % SECONDS_PER_HOUR) / float(SECONDS_PER_MINUTE)),
		total % SECONDS_PER_MINUTE,
	]


## Save time in the player's local time zone, as YYYY-MM-DD HH:MM.
func get_saved_at_text() -> String:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var local: Dictionary = Time.get_datetime_dict_from_unix_time(saved_at_unix + bias_minutes * SECONDS_PER_MINUTE)
	return "%04d-%02d-%02d %02d:%02d" % [local.year, local.month, local.day, local.hour, local.minute]


## data[key] if it has the same type as fallback (an int is accepted for a float), else fallback.
static func _get_typed(data: Dictionary, key: String, fallback: Variant) -> Variant:
	var value: Variant = data.get(key, fallback)
	if typeof(value) == typeof(fallback):
		return value
	if value is int and fallback is float:
		return float(value)
	push_warning("SaveSlotInfo: '%s' is missing or has the wrong type; using default." % key)
	return fallback
