class_name EnvironmentSettingsComponent
extends Node
## Applies player display settings (brightness) to a WorldEnvironment, now and
## whenever SettingsManager applies new settings.

@export var world_environment: WorldEnvironment


func _ready() -> void:
	if world_environment == null:
		push_error("EnvironmentSettingsComponent '%s' has no world_environment assigned." % name)
		return
	SettingsManager.settings_applied.connect(_on_settings_applied)
	_on_settings_applied(SettingsManager.current)


func _on_settings_applied(settings: GameSettings) -> void:
	var environment: Environment = world_environment.environment
	if environment == null:
		push_warning("EnvironmentSettingsComponent '%s': WorldEnvironment has no Environment." % name)
		return
	environment.adjustment_enabled = true
	environment.adjustment_brightness = settings.brightness
