class_name PauseWhileVisibleComponent
extends Node
## Pauses the game while screen is visible and resumes it when screen hides again,
## restoring the mouse mode from before. Several screens can use it at once (pause
## menu over inventory): the game resumes when the last of them hides.
## Must be a child of (or below) screen so it connects before ScreenBase frees the mouse.

@export var screen: Control

## Screens currently holding the game paused, across all instances.
static var _paused_by: int = 0

var _holds_pause: bool = false
var _resume_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	if screen == null:
		push_error("PauseWhileVisibleComponent '%s' has no screen assigned." % name)
		return
	screen.visibility_changed.connect(_on_visibility_changed)
	if screen.is_visible_in_tree():
		_on_visibility_changed()


func _exit_tree() -> void:
	_release()


func _on_visibility_changed() -> void:
	if screen.is_visible_in_tree():
		_hold()
	else:
		_release()


func _hold() -> void:
	if _holds_pause:
		return
	_holds_pause = true
	_resume_mouse_mode = Input.mouse_mode
	_paused_by += 1
	GameFlow.pause_game()


func _release() -> void:
	if not _holds_pause:
		return
	_holds_pause = false
	Input.mouse_mode = _resume_mouse_mode
	_paused_by -= 1
	if _paused_by == 0:
		GameFlow.resume_game()
