extends Node2D

@export var maxGear: int = 1
@export var maxChips: int = 3

@onready var chipInv: Inven = Inven.new()
@onready var gearInv: Inven = Inven.new()
@onready var itemInv: Inven = Inven.new()
@onready var regSFX: Array[AudioStreamPlayer] = [$SFX/Confirm,$SFX/Back,$SFX/Menu]
@onready var currentScene = $MainMenu

var setUp: bool = false
var gearFolder: String = "res://Resources/Gear Data/"
var chipFolder: String = "res://Resources/Chip Data/"
var itemFolder: String = "res://Resources/Item Data/ItemSpecifics/"
var mainMenu: PackedScene = preload("res://Scene/Mains/MainMenu.tscn")
var optionsMenu: PackedScene = preload("res://Scene/SideMenus/options_menu.tscn")
var chipMenu: PackedScene = preload("res://Scene/SideMenus/Chip/ChipMenu.tscn")
var gearMenu: PackedScene = preload("res://Scene/SideMenus/Gear/GearMenu.tscn")
var itemMenu: PackedScene = preload("res://Scene/SideMenus/Item/ItemMenu.tscn")
var battleScene: PackedScene = preload("res://Scene/Mains/Main.tscn")

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready(): #Make every inventory
	#MAKE CHIP INVENTORY
	chipInv.type = "Chip"
	chipInv.inventory = getInventoryArray(chipFolder)
	Globals.ChipInventory = getChipSorts(chipInv)
	Globals.currentSave.ChipInventory = Globals.ChipInventory
	
	#MAKE GEAR INVENTORY
	gearInv.type = "Gear"
	gearInv.inventory = getInventoryArray(gearFolder)
	Globals.GearInventory = gearInv
	Globals.currentSave.GearInventory = Globals.GearInventory
	
	#MAKE ITEM INVENTORY
	itemInv.type = "Item"
	itemInv.inventory = getInventoryArray(itemFolder)
	Globals.ItemInventory = getItemSorts(itemInv)
	Globals.currentSave.ItemInventory = Globals.ItemInventory
	
	setUp = true

func getInventoryArray(Folder) -> Array:
	var localArray: Array = []
	var resources: Array = getFilesinFolder(Folder)
	
	for resource in resources:
		localArray.append(resource)
	
	return localArray

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

func getChipSorts(chips) -> Inven:
	var CPUsort: Array = []
	var colorSort: Array = []
	var reds: Array = []
	var blues: Array = []
	var yellows: Array = []
	
	for chip in chips.inventory:
		var foundInsert: bool = false
		
		match chip.ChipType:
			"Red":
				reds.append(chip)
			"Blue":
				blues.append(chip)
			"Yellow":
				yellows.append(chip)
		
		for checkedChips in range(CPUsort.size()):
			if CPUsort[checkedChips].CpuCost > chip.CpuCost:
				CPUsort.insert(checkedChips, chip)
				foundInsert = true
				break
		
		if CPUsort.size() == 0 or not foundInsert:
			CPUsort.append(chip)
	
	colorSort = reds + blues + yellows
	chips.inventorySort1 = colorSort
	chips.inventorySort2 = CPUsort
	return chips

func getItemSorts(items) -> Inven:
	var itemSort: Array = items.inventory.duplicate()
	var ownerSort: Array = items.inventory.duplicate()
	
	ownerSort.sort_custom(InventoryFunctions.findOwnersNum)
	items.inventorySort1 = ownerSort
	
	itemSort.sort_custom(InventoryFunctions.findCurrentNum)
	items.inventorySort2 = itemSort
	
	return items

#-----------------------------------------
#SCENE CONNECTIONS
#-----------------------------------------
func changeScene(scene) -> void:
	Globals.currentSave.save()
	currentScene.queue_free()
	
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	currentScene = newScene
	currentScene.connect("makeNoise",makeNoise)

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func _on_main_menu_options_menu() -> void:
	changeScene(optionsMenu)

func _back_to_main_menu() -> void:
	changeScene(mainMenu)
	currentScene.connect("chipMenu",_on_to_chip_menu)
	currentScene.connect("gearMenu",_on_to_gear_menu)
	currentScene.connect("itemMenu",_on_to_item_menu)
	currentScene.connect("playTest",playMusic)

func _on_change_to_battle() -> void:
	changeScene(battleScene)

func _on_to_gear_menu() -> void:
	$SFX/Confirm.play()
	changeScene(gearMenu)
	currentScene.connect("exitMenu",_back_to_main_menu)
	currentScene.connect("chipMenu",_on_to_chip_menu)
	currentScene.connect("itemMenu",_on_to_item_menu)

func _on_to_item_menu() -> void:
	$SFX/Confirm.play()
	changeScene(itemMenu)
	currentScene.connect("exitMenu",_back_to_main_menu)
	currentScene.connect("gearMenu",_on_to_gear_menu)
	currentScene.connect("chipMenu",_on_to_chip_menu)
	currentScene.connect("sort", getNewSort)

func _on_to_chip_menu() -> void:
	$SFX/Confirm.play()
	changeScene(chipMenu)
	currentScene.connect("exitMenu",_back_to_main_menu)
	currentScene.connect("gearMenu",_on_to_gear_menu)
	currentScene.connect("itemMenu",_on_to_item_menu)

func getNewSort(type) -> void:
	if type == "Chip":
		Globals.ChipInventory = getChipSorts(Globals.ChipInventory)
	else:
		Globals.ItemInventory = getItemSorts(Globals.ItemInventory)

#-----------------------------------------
#AUDIO SIGNALS
#-----------------------------------------
func makeNoise(num) -> void:
	if setUp:
		regSFX[num].play()

func playMusic(song) -> void:
	if song != "stop":
		$Music.set_stream(load(song))
		$Music.play()
	else:
		$Music.stop()
