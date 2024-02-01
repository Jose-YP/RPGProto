extends Resource
class_name  SaveFile

@export_category("Characters")
@export var every_player_entity: Array[entityData] = []
@export var player_levels: Array[int] = [5,5,5,5]

@export_category("Inventories")
@export var ChipInventory: Inven
@export var GearInventory: Inven
@export var ItemInventory: Inven

func save() -> void:
	ResourceSaver.save(self, "res://JSONS&Saves/Saves/user_prefs.tres")

static func load_or_create() -> UserPreferences:
	var res: UserPreferences = load("res://JSONS&Saves/Saves/user_prefs.tres") as UserPreferences
	if !res:
		res = UserPreferences.new()
	return res
