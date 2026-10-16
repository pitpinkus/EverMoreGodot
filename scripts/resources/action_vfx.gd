class_name ActionVfx
extends Resource
## How a move or item looks when used (data/vfx/*.tres), played by ActionVfxPlayer:
## cast effect on the user, a short wait, then a lunge (melee) and/or a projectile,
## then the impact effect on the target if the action hit. Every part is optional.

## Spawned at the user when the action starts. Null = none.
@export var cast_vfx: PackedScene
## Wait after the cast effect before the lunge / projectile.
@export_range(0.0, 3.0, 0.05, "suffix:s") var cast_delay: float = 0.2
## The user lunges towards the target (melee). Ignored on self-targeted use.
@export var lunge: bool = false
## A Projectile scene flown from the user to the target. Null = none. Ignored on self-targeted use.
@export var projectile: PackedScene
## Spawned at the target on a hit. Null = none.
@export var impact_vfx: PackedScene
