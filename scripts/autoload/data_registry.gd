extends Node
## Autoload. Loads the GameDatabase and looks content up by id (saves store ids).
## Validates the data at startup and reports problems with push_error.

const DATABASE_PATH: String = "res://data/game_database.tres"

var _database: GameDatabase
var _species: Dictionary[StringName, GameDataEntry] = {}
var _moves: Dictionary[StringName, GameDataEntry] = {}
var _items: Dictionary[StringName, GameDataEntry] = {}
var _statuses: Dictionary[StringName, GameDataEntry] = {}
var _pockets: Array[ItemPocket] = []


func _ready() -> void:
	_database = load(DATABASE_PATH) as GameDatabase
	if _database == null:
		push_error("DataRegistry: '%s' is missing or not a GameDatabase." % DATABASE_PATH)
		_database = GameDatabase.new()
	if _database.rules == null:
		push_error("DataRegistry: '%s' has no rules; using defaults." % DATABASE_PATH)
		_database.rules = BattleRules.new()
	_species = _index(_database.species, "species")
	_moves = _index(_database.moves, "move")
	_items = _index(_database.items, "item")
	_statuses = _index(_database.statuses, "status")
	_index(_database.pockets, "pocket")
	_pockets.assign(_database.pockets.filter(func(pocket: ItemPocket) -> bool: return pocket != null))
	_pockets.sort_custom(func(a: ItemPocket, b: ItemPocket) -> bool: return a.order < b.order)
	_validate_overworld_items()
	_validate_item_pockets()


func get_rules() -> BattleRules:
	return _database.rules


## Null if id is unknown.
func get_species(id: StringName) -> SpeciesData:
	return _species.get(id) as SpeciesData


func get_move(id: StringName) -> MoveData:
	return _moves.get(id) as MoveData


func get_item(id: StringName) -> ItemData:
	return _items.get(id) as ItemData


func get_status(id: StringName) -> StatusEffectData:
	return _statuses.get(id) as StatusEffectData


## Bag pockets, in tab order.
func get_pockets() -> Array[ItemPocket]:
	return _pockets


## Maps each entry's id to the entry; reports missing entries and empty or duplicate ids.
func _index(entries: Array, kind: String) -> Dictionary[StringName, GameDataEntry]:
	var by_id: Dictionary[StringName, GameDataEntry] = {}
	for entry: GameDataEntry in entries:
		if entry == null:
			push_error("DataRegistry: the %s list has an empty slot." % kind)
			continue
		var id: StringName = entry.id
		if id.is_empty():
			push_error("DataRegistry: %s '%s' has no id." % [kind, entry.resource_path])
		elif by_id.has(id):
			push_error("DataRegistry: duplicate %s id '%s' ('%s' and '%s')." \
					% [kind, id, by_id[id].resource_path, entry.resource_path])
		else:
			by_id[id] = entry
	return by_id


## Items usable in the overworld may only contain effects that work outside battle.
func _validate_overworld_items() -> void:
	for item: ItemData in _database.items:
		if item == null or not item.is_usable_in(ItemData.UseContext.OVERWORLD):
			continue
		for effect: BattleEffect in item.effects:
			if effect != null and not effect.works_outside_battle():
				push_error("DataRegistry: item '%s' is usable in the overworld but has a battle-only %s." \
						% [item.id, effect.get_script().get_global_name()])


## Every item must be in a pocket the database lists, or the bag can't show it.
func _validate_item_pockets() -> void:
	for item: ItemData in _database.items:
		if item != null and not _pockets.has(item.pocket):
			push_error("DataRegistry: item '%s' has no pocket listed in the database." % item.id)
