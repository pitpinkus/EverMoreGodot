class_name MonsterStatusPanel
extends PanelContainer
## Name, level, HP bar and statuses of one monster. show_monster() fills it once
## (party screen); bind() follows a battle unit's HP and statuses. set_active switches
## between the normal and active theme variations (e.g. the unit whose turn it is).

const HP_FORMAT: String = "%d / %d"
const STATUS_SEPARATOR: String = ", "

@export var normal_variation: StringName = &"BattlePanel"
@export var active_variation: StringName = &"BattlePanelActive"

@onready var _name_label: Label = %NameLabel
@onready var _hp_bar: Range = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	# The bar shows the HP ratio (0..1).
	_hp_bar.max_value = 1.0


## Shows monster with statuses (none outside battle).
func show_monster(monster: MonsterInstance, statuses: Array[StatusEffectData]) -> void:
	_name_label.text = monster.get_name_with_level()
	_on_hp_changed(monster.current_hp, monster.get_max_hp(), monster)
	_on_statuses_changed(statuses)
	set_active(false)


## Shows unit and keeps following its HP and statuses.
func bind(unit: BattleMonster) -> void:
	show_monster(unit.instance, unit.get_status_holder().get_statuses())
	unit.hp_changed.connect(_on_hp_changed.bind(unit.instance))
	unit.statuses_changed.connect(_on_statuses_changed)


func set_active(active: bool) -> void:
	theme_type_variation = active_variation if active else normal_variation


func _on_hp_changed(current: int, maximum: int, monster: MonsterInstance) -> void:
	_hp_bar.value = monster.get_hp_ratio()
	_hp_label.text = HP_FORMAT % [current, maximum]


func _on_statuses_changed(statuses: Array[StatusEffectData]) -> void:
	_status_label.text = join_status_names(statuses)


## Status names separated by commas (empty without statuses).
static func join_status_names(statuses: Array[StatusEffectData]) -> String:
	var names: PackedStringArray = []
	for status: StatusEffectData in statuses:
		names.append(status.display_name)
	return STATUS_SEPARATOR.join(names)
