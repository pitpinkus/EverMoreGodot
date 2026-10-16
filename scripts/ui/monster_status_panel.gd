class_name MonsterStatusPanel
extends PanelContainer
## Name, level, HP bar and statuses of one battle unit. Highlighted while it is the
## unit whose turn it is (BattlePanelActive theme variation).

const NAME_FORMAT: String = "%s  Lv %d"
const HP_FORMAT: String = "%d / %d"
const STATUS_SEPARATOR: String = ", "
const VARIATION: StringName = &"BattlePanel"
const ACTIVE_VARIATION: StringName = &"BattlePanelActive"

@onready var _name_label: Label = %NameLabel
@onready var _hp_bar: Range = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	# The bar shows the HP ratio (0..1).
	_hp_bar.max_value = 1.0


func bind(unit: BattleMonster) -> void:
	_name_label.text = NAME_FORMAT % [unit.instance.get_display_name(), unit.instance.level]
	unit.hp_changed.connect(_on_hp_changed.bind(unit.instance))
	unit.statuses_changed.connect(_on_statuses_changed)
	_on_hp_changed(unit.instance.current_hp, unit.instance.get_max_hp(), unit.instance)
	_on_statuses_changed(unit.get_status_holder().get_statuses())
	set_active(false)


func set_active(active: bool) -> void:
	theme_type_variation = ACTIVE_VARIATION if active else VARIATION


func _on_hp_changed(current: int, maximum: int, monster: MonsterInstance) -> void:
	_hp_bar.value = monster.get_hp_ratio()
	_hp_label.text = HP_FORMAT % [current, maximum]


func _on_statuses_changed(statuses: Array[StatusEffectData]) -> void:
	var names: PackedStringArray = []
	for status: StatusEffectData in statuses:
		names.append(status.display_name)
	_status_label.text = STATUS_SEPARATOR.join(names)
