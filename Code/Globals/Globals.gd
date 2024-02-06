extends Node

var ChipInventory: Inven = load("res://Resources/Inventory Data/ChipInventory.tres") as Inven
var GearInventory: Inven = load("res://Resources/Inventory Data/GearInventory.tres") as Inven
var ItemInventory: Inven = load("res://Resources/Inventory Data/ItemInventory.tres") as Inven
var noMovePlaceholder: Move = load("res://Resources/Move Data/Player Moves/AllPlayers/MiscPlaceHolder.tres")

var playerStats: Dictionary
var statTypes:Array[String] = ["Attack","Defense","Speed","Luck"]
var elementGroups: Array[String] = ["Fire","Water","Elec","Neutral"]
var XSoftTypes: Array[String] = ["Fire","Water","Elec","Slash","Crush","Pierce","Comet","Light",
"Aurora","Aether"]
var AilmentTypes: Array[String] = ["Overdrive","Poison","Reckless","Exhausted","Rust","Dumbfounded",
"Stun","Curse","Protected","Miserable","Worn Out", "Explosive"]
var every_player_entity: Array[entityData] = [null]
var inactive_player_entities: Array[entityData] = []
var current_player_entities: Array[entityData] = []
var current_enemy_entities: Array[entityData] = []
var currentAura: String = ""
var currentSong: String = ""
var playerFirst: bool = true
var attacking: bool = false
var groupEleMod: float = 0.0
var currentSave: SaveFile
var userPrefs: UserPreferences

func _ready(): #Uselike this: Dict[Character][Level][Stat]
	currentSave = SaveFile.load_or_create()
	userPrefs = UserPreferences.load_or_create()
	playerStats = readJSON("res://JSONS&Saves/JSONS/PlayerDatabase.json")

func readJSON(filePath) -> Dictionary: #Don't open, Godot might kill itself
	var file = FileAccess.open(filePath, FileAccess.READ)
	var jsonObject = JSON.new()
	var _parsedErr = jsonObject.parse(file.get_as_text())
	return jsonObject.get_data()

func getStats(Entity,character,level) -> entityData:
	var stats = playerStats[character][str(level)]
	if currentSave.every_specific_data[charNum(Entity)].Tactics2 == null:
		currentSave.every_specific_data[charNum(Entity)].setUp(Entity.element, Entity.phyElement, Entity.Weakness, Entity.Resist, Entity.name)
	Entity.specificData = currentSave.every_specific_data[charNum(Entity)]
	
	#Resource Stats
	Entity.level = level
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
	
	#Properties
	Entity.element = Entity.specificData.permanentElement
	Entity.phyElement = Entity.specificData.permanentPhyEle
	Entity.Weakness = Entity.specificData.permanentWeakness
	Entity.Resist = Entity.specificData.permanentResist
	Entity.immunity = "None"
	Entity.soloElementMod = 0.0
	Entity.groupElementMod = 0.0
	Entity.phyElementMod = 0
	Entity.sameElement = false
	Entity.ItemChange = "None"
	#Bonuses
	Entity.costBonus = 0
	Entity.HpCostMod = 0.0
	Entity.LpCostMod = 0.0
	Entity.TpCostMod = 0.0
	Entity.calcBonus = 0
	Entity.drainCalcAmmount = 0
	Entity.ailmentCalcAmmount = 0
	Entity.critCalcAmmount = 0
	
	#Moves
	Entity.specificData.Basics[1] = noMovePlaceholder
	Entity.specificData.attackTarget = "Single"
	Entity.specificData.boostTarget = "Single"
	Entity.specificData.boostStat = Entity.specificData.defaultBoostStat
	
	InventoryFunctions.gearApply(Entity, Entity.specificData.GearData)
	InventoryFunctions.miniItemHandler(Entity,Entity.itemData,ItemInventory.inventory)
	InventoryFunctions.applyItems(Entity,ItemInventory.inventory)
	ApplyChips(Entity)
	return Entity

func getBaseStats(character,level,stat) -> int:
	var stats = playerStats[character][str(level)]
	
	match stat:
		"HP": return int(stats["HP"])
		"LP":return int(stats["LP"])
		"TP": return int(level)*2 + 80
		"CPU": return int(stats["CPU"])
		"Strength": return int(stats["Strength"])
		"Toughness": return int(stats["Toughness"])
		"Ballistics": return int(stats["Ballistics"])
		"Resistance": return int(stats["Resistance"])
		"Speed": return int(stats["Speed"])
		"Luck": return int(stats["Luck"])
	
	return 0

func ApplyChips(Entity) -> void:
	Entity.specificData.currentCPU = 0
	for chip in Entity.specificData.ChipData:
		Entity.specificData.currentCPU += chip.CpuCost
		match chip.ChipType:
			"Red": InventoryFunctions.redChipFun(Entity,chip)
			"Blue": InventoryFunctions.blueChipFun(Entity,chip)
			"Yellow": InventoryFunctions.yellowChipFun(Entity,chip)

func readyPlayerDataSave() -> void:
	for player in every_player_entity:
		print(player.name)
		currentSave.every_specific_data[charNum(player)] = player.specificData

func getTPCost(move,entity) -> int:
	var TPCost = move.TPCost - (entity.data.speed*(1 + entity.data.speedBoost))
	if Globals.currentAura == "LowTicks": TPCost = TPCost / 2
	
	return int(TPCost)

func charColor(entity) -> String:
	match entity.name:
		"DREAMER": return str("[color=#f4892b]",entity.name,"[/color]")
		"Lonna": return str("[color=#9800dc]",entity.name,"[/color]")
		"Damir": return str("[color=#2929ea]",entity.name,"[/color]")
		"Pepper": return str("[color=#e12828]",entity.name,"[/color]")
	
	return ""

func charNum(entity) -> int:
	match entity.name:
		"DREAMER": return 0
		"Lonna": return 1
		"Damir": return 2
		"Pepper": return 3
	return 0

func charFlag(entity) -> int:
	match entity.name:
		"DREAMER": return 1
		"Lonna": return 2
		"Damir": return 4
		"Pepper": return 8
	return 0
