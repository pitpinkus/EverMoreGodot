class_name SubmenuSwitcher
extends Node
## Swaps a menu's main button column for a submenu (any ScreenBase) and back.
## When the submenu closes, the column reappears and focus returns to the opener.

## The column of buttons hidden while a submenu is open.
@export var main_column: Control

var _open_submenu: ScreenBase


func _ready() -> void:
	if main_column == null:
		push_error("SubmenuSwitcher '%s' has no main_column assigned." % name)


## Hides main_column and opens submenu; opener gets focus back when it closes.
func open(submenu: ScreenBase, opener: Control) -> void:
	if _open_submenu != null:
		push_warning("SubmenuSwitcher '%s': a submenu is already open." % name)
		return
	_open_submenu = submenu
	main_column.hide()
	submenu.closed.connect(_on_submenu_closed.bind(opener), CONNECT_ONE_SHOT)
	submenu.open()


func is_open() -> bool:
	return _open_submenu != null


func _on_submenu_closed(opener: Control) -> void:
	_open_submenu = null
	main_column.show()
	if is_instance_valid(opener) and opener.is_visible_in_tree():
		opener.grab_focus()
