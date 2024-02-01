extends Resource
class_name  SaveFile

@export_category("Characters")
@export var every_player_entity: Array[entityData] = []
@export var current_party: Array[entityData] = []

@export_category("Inventories")
@export var ChipInventory: Inven = Inven.new()
@export var GearInventory: Inven = Inven.new()
@export var ItemInventory: Inven = Inven.new()

func save() -> void:
	ResourceSaver.save(self, "res://JSONS&Saves/Saves/save_file.tres")

static func load_or_create() -> SaveFile:
	var res: SaveFile = load("res://JSONS&Saves/Saves/save_file.tres") as SaveFile
	if !res:
		res = SaveFile.new()
	return res
