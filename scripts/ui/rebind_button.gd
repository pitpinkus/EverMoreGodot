class_name RebindButton
extends Button
## Shows one binding (keyboard/mouse or gamepad) of an action. When pressed it
## listens for the next matching input and reports it through binding_captured.
## ui_cancel (from any device) or the timeout stops listening, so inputs bound to
## ui_cancel (Escape, gamepad B) can't be captured; "Reset controls" restores them.

signal binding_captured(event: InputEvent)

const LISTENING_VARIATION: StringName = &"RebindButtonListening"

## true: accepts gamepad buttons/axes. false: accepts keys and mouse buttons.
@export var gamepad_slot: bool = false
@export_range(1.0, 30.0, 0.5, "suffix:s") var listen_timeout: float = 5.0
@export var listening_text: String = "Press a key..."
@export var unbound_text: String = "Unbound"

var _event: InputEvent
var _listening: bool = false
## Increases every time listening starts, so stale timeouts can be ignored.
var _listen_id: int = 0
var _idle_variation: StringName = &""


func _ready() -> void:
	_idle_variation = theme_type_variation
	pressed.connect(_on_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_text()


## Displays the given binding (null = unbound).
func show_event(event: InputEvent) -> void:
	_event = event
	if not _listening:
		_refresh_text()


func _input(event: InputEvent) -> void:
	if not _listening or event is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_stop_listening()
	elif InputBindings.is_bindable(event, gamepad_slot):
		_stop_listening()
		binding_captured.emit(InputBindings.make_binding_event(event))


func _on_pressed() -> void:
	if _listening:
		return
	# Start next frame so the press that activated the button is not captured.
	await get_tree().process_frame
	_listening = true
	_listen_id += 1
	theme_type_variation = LISTENING_VARIATION
	text = listening_text
	get_tree().create_timer(listen_timeout).timeout.connect(_on_listen_timeout.bind(_listen_id))


func _on_listen_timeout(listen_id: int) -> void:
	if _listening and listen_id == _listen_id:
		_stop_listening()


func _on_visibility_changed() -> void:
	if _listening and not is_visible_in_tree():
		_stop_listening()


func _stop_listening() -> void:
	_listening = false
	theme_type_variation = _idle_variation
	_refresh_text()


func _refresh_text() -> void:
	text = unbound_text if _event == null else InputBindings.get_event_label(_event)
