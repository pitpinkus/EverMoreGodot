class_name LearnsetEntry
extends Resource
## A move a species learns at a level.

@export var move: MoveData
@export_range(1, 100, 1) var level: int = 1
