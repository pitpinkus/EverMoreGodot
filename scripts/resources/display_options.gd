class_name DisplayOptions
extends Resource
## Choices offered by the display settings (resolutions, FPS caps, quality presets).

## fps_caps entry meaning "no cap" (same convention as Engine.max_fps).
const UNLIMITED_FPS: int = 0

@export var resolutions: Array[Vector2i] = []
## UNLIMITED_FPS = no cap.
@export var fps_caps: PackedInt32Array = PackedInt32Array()
@export var unlimited_fps_label: String = "Unlimited"
## Format for resolution entries, filled with width and height.
@export var resolution_format: String = "%d x %d"
@export var quality_presets: Array[QualityPreset] = []


## Preset at index, clamped into range. Null only when the list is empty.
func get_quality_preset(index: int) -> QualityPreset:
	if quality_presets.is_empty():
		return null
	return quality_presets[clampi(index, 0, quality_presets.size() - 1)]


func get_resolution_labels() -> PackedStringArray:
	var labels: PackedStringArray = PackedStringArray()
	for size: Vector2i in resolutions:
		labels.append(resolution_format % [size.x, size.y])
	return labels


func get_fps_labels() -> PackedStringArray:
	var labels: PackedStringArray = PackedStringArray()
	for cap: int in fps_caps:
		labels.append(unlimited_fps_label if cap == UNLIMITED_FPS else str(cap))
	return labels


func get_quality_labels() -> PackedStringArray:
	var labels: PackedStringArray = PackedStringArray()
	for preset: QualityPreset in quality_presets:
		labels.append(preset.display_name)
	return labels
