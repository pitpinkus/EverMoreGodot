class_name PlayerBattleController
extends BattleController
## The player's side: shows the command menu on the BattleHud and turns the choice
## into a BattleDecision, using the BattleCursor to pick walk destinations and
## targets. Fight lists the unit's moves, Bag opens the pocketed bag, Monsters shows
## the own side read-only. ui_cancel at any step goes back to the command menu.

const MOVES_TITLE: String = "Fight"
const MONSTERS_TITLE: String = "Monsters"
const STAT_FORMAT: String = "%s %d"
## Joins the HP / status part of a monster row and the stats in its description.
const PART_SEPARATOR: String = " · "
const NO_TARGET_REASON: String = "No target in range."
const COMMAND_HINT: String = "Choose a command."
const MOVE_HINT: String = "Point inside the highlighted area and confirm to walk there; cancel to go back."
const TARGET_HINT: String = "Point at a target or use left / right, confirm to use; cancel to go back."
## Hint shown for each BattleCursor.RejectReason.
const REJECT_HINTS: Dictionary[BattleCursor.RejectReason, String] = {
	BattleCursor.RejectReason.TOO_CLOSE: "Too close - point further away to walk there.",
	BattleCursor.RejectReason.UNREACHABLE: "Can't walk there - point inside the highlighted area.",
}
const CHOICE_HINT: String = "Choose, or cancel to go back."
const MONSTERS_HINT: String = "Your monsters. Cancel to go back."

@export var hud: BattleHud
@export var cursor: BattleCursor


func _ready() -> void:
	if hud == null or cursor == null:
		push_error("PlayerBattleController '%s' needs hud and cursor assigned." % name)
		return
	cursor.point_rejected.connect(_on_point_rejected)


func decide(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	while true:
		hud.set_hint(COMMAND_HINT)
		hud.set_steps_left(battle.steps_left(unit))
		hud.show_commands(_get_enabled_commands(unit, battle))
		var command: BattleHud.Command = await hud.command_chosen
		var decision: BattleDecision = null
		match command:
			BattleHud.Command.MOVE:
				decision = await _choose_destination(unit, battle)
			BattleHud.Command.FIGHT:
				decision = await _choose_action(unit, battle, MoveEntryBuilder.build(unit.instance.moves),
						func(entries: Array[ChoiceEntry]) -> void: hud.show_choices(MOVES_TITLE, entries))
			BattleHud.Command.BAG:
				decision = await _choose_action(unit, battle,
						ItemEntryBuilder.build(PlayerProfile.inventory, ItemData.UseContext.BATTLE),
						func(entries: Array[ChoiceEntry]) -> void: hud.show_bag(DataRegistry.get_pockets(), entries))
			BattleHud.Command.MONSTERS:
				await _show_monsters(unit, battle)
			BattleHud.Command.RUN:
				decision = BattleDecision.flee()
			BattleHud.Command.END_TURN:
				decision = BattleDecision.end_turn()
		if decision != null:
			hud.set_hint("")
			return decision
	return BattleDecision.end_turn()


func _get_enabled_commands(unit: BattleMonster, battle: BattleManager) -> Dictionary[BattleHud.Command, bool]:
	var can_act: bool = not battle.has_acted(unit)
	return {
		BattleHud.Command.MOVE: battle.steps_left(unit) >= battle.get_rules().min_move_distance,
		BattleHud.Command.FIGHT: can_act and not unit.instance.moves.is_empty(),
		BattleHud.Command.BAG: can_act and not PlayerProfile.inventory.get_items().is_empty(),
		BattleHud.Command.MONSTERS: true,
		BattleHud.Command.RUN: can_act and battle.can_flee(),
		BattleHud.Command.END_TURN: true,
	}


## MOVE decision for a picked point, or null if cancelled.
func _choose_destination(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	hud.set_hint(MOVE_HINT)
	var area: ReachableArea = battle.get_navigator().compute_reachable(unit.global_position, battle.steps_left(unit))
	cursor.pick_point(unit.global_position, area, battle.get_rules().min_move_distance)
	var picked: Array = await cursor.point_picked
	return BattleDecision.move_to(picked[1]) if picked[0] else null


## Lets the player pick one entry (payload = ActionData) from the list show_list opens
## (it receives the entries), then a target. Null if cancelled.
func _choose_action(unit: BattleMonster, battle: BattleManager, entries: Array[ChoiceEntry],
		show_list: Callable) -> BattleDecision:
	for entry: ChoiceEntry in entries:
		if entry.enabled and battle.get_targeting().get_valid_targets(unit, entry.payload as ActionData).is_empty():
			entry.disable(NO_TARGET_REASON)
	hud.set_hint(CHOICE_HINT)
	show_list.call(entries)
	var index: int = await hud.choice_finished
	if index < 0:
		return null
	var action: ActionData = entries[index].payload as ActionData
	var targets: Array[BattleMonster] = battle.get_targeting().get_valid_targets(unit, action)
	if action.target_kind == BattleTypes.TargetKind.SELF:
		return BattleDecision.use(action, unit)
	hud.set_hint(TARGET_HINT)
	cursor.pick_unit(targets)
	var target: BattleMonster = await cursor.unit_picked
	return BattleDecision.use(action, target) if target != null else null


## Read-only list of the living monsters on unit's side; returns when it is closed.
func _show_monsters(unit: BattleMonster, battle: BattleManager) -> void:
	var entries: Array[ChoiceEntry] = []
	for ally: BattleMonster in battle.get_roster().get_allies(unit):
		entries.append(_make_monster_entry(ally))
	hud.set_hint(MONSTERS_HINT)
	hud.show_choices(MONSTERS_TITLE, entries)
	await hud.choice_finished


## Row text: name and level; detail: HP and statuses; description: current stats.
static func _make_monster_entry(ally: BattleMonster) -> ChoiceEntry:
	var monster: MonsterInstance = ally.instance
	var detail: PackedStringArray = [monster.get_hp_text()]
	var statuses: String = MonsterStatusPanel.join_status_names(ally.get_status_holder().get_statuses())
	if not statuses.is_empty():
		detail.append(statuses)
	var stats: PackedStringArray = []
	for stat: BattleTypes.Stat in BattleTypes.STAT_ABBREVIATIONS:
		if stat != BattleTypes.Stat.HP:
			stats.append(STAT_FORMAT % [BattleTypes.get_stat_abbreviation(stat), ally.get_stat(stat)])
	var entry: ChoiceEntry = ChoiceEntry.new(monster.get_name_with_level(),
			PART_SEPARATOR.join(detail), PART_SEPARATOR.join(stats), ally)
	entry.element = monster.species.element
	return entry


func _on_point_rejected(reason: BattleCursor.RejectReason) -> void:
	hud.set_hint(REJECT_HINTS[reason])
