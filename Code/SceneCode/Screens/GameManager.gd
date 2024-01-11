extends Node2D

@export var maxGear: int = 1
@export var maxChips: int = 3

@onready var chipInv: Inven = load("res://Resources/Inventory Data/ChipInventory.tres")
@onready var gearInv: Inven = load("res://Resources/Inventory Data/GearInventory.tres")
@onready var itemInv: Inven = load("res://Resources/Inventory Data/ItemInventory.tres")
@onready var regSFX: Array[AudioStreamPlayer] = [$SFX/Confirm,$SFX/Back,$SFX/Menu]
@onready var currentScene = $MainMenu

var gearFolder = "res://Resources/Gear Data/"
var chipFolder = "res://Resources/Chip Data/"
var itemFolder = "res://Resources/Item Data/ItemSpecifics/"

var mainMenu: PackedScene = preload("res://Scene/Mains/MainMenu.tscn")
var optionsMenu: PackedScene = preload("res://Scene/SideMenus/options_menu.tscn")
var chipMenu: PackedScene = preload("res://Scene/SideMenus/Chip/ChipMenu.tscn")
var battleScene: PackedScene = preload("res://Scene/Mains/Main.tscn")

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
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
	
	#print(Globals.ChipInventory.inventory)
	#for chip in chipInv.inventory:
		#print(chip, chipInv.inventory[chip])

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

#-----------------------------------------
#SCENE CONNECTIONS
#-----------------------------------------
func _on_main_menu_options_menu():
	currentScene.get_tree().change_scene_to_packed(optionsMenu)

func _back_to_main_menu():
	currentScene.get_tree().change_scene_to_packed(mainMenu)

func _on_change_to_battle():
	currentScene.get_tree().change_scene_to_packed(battleScene)

func _on_main_menu_gear_menu():
	pass # Replace with function body.

func _on_main_menu_item_menu():
	pass # Replace with function body.


#-----------------------------------------
#SIGNALS
#-----------------------------------------
func _on_main_menu_chip_menu():
	$SFX/Confirm.play()
	currentScene.queue_free()
	var newScene = chipMenu.instantiate()
	$".".add_child(newScene)
	currentScene = newScene
	currentScene.connect("exitMenu",_back_to_main_menu)
	currentScene.connect("makeNoise",makeNoise)

func makeNoise(num):
	regSFX[num].play()
