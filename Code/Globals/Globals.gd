extends Node

var playerStats: Dictionary
var elementGroups: Array = ["Fire","Water","Elec","Neutral"]
var XSoftTypes: Array = ["Fire","Water","Elec","Slash","Crush","Pierce"]
var AilmentTypes: Array = ["Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive",]
var current_player_entities: Array = []
var current_enemy_entities: Array = []
var currentAura = ""
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
	
	#Battle Stats
	Entity.strength = int(stats["Strength"])
	Entity.toughness = int(stats["Toughness"])
	Entity.ballistics = int(stats["Ballistics"])
	Entity.resistance = int(stats["Resistance"])
	Entity.speed = int(stats["Speed"])
	Entity.luck = int(stats["Luck"])
	
	return Entity

func getTPCost(move,entity,aura):
	var TPCost = move.TPCost - (entity.data.speed*(1 + entity.data.speedBoost))
	if aura == "LowTicks":
		TPCost = TPCost / 2
	
	return int(TPCost)
