class_name SaveSlotInfo
extends Resource
## Summary of one save slot, as shown in the Load menu. Filled by SaveSystem.

const SECONDS_PER_MINUTE: int = 60
const SECONDS_PER_HOUR: int = 3600

@export var slot_id: String = ""
@export var display_name: String = ""
@export var level_name: String = ""
@export_range(0.0, 1.0e7, 1.0, "or_greater", "suffix:s") var playtime_seconds: float = 0.0
## Unix time (UTC) when the slot was saved.
@export var saved_at_unix: int = 0


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
