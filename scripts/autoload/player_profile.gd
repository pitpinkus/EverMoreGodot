extends Node
## Autoload. The player's monsters, inventory and last heal point. Saved through
## SaveSystem state; a new game (and running a scene directly) starts from
## STARTING_PROFILE_PATH.

signal party_changed

const STARTING_PROFILE_PATH: String = "res://data/party/starting_profile.tres"
const STATE_PARTY: StringName = &"party"
const STATE_INVENTORY: StringName = &"inventory"
const STATE_RESPAWN_POINT: StringName = &"respawn_point"
const MESSAGE_NOT_USABLE: String = "That can't be used here."
const MESSAGE_NONE_LEFT: String = "You don't have any left."
const MESSAGE_NO_EFFECT: String = "It won't have any effect."

## Both are replaced (not edited) on reset and load; party_changed is emitted then,
## so re-read them on party_changed instead of keeping references.
var party: Array[MonsterInstance] = []
var inventory: Inventory = Inventory.new()

var _starting_profile: StartingProfile
## Last visited heal point; null until one is visited.
var _respawn: RespawnPoint


func _ready() -> void:
	_starting_profile = load(STARTING_PROFILE_PATH) as StartingProfile
	if _starting_profile == null:
		push_error("PlayerProfile: '%s' is missing or not a StartingProfile." % STARTING_PROFILE_PATH)
		_starting_profile = StartingProfile.new()
	SaveSystem.save_started.connect(_on_save_started)
	SaveSystem.load_completed.connect(_on_load_completed)
	reset_to_starting_profile()


## Starting party and items, no heal point.
func reset_to_starting_profile() -> void:
	party = _build_starting_party()
	inventory = _build_starting_inventory()
	_respawn = null
	party_changed.emit()


func has_able_monster() -> bool:
	return not get_able_monsters().is_empty()


## Party monsters that have not fainted, in party order.
func get_able_monsters() -> Array[MonsterInstance]:
	var able: Array[MonsterInstance] = []
	for monster: MonsterInstance in party:
		if not monster.is_fainted():
			able.append(monster)
	return able


func is_party_full() -> bool:
	return party.size() >= DataRegistry.get_rules().max_party_size


## Adds monster to the party. False if the party is full.
func add_to_party(monster: MonsterInstance) -> bool:
	if monster == null or is_party_full():
		return false
	party.append(monster)
	party_changed.emit()
	return true


## Restores every party monster to full HP.
func heal_party() -> void:
	for monster: MonsterInstance in party:
		monster.restore_full()


## True if item would do something to target outside battle (ignores how many are held).
func can_use_item_outside_battle(item: ItemData, target: MonsterInstance) -> bool:
	return item.is_usable_in(ItemData.UseContext.OVERWORLD) \
			and item.can_use_on(EffectContext.for_overworld(target, item, DataRegistry.get_rules()))


## Uses one item on target outside battle. Returns the messages to show.
func use_item_outside_battle(item: ItemData, target: MonsterInstance) -> Array[String]:
	if item == null or target == null or not item.is_usable_in(ItemData.UseContext.OVERWORLD):
		return [MESSAGE_NOT_USABLE]
	if inventory.get_count(item) <= 0:
		return [MESSAGE_NONE_LEFT]
	if not can_use_item_outside_battle(item, target):
		return [MESSAGE_NO_EFFECT]
	var ctx: EffectContext = EffectContext.for_overworld(target, item, DataRegistry.get_rules())
	item.apply_effects(ctx)
	if item.consumed_on_use:
		inventory.remove(item)
	return ctx.take_messages()


func set_respawn_point(point: RespawnPoint) -> void:
	_respawn = point


## Last visited heal point, or null if none was visited yet.
func get_respawn_point() -> RespawnPoint:
	return _respawn


func _build_starting_party() -> Array[MonsterInstance]:
	return MonsterSpawnEntry.build_all(_starting_profile.party, RandomNumberGenerator.new(), DataRegistry.get_rules())


func _build_starting_inventory() -> Inventory:
	var start: Inventory = Inventory.new()
	for item: ItemData in _starting_profile.items:
		start.add(item, _starting_profile.items[item])
	return start


func _on_save_started() -> void:
	var party_data: Array[Dictionary] = []
	for monster: MonsterInstance in party:
		party_data.append(monster.to_dict())
	SaveSystem.set_state(STATE_PARTY, party_data)
	SaveSystem.set_state(STATE_INVENTORY, inventory.to_dict())
	if _respawn != null:
		SaveSystem.set_state(STATE_RESPAWN_POINT, _respawn.to_dict())
	else:
		SaveSystem.erase_state(STATE_RESPAWN_POINT)


## Restores the saved profile; anything missing from the save comes from the starting profile.
func _on_load_completed(_info: SaveSlotInfo) -> void:
	var saved_party: Variant = SaveSystem.get_state(STATE_PARTY)
	if saved_party is Array:
		party = []
		for data: Variant in saved_party:
			var monster: MonsterInstance = MonsterInstance.from_dict(data) if data is Dictionary else null
			if monster != null:
				party.append(monster)
			else:
				push_warning("PlayerProfile: skipped an unreadable party entry.")
	else:
		party = _build_starting_party()
	var saved_inventory: Variant = SaveSystem.get_state(STATE_INVENTORY)
	inventory = Inventory.from_dict(saved_inventory) if saved_inventory is Dictionary else _build_starting_inventory()
	var saved_respawn: Variant = SaveSystem.get_state(STATE_RESPAWN_POINT)
	_respawn = RespawnPoint.from_dict(saved_respawn) if saved_respawn is Dictionary else null
	party_changed.emit()
