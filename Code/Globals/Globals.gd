extends Node

var ChipInventory: Inven
var GearInventory: Inven
var ItemInventory: Inven
var playerStats: Dictionary
var statTypes:Array[String] = ["Attack","Defense","Speed","Luck"]
var elementGroups: Array[String] = ["Fire","Water","Elec","Neutral"]
var XSoftTypes: Array[String] = ["Fire","Water","Elec","Slash","Crush","Pierce"]
var AilmentTypes: Array[String] = ["Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive",]
var every_player_entity: Array[entityData] = [null]
var inactive_player_entities: Array[entityData] = []
var current_player_entities: Array[entityData] = []
var current_enemy_entities: Array[entityData] = []
var currentAura: String = ""
var currentSong: String = ""
var playerFirst: bool = true
var attacking: bool

func _ready(): #Uselike this: Dict[Character][Level][Stat]
	playerStats = readJSON("res://JSONS/PlayerDatabase.json")

func readJSON(filePath): #Don't open, Godot might kill itself
	var file = FileAccess.open(filePath, FileAccess.READ)
	var jsonObject = JSON.new()
	var _parsedErr = jsonObject.parse(file.get_as_text())
	return jsonObject.get_data()

func getStats(Entity,character,level):
	var stats = playerStats[character][level]
	#Resource Stats
	Entity.MaxHP = int(stats["HP"])
	Entity.specificData.MaxLP = int(stats["LP"])
	Entity.MaxTP = int(level)*2 + 80
	Entity.specificData.MaxCPU = int(stats["CPU"])
	
	#Battle Stats
	Entity.strength = int(stats["Strength"])
	Entity.toughness = int(stats["Toughness"])
	Entity.ballistics = int(stats["Ballistics"])
	Entity.resistance = int(stats["Resistance"])
	Entity.speed = int(stats["Speed"])
	Entity.luck = int(stats["Luck"])
	
	preapplyChips(Entity)
	
	return Entity

func preapplyChips(Entity):
	for chip in Entity.specificData.ChipData:
		Entity.specificData.currentCPU += chip.CpuCost
		
		match chip.ChipType:
			"Blue":
				InventoryFunctions.blueChipFun(Entity,chip)
			"Yellow":
				InventoryFunctions.yellowChipFun(Entity,chip)

func applyRedChip(Entity):
	for chip in Entity.specificData.ChipData:
		if chip.ChipType == "Red":
			InventoryFunctions.redChipFun(Entity,chip)

func getTPCost(move,entity,aura):
	var TPCost = move.TPCost - (entity.data.speed*(1 + entity.data.speedBoost))
	if aura == "LowTicks":
		TPCost = TPCost / 2
	
	return int(TPCost)

func charColor(entity):
	match entity.name:
		"DREAMER":
			return str("[color=#f4892b]",entity.name,"[/color]")
		"Lonna":
			return str("[color=#9800dc]",entity.name,"[/color]")
		"Damir":
			return str("[color=#2929ea]",entity.name,"[/color]")
		"Pepper":
			return str("[color=#e12828]",entity.name,"[/color]")
