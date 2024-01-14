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
	chipInv.inventory = getInventoryArray(chipFolder)
	chipInv = getChipSorts(chipInv)
	
	Globals.ChipInventory = chipInv
	print(Globals.ChipInventory)
	#MAKE GEAR INVENTORY
	gearInv.type = "Gear"
	gearInv.inventory = getInventoryArray(gearFolder)
	Globals.GearInventory = gearInv
	
	#MAKE ITEM INVENTORY
	itemInv.type = "Item"
	itemInv.inventory = getInventoryArray(itemFolder)
	Globals.ItemInventory = getItemSorts(itemInv)

func getInventoryArray(Folder) -> Array:
	var localArray: Array = []
	var resources: Array = getFilesinFolder(Folder)
	var item = false
	
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
	var ownerSort: Array = []
	var reds: Array = []
	var blues: Array = []
	var yellows: Array = []
	
	for chip in chips.inventory:
		var _ownerNum: int = 0
		var foundInsert: bool = false
		
		match chip.ChipType:
			"Red":
				reds.append(chip)
			"Blue":
				blues.append(chip)
			"Yellow":
				yellows.append(chip)
		
		for checkedChips in range(CPUsort.size()):
			print(CPUsort[checkedChips])
			if CPUsort[checkedChips].CpuCost > chip.CpuCost:
				CPUsort.insert(checkedChips, chip)
				foundInsert = true
				break
		
		if CPUsort.size() == 0 or not foundInsert:
			CPUsort.append(chip)
		#if chip.equippedOn == null: #Make sure the chip being operated on isn't null
			#chip.equippedOn = 0
		#if chip.equippedOn != null:
			#if chip.equippedOn & 1:
				#ownerNum += 1
			#if chip.equippedOn & 2:
				#ownerNum += 1
			#if chip.equippedOn & 4:
				#ownerNum += 1
			#if chip.equippedOn & 8:
				#ownerNum += 1
		#chip.ownerNum = ownerNum
		#
		#if ownerSort.size() == 0:
			#ownerSort.append(chip)
		#for checkedChips in range(ownerSort.size()):
			#print(ownerSort[checkedChips])
			#if ownerSort[checkedChips].ownerNum > chip.ownerNum:
				#ownerSort.insert(checkedChips, chip)
				#break
	
	colorSort = reds + blues + yellows
	chips.inventorySort1 = colorSort
	chips.inventorySort2 = CPUsort
	#chips.inventorySort3 = ownerSort
	return chips

func getItemSorts(items) -> Inven:
	return items

#-----------------------------------------
#SCENE CONNECTIONS
#-----------------------------------------
func changeScene(scene):
	currentScene.queue_free()
	var newScene = scene.instantiate()
	$".".add_child(newScene)
	currentScene = newScene
	currentScene.connect("makeNoise",makeNoise)

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func _on_main_menu_options_menu():
	changeScene(optionsMenu)

func _back_to_main_menu():
	changeScene(mainMenu)

func _on_change_to_battle():
	changeScene(battleScene)

func _on_to_gear_menu():
	$SFX/Confirm.play()

func _on_to_item_menu():
	$SFX/Confirm.play()

func _on_to_chip_menu():
	$SFX/Confirm.play()
	changeScene(chipMenu)
	currentScene.connect("exitMenu",_back_to_main_menu)
	currentScene.connect("gearMenu",_on_to_gear_menu)
	currentScene.connect("itemMenu",_on_to_item_menu)

#-----------------------------------------
#AUDIO SIGNALS
#-----------------------------------------
func makeNoise(num):
	regSFX[num].play()

func playMusic(song):
	$Music.set_stream(load(song))
	$Music.play()
