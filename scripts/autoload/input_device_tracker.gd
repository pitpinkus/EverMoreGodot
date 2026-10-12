extends Node
## Autoload. Remembers whether the player last used keyboard/mouse or a gamepad,
## so UI can react (e.g. regrab focus when a gamepad takes over).

signal device_changed(device: Device)

enum Device { KEYBOARD_MOUSE, GAMEPAD }

var current_device: Device = Device.KEYBOARD_MOUSE


func _ready() -> void:
	# Keep tracking while the game is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var device: Device = current_device
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		device = Device.KEYBOARD_MOUSE
	elif InputBindings.is_deliberate_gamepad_event(event):
		device = Device.GAMEPAD
	if device != current_device:
		current_device = device
		device_changed.emit(device)
