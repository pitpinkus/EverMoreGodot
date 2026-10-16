class_name MoveData
extends ActionData
## A move a monster knows (data/moves/*.tres).

@export var element: BattleTypes.Element = BattleTypes.Element.NEUTRAL
@export_range(0, 100, 1, "suffix:%") var accuracy: int = 100
## Never misses (no accuracy roll).
@export var guaranteed_hit: bool = false
## Direct moves are melee; indirect (ranged) moves deal indirect_damage_multiplier damage.
@export var is_direct: bool = true
@export_range(0.0, 2.0, 0.01) var indirect_damage_multiplier: float = 0.85


func rolls_accuracy() -> bool:
	return not guaranteed_hit


func get_accuracy() -> int:
	return accuracy


## Total power of the damage it deals to its target (0 = not a damaging move).
func get_power() -> int:
	var power: int = 0
	for effect: BattleEffect in effects:
		if effect is DamageEffect and not effect.target_self:
			power += (effect as DamageEffect).power
	return power
