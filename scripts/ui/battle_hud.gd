class_name BattleHud
extends Control
## Battle screen overlay: unit status panels, the command menu, the move/item list,
## the message log, whose turn it is, the upcoming turn order and an input hint.
## Shows what it is told and reports choices through signals; it makes no battle
## decisions.

signal command_chosen(command: Command)
## Picked index in the list from show_choices, or -1 if cancelled.
signal choice_finished(index: int)

enum Command { MOVE, ATTACK, ITEM, RUN, END_TURN }

const TURN_FORMAT: String = "%s's turn"

@export var status_panel_scene: PackedScene

var _panels: Dictionary[BattleMonster, MonsterStatusPanel] = {}

@onready var _player_panels: Container = %PlayerPanels
@onready var _enemy_panels: Container = %EnemyPanels
@onready var _command_menu: Control = %CommandMenu
@onready var _choice_list: ChoiceListPanel = %ChoiceList
@onready var _battle_log: BattleLog = %BattleLog
@onready var _turn_label: Label = %TurnLabel
@onready var _hint_label: Label = %HintLabel
@onready var _turn_timeline: TurnTimelineBar = %TurnTimeline
@onready var _command_buttons: Dictionary[Command, Button] = {
	Command.MOVE: %MoveButton,
	Command.ATTACK: %AttackButton,
	Command.ITEM: %ItemButton,
	Command.RUN: %RunButton,
	Command.END_TURN: %EndTurnButton,
}


func _ready() -> void:
	if status_panel_scene == null:
		push_error("BattleHud '%s' has no status_panel_scene assigned." % name)
	for command: Command in _command_buttons:
		_command_buttons[command].pressed.connect(_on_command_pressed.bind(command))
	_choice_list.choice_finished.connect(choice_finished.emit)
	_command_menu.hide()
	_hint_label.text = ""
	_turn_label.text = ""


## Creates a status panel for every unit.
func bind_units(player_units: Array[BattleMonster], enemy_units: Array[BattleMonster]) -> void:
	for unit: BattleMonster in player_units:
		_add_panel(unit, _player_panels)
	for unit: BattleMonster in enemy_units:
		_add_panel(unit, _enemy_panels)


## Shows the command menu; commands mapped to false are disabled. Focuses the first enabled one.
func show_commands(enabled: Dictionary[Command, bool]) -> void:
	var focus_order: Array[Control] = []
	for command: Command in _command_buttons:
		var button: Button = _command_buttons[command]
		button.disabled = not enabled.get(command, false)
		FocusUtils.set_focusable(button, not button.disabled)
		if not button.disabled:
			focus_order.append(button)
	_command_menu.show()
	if not focus_order.is_empty():
		FocusUtils.wrap_vertical(focus_order)
		focus_order[0].grab_focus.call_deferred()


func hide_commands() -> void:
	_command_menu.hide()


## Opens the shared list with entries; the result arrives as choice_finished.
func show_choices(title: String, entries: Array[ChoiceEntry]) -> void:
	_choice_list.open(title, entries)


func log_message(text: String) -> void:
	_battle_log.add_message(text)


func set_hint(text: String) -> void:
	_hint_label.text = text


## Highlights unit's panel and names it in the turn label.
func set_active_unit(unit: BattleMonster) -> void:
	for panel_unit: BattleMonster in _panels:
		_panels[panel_unit].set_active(panel_unit == unit)
	_turn_label.text = TURN_FORMAT % unit.instance.get_display_name()


## Shows the upcoming turn order; acting (null between turns) is highlighted if listed first.
func set_timeline(units: Array[BattleMonster], acting: BattleMonster) -> void:
	_turn_timeline.set_order(units, acting)


## How many upcoming turns the timeline shows.
func get_timeline_length() -> int:
	return _turn_timeline.get_length()


func _add_panel(unit: BattleMonster, container: Container) -> void:
	var panel: MonsterStatusPanel = status_panel_scene.instantiate() as MonsterStatusPanel
	container.add_child(panel)
	panel.bind(unit)
	_panels[unit] = panel


func _on_command_pressed(command: Command) -> void:
	hide_commands()
	command_chosen.emit(command)
