extends Resource
class_name  SaveFile

@export_category("Characters")
#DREAMER 0 | LONNA 1 | DAMIR 2 | PEPPER 3
@export var every_player_entity: Array[entityData] = [entityData.new(),entityData.new(),entityData.new(),entityData.new()]
@export var every_specific_data: Array[Player] = [Player.new(),Player.new(),Player.new(),Player.new()]
@export var current_party: Array[int] = [0,2,3]

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
