class_name TurnScheduler
extends RefCounted
## Conditional turn-based (CTB) timeline. Every unit has an absolute time of its next
## turn; the earliest acts. After a turn the unit waits
## rules.turn_base_delay / Speed * jitter, so twice the Speed means about twice the turns.
## Ties: player side first, then the order units were added.
## Jitters are pre-rolled per unit from the scheduler's own RNG (so predicting never
## shifts combat rolls) and never re-rolled, so predict() shows exactly what will happen
## unless the battle state changes (Speed buffs, faints).
## It watches its units' stat stages, so a Speed change moves the unit's turn at once.

## A unit's Speed changed and its next turn moved.
signal order_changed


## Timeline state of one unit.
class Entry:
	extends RefCounted
	var next_time: float
	## Insertion counter, the last tie-breaker.
	var order: int
	## Jitters of this unit's next delays; [0] is used by the next reschedule.
	var jitters: Array[float] = []
	## Last known Speed, to rescale the wait when it changes.
	var speed: int

	func _init(entry_order: int) -> void:
		order = entry_order


var _rules: BattleRules
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _now: float = 0.0
var _entries: Dictionary[BattleMonster, Entry] = {}
var _added_count: int = 0


func _init(rules: BattleRules, rng_seed: int) -> void:
	_rules = rules
	_rng.seed = rng_seed


## Puts unit on the timeline; its first turn comes one delay from now.
func add(unit: BattleMonster) -> void:
	if _entries.has(unit):
		return
	var entry: Entry = Entry.new(_added_count)
	_added_count += 1
	_entries[unit] = entry
	entry.speed = unit.get_stat(BattleTypes.Stat.SPEED)
	unit.get_stat_stages().stages_changed.connect(_on_stages_changed.bind(unit))
	_schedule_next(unit, entry)


## Takes unit off the timeline (fainted, captured).
func remove(unit: BattleMonster) -> void:
	if _entries.erase(unit):
		unit.get_stat_stages().stages_changed.disconnect(_on_stages_changed.bind(unit))


## The unit whose turn comes next; the timeline advances to its turn. Null if empty.
func pop_next() -> BattleMonster:
	var times: Dictionary[BattleMonster, float] = {}
	for unit: BattleMonster in _entries:
		times[unit] = _entries[unit].next_time
	var next: BattleMonster = _get_earliest(times)
	if next != null:
		_now = times[next]
	return next


## After unit's turn: its next turn comes one delay (at its current Speed) from now.
func reschedule(unit: BattleMonster) -> void:
	var entry: Entry = _entries.get(unit)
	if entry == null:
		return
	_schedule_next(unit, entry)


## The next count turns, current first (the unit acting now, or null between turns).
## Simulated on copies with the pre-rolled jitters; buffs that run out at a unit's
## turn start are taken into account.
func predict(count: int, current: BattleMonster) -> Array[BattleMonster]:
	var turns: Array[BattleMonster] = []
	var times: Dictionary[BattleMonster, float] = {}
	# Reschedules simulated so far per unit (index into its jitters).
	var simulated: Dictionary[BattleMonster, int] = {}
	for unit: BattleMonster in _entries:
		times[unit] = _entries[unit].next_time
		simulated[unit] = 0
	if current != null and _entries.has(current) and count > 0:
		turns.append(current)
		times[current] = _now + _get_delay(current, _entries[current], 0, 0)
		simulated[current] = 1
	while turns.size() < count and not times.is_empty():
		var unit: BattleMonster = _get_earliest(times)
		turns.append(unit)
		var index: int = simulated[unit]
		# Units other than current still have their turn start (and its buff tick) ahead.
		var turn_starts_ahead: int = index if unit == current else index + 1
		times[unit] += _get_delay(unit, _entries[unit], index, turn_starts_ahead)
		simulated[unit] = index + 1
	return turns


## The unit's Speed went from old_speed to new_speed: the rest of its wait shrinks or
## grows at once.
func _rescale_wait(entry: Entry, old_speed: int, new_speed: int) -> void:
	var ratio: float = float(_clamp_speed(old_speed)) / _clamp_speed(new_speed)
	entry.next_time = _now + (entry.next_time - _now) * ratio


## Sets unit's next turn one delay from now and uses up that delay's jitter.
func _schedule_next(unit: BattleMonster, entry: Entry) -> void:
	entry.next_time = _now + _get_delay(unit, entry, 0, 0)
	entry.jitters.pop_front()


## Wait after a turn: base delay / Speed * the jitter at jitter_index. Speed is taken
## as it will be after turn_starts_ahead more turn starts of unit.
func _get_delay(unit: BattleMonster, entry: Entry, jitter_index: int, turn_starts_ahead: int) -> float:
	while entry.jitters.size() <= jitter_index:
		entry.jitters.append(_rng.randf_range(_rules.turn_jitter_min, _rules.turn_jitter_max))
	var speed: int = unit.get_projected_stat(BattleTypes.Stat.SPEED, turn_starts_ahead)
	return _rules.turn_base_delay / _clamp_speed(speed) * entry.jitters[jitter_index]


## A Speed change takes effect at once: the unit's remaining wait is rescaled.
func _on_stages_changed(unit: BattleMonster) -> void:
	var entry: Entry = _entries[unit]
	var new_speed: int = unit.get_stat(BattleTypes.Stat.SPEED)
	if new_speed == entry.speed:
		return
	_rescale_wait(entry, entry.speed, new_speed)
	entry.speed = new_speed
	order_changed.emit()


func _clamp_speed(speed: int) -> int:
	return maxi(speed, _rules.min_turn_speed)


## Unit with the lowest time; ties go to the player side, then to the earlier added unit.
func _get_earliest(times: Dictionary[BattleMonster, float]) -> BattleMonster:
	var best: BattleMonster = null
	for unit: BattleMonster in times:
		if best == null or _comes_before(unit, times[unit], best, times[best]):
			best = unit
	return best


func _comes_before(a: BattleMonster, time_a: float, b: BattleMonster, time_b: float) -> bool:
	if time_a != time_b:
		return time_a < time_b
	if a.side != b.side:
		return a.side == BattleTypes.Side.PLAYER
	return _entries[a].order < _entries[b].order
