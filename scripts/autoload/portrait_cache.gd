extends Node
## Autoload. Face portraits of monster species for the UI (turn timeline, party).
## A species' icon is used when set; otherwise its model is photographed once by a
## PortraitStudio and the result is kept for the session. get_portrait() answers at
## once: a texture, or null while the portrait is still being made (portrait_ready
## follows). Without a display (headless) no portraits are made and everything is null.

signal portrait_ready(species_id: StringName, texture: Texture2D)

## The studio prefab, loaded by path so the autoload works without it (no portraits then).
const STUDIO_SCENE_PATH: String = "res://prefabs/ui/portrait_studio.tscn"
const HEADLESS_DISPLAY: String = "headless"

var _studio: PortraitStudio
var _cache: Dictionary[StringName, Texture2D] = {}
## Species whose model could not be photographed; not tried again.
var _failed: Dictionary[StringName, bool] = {}
var _queue: Array[SpeciesData] = []
var _rendering: bool = false


func _ready() -> void:
	# Portraits keep coming while the game is paused (pause menu party view).
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == HEADLESS_DISPLAY:
		return
	_studio = OptionalScene.add_to(self, STUDIO_SCENE_PATH, PortraitStudio, true) as PortraitStudio


## species' icon, its cached portrait, or null (a portrait is then queued and announced
## with portrait_ready).
func get_portrait(species: SpeciesData) -> Texture2D:
	if species == null:
		return null
	if species.icon != null:
		return species.icon
	if _cache.has(species.id):
		return _cache[species.id]
	_request(species)
	return null


## Queues portraits for species that have none yet (e.g. while a battle fades in).
func prewarm(species_list: Array[SpeciesData]) -> void:
	for species: SpeciesData in species_list:
		get_portrait(species)


func _request(species: SpeciesData) -> void:
	if _studio == null or _failed.has(species.id) or _queue.has(species):
		return
	_queue.append(species)
	if not _rendering:
		_render_queue()


func _render_queue() -> void:
	_rendering = true
	while not _queue.is_empty():
		var species: SpeciesData = _queue.pop_front()
		if _cache.has(species.id):
			continue
		var texture: Texture2D = await _studio.render(species)
		if texture == null:
			_failed[species.id] = true
			continue
		_cache[species.id] = texture
		portrait_ready.emit(species.id, texture)
	_rendering = false
