extends Node
## Autoload. Helpers for player-rebindable InputMap actions: applying overrides,
## reading defaults, editing event lists and turning events into labels.
## An override is the full event list of one action (see GameSettings.input_overrides).

const PROJECT_INPUT_PREFIX: String = "input/"
const PROJECT_EVENTS_KEY: String = "events"
## Joypad axis motion stronger than this counts as deliberate input (not stick drift).
const JOYPAD_MOTION_THRESHOLD: float = 0.5
## InputEvent.device value that matches every device (InputMap.ALL_DEVICES in the engine).
const ALL_DEVICES: int = -1

const MOUSE_BUTTON_LABELS: Dictionary[MouseButton, String] = {
	MOUSE_BUTTON_LEFT: "Left Click",
	MOUSE_BUTTON_RIGHT: "Right Click",
	MOUSE_BUTTON_MIDDLE: "Middle Click",
	MOUSE_BUTTON_WHEEL_UP: "Wheel Up",
	MOUSE_BUTTON_WHEEL_DOWN: "Wheel Down",
	MOUSE_BUTTON_WHEEL_LEFT: "Wheel Left",
	MOUSE_BUTTON_WHEEL_RIGHT: "Wheel Right",
	MOUSE_BUTTON_XBUTTON1: "Mouse Back",
	MOUSE_BUTTON_XBUTTON2: "Mouse Forward",
}

const JOY_BUTTON_LABELS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

## Axis -> [label for the negative direction, label for the positive direction].
const JOY_AXIS_LABELS: Dictionary[JoyAxis, Array] = {
	JOY_AXIS_LEFT_X: ["Left Stick Left", "Left Stick Right"],
	JOY_AXIS_LEFT_Y: ["Left Stick Up", "Left Stick Down"],
	JOY_AXIS_RIGHT_X: ["Right Stick Left", "Right Stick Right"],
	JOY_AXIS_RIGHT_Y: ["Right Stick Up", "Right Stick Down"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"],
	JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}


## Resets the InputMap to project.godot, then replaces each overridden action's events.
func apply_overrides(overrides: Dictionary[StringName, Array]) -> void:
	InputMap.load_from_project_settings()
	for action: StringName in overrides:
		if not InputMap.has_action(action):
			push_warning("InputBindings: override for unknown action '%s' ignored." % action)
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in to_event_array(overrides[action]):
			InputMap.action_add_event(action, event)


## Whether project.godot defines this action.
func is_project_action(action: StringName) -> bool:
	return ProjectSettings.has_setting(PROJECT_INPUT_PREFIX + action)


## Events defined for the action in project.godot.
func get_default_events(action: StringName) -> Array[InputEvent]:
	if not is_project_action(action):
		push_warning("InputBindings: '%s' is not an action in project.godot." % action)
		return []
	var entry: Dictionary = ProjectSettings.get_setting(PROJECT_INPUT_PREFIX + action)
	return to_event_array(entry.get(PROJECT_EVENTS_KEY, []))


## The override for the action if there is one, otherwise its defaults.
func get_events(overrides: Dictionary[StringName, Array], action: StringName) -> Array[InputEvent]:
	if overrides.has(action):
		return to_event_array(overrides[action])
	return get_default_events(action)


## Stores events as the action's override, or removes the override if they equal the defaults.
func set_override(overrides: Dictionary[StringName, Array], action: StringName, events: Array[InputEvent]) -> void:
	if _same_events(events, get_default_events(action)):
		overrides.erase(action)
	else:
		overrides[action] = events.duplicate()


## Typed copy of an untyped array, keeping only InputEvents.
func to_event_array(values: Array) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for value: Variant in values:
		if value is InputEvent:
			events.append(value)
	return events


func is_gamepad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


## Gamepad button event, or axis motion past JOYPAD_MOTION_THRESHOLD.
func is_deliberate_gamepad_event(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > JOYPAD_MOTION_THRESHOLD
	return event is InputEventJoypadButton


## First event of the given device class (gamepad or keyboard/mouse), or null.
func get_first_event(events: Array[InputEvent], gamepad: bool) -> InputEvent:
	for event: InputEvent in events:
		if is_gamepad_event(event) == gamepad:
			return event
	return null


## Copy of events where the first event of the given device class is replaced by
## new_event (or new_event is appended if that class has none).
func replace_event(events: Array[InputEvent], new_event: InputEvent, is_gamepad: bool) -> Array[InputEvent]:
	var result: Array[InputEvent] = events.duplicate()
	for i: int in result.size():
		if is_gamepad_event(result[i]) == is_gamepad:
			result[i] = new_event
			return result
	result.append(new_event)
	return result


## Copy of events without any event matching the given one.
func remove_event(events: Array[InputEvent], event: InputEvent) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for existing: InputEvent in events:
		if not existing.is_match(event):
			result.append(existing)
	return result


## First action in actions (other than ignore_action) already bound to event, or &"".
func find_conflict(overrides: Dictionary[StringName, Array], event: InputEvent, actions: Array[StringName], ignore_action: StringName) -> StringName:
	for action: StringName in actions:
		if action == ignore_action:
			continue
		for existing: InputEvent in get_events(overrides, action):
			if existing.is_match(event):
				return action
	return &""


## Whether a pressed event can become a binding for the given device class.
func is_bindable(event: InputEvent, gamepad: bool) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if gamepad:
		return is_deliberate_gamepad_event(event)
	return event is InputEventKey or event is InputEventMouseButton


## Device-independent copy of a captured event, suitable for storing as a binding.
## Returns null for events that can't be bindings.
func make_binding_event(event: InputEvent) -> InputEvent:
	var binding: InputEvent = null
	if event is InputEventKey:
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = (event as InputEventKey).physical_keycode
		binding = key
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.button_index = (event as InputEventMouseButton).button_index
		binding = mouse
	elif event is InputEventJoypadButton:
		var button: InputEventJoypadButton = InputEventJoypadButton.new()
		button.button_index = (event as InputEventJoypadButton).button_index
		binding = button
	elif event is InputEventJoypadMotion:
		var source: InputEventJoypadMotion = event as InputEventJoypadMotion
		var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
		motion.axis = source.axis
		motion.axis_value = signf(source.axis_value)
		binding = motion
	if binding != null:
		binding.device = ALL_DEVICES
	return binding


## Human-readable name for a binding, using the current keyboard layout for keys.
func get_event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.physical_keycode == KEY_NONE:
			return OS.get_keycode_string(key.keycode)
		# Without keyboard layouts (e.g. headless) fall back to the US-layout name.
		if DisplayServer.keyboard_get_layout_count() == 0:
			return key.as_text_physical_keycode()
		return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode))
	if event is InputEventMouseButton:
		var mouse_button: MouseButton = (event as InputEventMouseButton).button_index
		if MOUSE_BUTTON_LABELS.has(mouse_button):
			return MOUSE_BUTTON_LABELS[mouse_button]
	elif event is InputEventJoypadButton:
		var joy_button: JoyButton = (event as InputEventJoypadButton).button_index
		if JOY_BUTTON_LABELS.has(joy_button):
			return JOY_BUTTON_LABELS[joy_button]
	elif event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if JOY_AXIS_LABELS.has(motion.axis):
			var labels: Array = JOY_AXIS_LABELS[motion.axis]
			return labels[1 if motion.axis_value > 0.0 else 0]
	return event.as_text()


func _same_events(a: Array[InputEvent], b: Array[InputEvent]) -> bool:
	if a.size() != b.size():
		return false
	for i: int in a.size():
		if not a[i].is_match(b[i]):
			return false
	return true
