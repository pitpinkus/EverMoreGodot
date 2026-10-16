class_name MonsterSummaryPanel
extends PanelContainer
## Details of one monster (prefabs/ui/monster_summary_panel.tscn): name and level,
## element, every stat in %StatsGrid (name / value pairs) and its moves in %MovesList
## (one EntryRowContent each: element badge, name, power / accuracy / range). Display only.

## Theme variation of the stat name and value labels.
@export var stat_label_variation: StringName = &"SummaryStatLabel"
## Row instanced for each move; its root must be an EntryRowContent.
@export var move_row_scene: PackedScene

@onready var _name_label: Label = %NameLabel
@onready var _element_badge: ElementBadge = %ElementBadge
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _moves_list: VBoxContainer = %MovesList


func _ready() -> void:
	if move_row_scene == null:
		push_error("MonsterSummaryPanel '%s' has no move_row_scene assigned." % name)


func show_monster(monster: MonsterInstance) -> void:
	_name_label.text = monster.get_name_with_level()
	_element_badge.set_element(monster.species.element)
	_clear(_stats_grid)
	for stat: BattleTypes.Stat in BattleTypes.STAT_NAMES:
		_stats_grid.add_child(_make_label(BattleTypes.get_stat_name(stat)))
		_stats_grid.add_child(_make_label(str(monster.get_base_stat(stat))))
	_clear(_moves_list)
	if move_row_scene == null:
		return
	for move: MoveData in monster.moves:
		var row: EntryRowContent = move_row_scene.instantiate() as EntryRowContent
		_moves_list.add_child(row)
		row.set_content(move.display_name, MoveEntryBuilder.get_detail(move), move.element, true)


func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = stat_label_variation
	label.text = text
	return label


static func _clear(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
