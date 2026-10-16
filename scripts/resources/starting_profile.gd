class_name StartingProfile
extends Resource
## What a new game starts with (data/party/starting_profile.tres).

@export var party: Array[MonsterSpawnEntry] = []
@export var items: Dictionary[ItemData, int] = {}
