class_name GameSettings
extends Resource
## Every player-facing setting. Defaults live in data/settings/default_settings.tres;
## SettingsManager applies an instance and saves it to user://.

enum WindowMode { WINDOWED, BORDERLESS, FULLSCREEN }
enum TextSpeed { SLOW, NORMAL, FAST, INSTANT }

@export_group("Audio")
@export_range(0.0, 1.0, 0.01) var master_volume: float = 1.0
@export_range(0.0, 1.0, 0.01) var music_volume: float = 1.0
@export_range(0.0, 1.0, 0.01) var sfx_volume: float = 1.0
@export_range(0.0, 1.0, 0.01) var ui_volume: float = 1.0
@export var muted: bool = false

@export_group("Display")
@export var window_mode: WindowMode = WindowMode.WINDOWED
## Window size; only used in WINDOWED mode.
@export var resolution: Vector2i = Vector2i(1280, 720)
@export var vsync: bool = true
## 0 = unlimited.
@export_range(0, 1000, 1, "suffix:fps") var max_fps: int = 0
@export_range(0.5, 1.0, 0.05) var render_scale: float = 1.0
## Index into DisplayOptions.quality_presets.
@export_range(0, 16, 1) var quality_preset: int = 0
@export_range(0.5, 1.5, 0.01) var brightness: float = 1.0

@export_group("Gameplay")
@export var text_speed: TextSpeed = TextSpeed.NORMAL
## Multiplier on mouse and stick camera look speed.
@export_range(0.1, 3.0, 0.05) var camera_sensitivity: float = 1.0
@export var invert_camera_y: bool = false
@export var battle_animations: bool = true

@export_group("Controls")
## Action name -> full event list that replaces the project.godot default.
## Actions not listed use their defaults.
@export var input_overrides: Dictionary[StringName, Array] = {}
