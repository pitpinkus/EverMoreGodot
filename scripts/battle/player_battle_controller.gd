class_name PlayerBattleController
extends BattleController
## The player's side: shows the command menu on the BattleHud and turns the choice
## into a BattleDecision, using the BattleCursor to pick walk destinations and
## targets. ui_cancel at any step goes back to the command menu.

const MOVES_TITLE: String = "Moves"
const ITEMS_TITLE: String = "Items"
const MOVE_DETAIL_FORMAT: String = "Acc %d%%  Range %.0fm"
const NO_TARGET_REASON: String = "No target in range."
const COMMAND_HINT: String = "Choose a command."
const MOVE_HINT: String = "Point at the ground (mouse or stick) and confirm to walk there; cancel to go back."
const TARGET_HINT: String = "Point at a target or use left / right, confirm to use; cancel to go back."
const TOO_CLOSE_HINT: String = "Too close - point further away to walk there."
const CHOICE_HINT: String = "Choose, or cancel to go back."

@export var hud: BattleHud
@export var cursor: BattleCursor


func _ready() -> void:
	if hud == null or cursor == null:
		push_error("PlayerBattleController '%s' needs hud and cursor assigned." % name)
		return
	cursor.point_rejected.connect(hud.set_hint.bind(TOO_CLOSE_HINT))


func decide(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	while true:
		hud.set_hint(COMMAND_HINT)
		hud.show_commands(_get_enabled_commands(unit, battle))
		var command: BattleHud.Command = await hud.command_chosen
		var decision: BattleDecision = null
		match command:
			BattleHud.Command.MOVE:
				decision = await _choose_destination(unit, battle)
			BattleHud.Command.ATTACK:
				decision = await _choose_action(unit, battle, MOVES_TITLE, _build_move_entries(unit))
			BattleHud.Command.ITEM:
				decision = await _choose_action(unit, battle, ITEMS_TITLE,
						ItemEntryBuilder.build(PlayerProfile.inventory, ItemData.UseContext.BATTLE))
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
		BattleHud.Command.ATTACK: can_act and not unit.instance.moves.is_empty(),
		BattleHud.Command.ITEM: can_act and not PlayerProfile.inventory.get_items().is_empty(),
		BattleHud.Command.RUN: can_act and battle.can_flee(),
		BattleHud.Command.END_TURN: true,
	}


## MOVE decision for a picked point, or null if cancelled.
func _choose_destination(unit: BattleMonster, battle: BattleManager) -> BattleDecision:
	hud.set_hint(MOVE_HINT)
	cursor.pick_point(unit.global_position, battle.steps_left(unit), battle.get_rules().min_move_distance)
	var picked: Array = await cursor.point_picked
	return BattleDecision.move_to(picked[1]) if picked[0] else null


## Lets the player pick one entry (payload = ActionData) and then a target. Null if cancelled.
func _choose_action(unit: BattleMonster, battle: BattleManager, title: String,
		entries: Array[ChoiceEntry]) -> BattleDecision:
	for entry: ChoiceEntry in entries:
		if entry.enabled and battle.get_valid_targets(unit, entry.payload as ActionData).is_empty():
			entry.disable(NO_TARGET_REASON)
	hud.set_hint(CHOICE_HINT)
	hud.show_choices(title, entries)
	var index: int = await hud.choice_finished
	if index < 0:
		return null
	var action: ActionData = entries[index].payload as ActionData
	var targets: Array[BattleMonster] = battle.get_valid_targets(unit, action)
	if action.target_kind == BattleTypes.TargetKind.SELF:
		return BattleDecision.use(action, unit)
	hud.set_hint(TARGET_HINT)
	cursor.pick_unit(targets)
	var target: BattleMonster = await cursor.unit_picked
	return BattleDecision.use(action, target) if target != null else null


func _build_move_entries(unit: BattleMonster) -> Array[ChoiceEntry]:
	var entries: Array[ChoiceEntry] = []
	for move: MoveData in unit.instance.moves:
		entries.append(ChoiceEntry.new(move.display_name, MOVE_DETAIL_FORMAT % [move.get_accuracy(), move.max_range],
				move.description, move))
	return entries
