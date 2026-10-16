class_name BlueprintCatalog
extends Resource
## Every Blueprint offered by the editor's Evermore tools menu, in menu order, and the
## GameDatabase new entries are registered in (data/templates/blueprint_catalog.tres).

@export var database: GameDatabase
@export var blueprints: Array[Blueprint] = []
