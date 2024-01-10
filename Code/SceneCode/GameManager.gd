extends Node2D

@export var maxGear: int = 1
@export var maxChips: int = 4

@onready var gearInv: Inven = load("res://Resources/Inventory Data/ChipInventory.tres")
@onready var chipInv: Inven = load("res://Resources/Inventory Data/GearInventory.tres")
@onready var itemInv: Inven = load("res://Resources/Inventory Data/ItemInventory.tres")

var gearFolder = "res://Resources/Gear Data/"
var chipFolder = "res://Resources/Chip Data/"
var itemFolder = "res://Resources/Item Data/ItemSpecifics/"

var chipMenu: PackedScene = load("res://Scene/ChipMenu.tscn")

func _ready(): #Make every inventory
	#MAKE CHIP INVENTORY
	chipInv.type = "Chip"
	chipInv.inventory = getInventoryDict(chipFolder)
	Globals.ChipInventory = chipInv
	
	#MAKE GEAR INVENTORY
	gearInv.type = "Gear"
	gearInv.inventory = getInventoryDict(gearFolder)
	Globals.GearInventory = gearInv
	
	#MAKE ITEM INVENTORY
	itemInv.type = "Item"
	itemInv.inventory = getInventoryDict(itemFolder)
	Globals.ItemInventory = itemInv
	
	print(chipInv,gearInv,itemInv)

func getInventoryDict(Folder) -> Dictionary:
	var localDict: Dictionary = {}
	var resources: Array = getFilesinFolder(Folder)
	var folderMax = 1
	var item = false
	
	match Folder: #Depending on folder get max
		chipFolder:
			folderMax = maxChips
		gearFolder:
			folderMax = maxGear
		itemFolder:
			item = true
	
	for resource in resources:
		if item == true: #If item it depends on item specific
			folderMax = resource.maxCarry
		
		localDict[resource] = folderMax
	
	return localDict

func getFilesinFolder(path) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin() #Start checking every file in folder
		var file_name = dir.get_next()
		
		while file_name != "":
			var fileResource = load(path + file_name) #Load file in file folder
			files.append(fileResource)
			file_name = dir.get_next()
			
			if file_name == "":
				break
			if dir.current_is_dir():
				continue
	
	return files #return array of every resource
