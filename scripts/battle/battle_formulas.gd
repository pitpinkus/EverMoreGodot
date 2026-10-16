class_name BattleFormulas
extends RefCounted
## Static battle maths (ported from "Evermore – the Wilds"). Fixed formula constants
## live here; tunables come from BattleRules.

## Percent scale used by chances, accuracy and crit power.
const PERCENT: float = 100.0
## Stats grow linearly with level: (base + iv) * level / STAT_LEVEL_DIVISOR.
const STAT_LEVEL_DIVISOR: float = 50.0
const HP_FLAT_BONUS: int = 10
const STAT_FLAT_BONUS: int = 5
## Damage: ((LEVEL_FACTOR * level + LEVEL_OFFSET) * power * atk / def) / DAMAGE_DIVISOR + DAMAGE_OFFSET.
const DAMAGE_LEVEL_FACTOR: float = 2.0 / 5.0
const DAMAGE_LEVEL_OFFSET: float = 2.0
const DAMAGE_DIVISOR: float = 50.0
const DAMAGE_OFFSET: float = 2.0
const MIN_DAMAGE: int = 1
## Upper end of the random damage roll (lower end is BattleRules.damage_variance_min).
const DAMAGE_VARIANCE_MAX: float = 1.0
## Power-scaled heal: level * power / HEAL_DIVISOR + HEAL_OFFSET.
const HEAL_DIVISOR: float = 50.0
const HEAL_OFFSET: float = 2.0


## Unstaged stat at level. HP gets a larger flat bonus.
static func stat_value(base: int, iv: int, level: int, is_hp: bool) -> int:
	var bonus: int = HP_FLAT_BONUS if is_hp else STAT_FLAT_BONUS
	return floori((base + iv) * level / STAT_LEVEL_DIVISOR) + bonus


## value after applying the multiplier for stage (clamped by rules). Never below 0.
static func staged(value: int, stage: int, rules: BattleRules) -> int:
	return maxi(0, roundi(value * rules.get_stage_multiplier(stage)))


## Chance in percent (rules.min_hit_chance .. rules.max_hit_chance) that an attack hits.
static func hit_chance(accuracy: float, target_dodge: float, rules: BattleRules) -> float:
	return clampf(accuracy - target_dodge * rules.dodge_effectiveness, rules.min_hit_chance, rules.max_hit_chance)


## Final damage. crit_mod is the crit bonus in percent; ranged_mult scales indirect moves;
## variance is the random roll from roll_variance().
static func damage(level: int, power: int, atk: int, def: int, crit: bool, crit_mod: int,
		ranged_mult: float, variance: float) -> int:
	var base: float = ((DAMAGE_LEVEL_FACTOR * level + DAMAGE_LEVEL_OFFSET) * power * (float(atk) / maxi(1, def))) \
			/ DAMAGE_DIVISOR + DAMAGE_OFFSET
	if crit:
		base += base * crit_mod / PERCENT
	base *= ranged_mult
	return maxi(MIN_DAMAGE, floori(base * variance))


## Random damage multiplier in [rules.damage_variance_min, DAMAGE_VARIANCE_MAX].
static func roll_variance(rng: RandomNumberGenerator, rules: BattleRules) -> float:
	return rng.randf_range(rules.damage_variance_min, DAMAGE_VARIANCE_MAX)


## HP restored by a power-scaled heal from a user at level.
static func heal_by_power(level: int, power: int) -> int:
	return floori(level * power / HEAL_DIVISOR + HEAL_OFFSET)


## Distance between a and b on the ground plane (height ignored). Used for ranges and steps.
static func flat_distance(a: Vector3, b: Vector3) -> float:
	return flat_offset(a, b).length()


## Vector from from_point to to_point on the ground plane (y = 0).
static func flat_offset(from_point: Vector3, to_point: Vector3) -> Vector3:
	return Vector3(to_point.x - from_point.x, 0.0, to_point.z - from_point.z)
