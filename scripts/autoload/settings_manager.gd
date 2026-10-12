extends Node
## Autoload. Owns the active GameSettings: loads defaults + the player's saved file,
## applies them to audio, display and input, and saves them back.

signal settings_applied(settings: GameSettings)

const DEFAULTS_PATH: String = "res://data/settings/default_settings.tres"
const DISPLAY_OPTIONS_PATH: String = "res://data/settings/display_options.tres"
const SAVE_PATH: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "settings"
const CONTROLS_SECTION: String = "controls"
## Saved in CONTROLS_SECTION instead of SETTINGS_SECTION.
const OVERRIDES_PROPERTY: StringName = &"input_overrides"

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const UI_BUS: StringName = &"UI"

const SHADOW_16_BITS_SETTING: String = "rendering/lights_and_shadows/directional_shadow/16_bits"

## The settings currently in effect. Treat as read-only; change settings via apply().
var current: GameSettings
## Choices for the display settings; quality_preset indexes into its presets.
var display_options: DisplayOptions

var _defaults: GameSettings


func _ready() -> void:
	_defaults = load(DEFAULTS_PATH) as GameSettings
	if _defaults == null:
		push_error("SettingsManager: '%s' is missing or not a GameSettings." % DEFAULTS_PATH)
		_defaults = GameSettings.new()
	display_options = load(DISPLAY_OPTIONS_PATH) as DisplayOptions
	if display_options == null:
		push_error("SettingsManager: '%s' is missing or not a DisplayOptions." % DISPLAY_OPTIONS_PATH)
		display_options = DisplayOptions.new()
	var settings: GameSettings = get_defaults()
	_load_saved(settings)
	apply(settings)


## A fresh, editable copy of the default settings.
func get_defaults() -> GameSettings:
	return _defaults.duplicate(true) as GameSettings


## Makes a copy of settings the current settings and pushes it to every system.
func apply(settings: GameSettings) -> void:
	current = settings.duplicate(true) as GameSettings
	_apply_audio(current)
	_apply_display(current)
	InputBindings.apply_overrides(current.input_overrides)
	settings_applied.emit(current)


## Writes the current settings to SAVE_PATH.
func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for property: StringName in _get_setting_names():
		config.set_value(SETTINGS_SECTION, property, current.get(property))
	for action: StringName in current.input_overrides:
		config.set_value(CONTROLS_SECTION, action, current.input_overrides[action])
	var error: Error = config.save(SAVE_PATH)
	if error != OK:
		push_error("SettingsManager: could not save '%s' (%s)." % [SAVE_PATH, error_string(error)])


func _load_saved(settings: GameSettings) -> void:
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("SettingsManager: could not read '%s' (%s); using defaults." % [SAVE_PATH, error_string(error)])
		return
	_load_settings_section(config, settings)
	_load_controls_section(config, settings)


func _load_settings_section(config: ConfigFile, settings: GameSettings) -> void:
	if not config.has_section(SETTINGS_SECTION):
		return
	var names: Array[StringName] = _get_setting_names()
	for key: String in config.get_section_keys(SETTINGS_SECTION):
		if not names.has(StringName(key)):
			push_warning("SettingsManager: unknown setting '%s' in save file ignored." % key)
			continue
		var value: Variant = config.get_value(SETTINGS_SECTION, key)
		if typeof(value) != typeof(settings.get(key)):
			push_warning("SettingsManager: setting '%s' has the wrong type in save file; keeping default." % key)
			continue
		settings.set(key, value)


func _load_controls_section(config: ConfigFile, settings: GameSettings) -> void:
	if not config.has_section(CONTROLS_SECTION):
		return
	for action: String in config.get_section_keys(CONTROLS_SECTION):
		var value: Variant = config.get_value(CONTROLS_SECTION, action)
		if not InputBindings.is_project_action(action) or not value is Array:
			push_warning("SettingsManager: invalid binding '%s' in save file ignored." % action)
			continue
		settings.input_overrides[StringName(action)] = InputBindings.to_event_array(value)


## Names of every saved GameSettings property except the input overrides.
func _get_setting_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for property: Dictionary in GameSettings.new().get_property_list():
		var usage: int = property["usage"]
		var property_name: StringName = property["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property_name != OVERRIDES_PROPERTY:
			names.append(property_name)
	return names


func _apply_audio(settings: GameSettings) -> void:
	_set_bus_volume(MASTER_BUS, settings.master_volume)
	_set_bus_volume(MUSIC_BUS, settings.music_volume)
	_set_bus_volume(SFX_BUS, settings.sfx_volume)
	_set_bus_volume(UI_BUS, settings.ui_volume)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), settings.muted)


func _set_bus_volume(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("SettingsManager: audio bus '%s' not found in the bus layout." % bus)
		return
	AudioServer.set_bus_volume_linear(index, linear)


func _apply_display(settings: GameSettings) -> void:
	var window: Window = get_window()
	match settings.window_mode:
		GameSettings.WindowMode.BORDERLESS:
			window.mode = Window.MODE_FULLSCREEN
		GameSettings.WindowMode.FULLSCREEN:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		_:
			window.mode = Window.MODE_WINDOWED
			window.size = settings.resolution
			window.move_to_center()
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = settings.max_fps

	var viewport: Viewport = get_viewport()
	viewport.scaling_3d_scale = settings.render_scale
	var preset: QualityPreset = display_options.get_quality_preset(settings.quality_preset)
	if preset == null:
		push_warning("SettingsManager: no quality presets in '%s'." % DISPLAY_OPTIONS_PATH)
		return
	viewport.msaa_3d = preset.msaa_3d
	viewport.screen_space_aa = preset.screen_space_aa
	viewport.use_taa = preset.use_taa
	RenderingServer.directional_shadow_atlas_set_size(
		preset.directional_shadow_size, ProjectSettings.get_setting(SHADOW_16_BITS_SETTING)
	)
