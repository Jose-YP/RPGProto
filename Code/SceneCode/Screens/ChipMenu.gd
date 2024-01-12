extends Control

@export var InvChipPanel: PackedScene
@export var playerChipPanel: PackedScene

#Menus
@onready var chipInv: GridContainer = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/ChipSelection/GridContainer
@onready var playerChips: GridContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CurrentChips/PanelContainer
@onready var InvMarkers: Array[Marker2D] = [$InvFirst]
@onready var PlayMarkers: Array[Marker2D] = [$PlayeFirst]
@onready var Arrow: Sprite2D = $Arrow
#Descriptions
@onready var invChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var invChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var invChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/Description/RichTextLabel
@onready var playerChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var playerChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var playerChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/MarginContainer/Description/RichTextLabel
#Current Player Info
@onready var playerResource: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/Character/RichTextLabel
@onready var playerElement: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/Player1Element
@onready var playerPhyEle: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/PlayerPhyElement1
@onready var playerBattleStats: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/Stats/RichTextLabel
@onready var CPUText: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/RichTextLabel
@onready var CPUBar: TextureProgressBar = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/EnemyTP

signal chipMenu
signal gearMenu
signal itemMenu
signal exitMenu
signal makeNoise(num)

var ChipIcon = preload("res://Icons/MenuIcons/icons-set-2_0000s_0029__Group_.png")
var InvMenu: Array[Array] = [[],[]]
var PlayMenu: Array[Array] = [[],[]]
var markerArray: Array = []
var markerIndex: int = 0
var side: int = 0
var num: int = 0
var playerIndex: int = 0
var CPUusage: int = 0
var movingChip: bool = false

#-----------------------------------------
#INITALIZATION AND PROCESSING
#-----------------------------------------
func _ready():
	emit_signal("chipMenu")
	InventoryFunctions.chipHandler()
	
	for chip in Globals.ChipInventory.inventory:
		var chipPanel = InvChipPanel.instantiate()
		chipPanel.ChipData = chip
		chipPanel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPanel.connect("getDesc",on_inv_focused)
		chipInv.add_child(chipPanel)
		
		InvMenu[side].append(chipPanel)
		InvMarkers.append(chipPanel.inBetween)
		side = swap(side)
	
	side = 0
	
	getPlayerStats(playerIndex)
	getPlayerChips(playerIndex)
	
	InvMenu[0][0].focus.grab_focus()

func _process(_delta):
	movement()
	buttons()

func movement():
	if Input.is_action_just_pressed("Left"):
		if movingChip:
			if markerIndex%3 == 0 and markerIndex != 0:
				side = swap(side)
			else:
				markerIndex -= 1
			if markerIndex < 0:
				if side == 1:
					side = swap(side)
					markerIndex = 1
				else:
					markerIndex = 0
			if markerIndex > (markerArray[side].size() - 1):
				markerIndex = markerArray[side].size() - 1
			
			print(side,markerIndex)
			print(markerArray[side][markerIndex])
			Arrow.global_position = markerArray[side][markerIndex].global_position
	
	if Input.is_action_just_pressed("Right"):
		if movingChip:
			markerIndex += 1
			if markerIndex%3 == 0:
				print("Swap")
				side = swap(side)
				markerIndex -= 1
			if markerIndex > (markerArray[side].size() - 1):
				markerIndex = markerArray[side].size() - 1
			
			print(side,markerIndex)
			print(markerArray[side][markerIndex])
			Arrow.global_position = markerArray[side][markerIndex].global_position
	
	if Input.is_action_just_pressed("Up"):
		if movingChip:
			markerIndex -= 2
			if markerIndex < 0:
				markerIndex = 0
			
			Arrow.global_position = markerArray[side][markerIndex].global_position
			print(side,markerIndex)
			print(markerArray[side][markerIndex])
	
	if Input.is_action_just_pressed("Down"):
		if movingChip:
			markerIndex += 2
			if markerIndex > (markerArray[side].size() - 1):
				markerIndex = markerArray[side].size() - 1
			
			Arrow.global_position = markerArray[side][markerIndex].global_position
			print(side,markerIndex)
			print(markerArray[side][markerIndex])

func buttons():
	if Input.is_action_just_pressed("Accept"):
		makeNoise.emit(0)
		if movingChip:
			movingChip = false
		else:
			movingChip = true
			Arrow.show()
			Arrow.global_position = get_viewport().gui_get_focus_owner().get_parent().inBetween.global_position
		
	if Input.is_action_just_pressed("Cancel"):
		makeNoise.emit(1)
		if movingChip:
			movingChip = false
		else:
			exitMenu.emit()
	
	if Input.is_action_just_pressed("X"):
		exitMenu.emit()
	
	if Input.is_action_just_pressed("Y"):
		pass
	
	#[chip,gear,item]
	if Input.is_action_just_pressed("ZL"):
		itemMenu.emit()
	
	if Input.is_action_just_pressed("ZR"):
		gearMenu.emit()
	
	if Input.is_action_just_pressed("L"):
		makeNoise.emit(2)
		playerIndex -= 1
		if playerIndex < 0:
			playerIndex = 2
		
		getPlayerStats(playerIndex)
		getPlayerChips(playerIndex)
		
		if get_viewport().gui_get_focus_owner() == null:
			PlayMenu[0][0].focus.grab_focus()
	
	if Input.is_action_just_pressed("R"):
		makeNoise.emit(2)
		playerIndex += 1
		if playerIndex > (Globals.every_player_entity.size() - 1):
			playerIndex = 0
		
		getPlayerStats(playerIndex)
		getPlayerChips(playerIndex)
		
		if get_viewport().gui_get_focus_owner() == null:
			PlayMenu[0][0].focus.grab_focus()

func _unhandled_input(_event):
	if movingChip:
		return

#-----------------------------------------
#INVENTORY DOCK
#-----------------------------------------

#-----------------------------------------
#PLAYER DOCK
#-----------------------------------------
func getPlayerStats(index):
	var entity = Globals.every_player_entity[index]
	var CPUtween = CPUBar.create_tween()
	var resourceString = str(Globals.charColor(entity)," [color=red]HP: ",entity.MaxHP,"[/color]"
	,"\n [color=aqua]LP:",entity.specificData.MaxLP," [/color][color=green]",
	entity.MaxTP,"[/color]")
	var stats = str("STR: ",entity.strength,"\tTGH: ",entity.toughness,"\tSPD: ",entity.speed,
	"\nBAL: ",entity.ballistics,"\tRES: ",entity.resistance,"\tLUK: ",entity.luck)
	var currentCPUtext = str((entity.specificData.MaxCPU - entity.specificData.currentCPU),"/",entity.specificData.MaxCPU,"\nCPU")
	
	playerResource.clear()
	playerBattleStats.clear()
	CPUText.clear()
	
	playerResource.append_text(resourceString)
	playerBattleStats.append_text(stats)
	CPUText.append_text(currentCPUtext)
	
	getElements(entity)
	
	var newValue = int(100*(float(entity.specificData.MaxCPU - entity.specificData.currentCPU) / float(entity.specificData.MaxCPU)))
	CPUtween.tween_property(CPUBar, "value", newValue,.2).set_trans(Tween.TRANS_CIRC).from(entity.specificData.MaxCPU)

func getPlayerChips(index):
	clearPlayerChips()
	
	var entity = Globals.every_player_entity[index]
	entity.specificData.currentCPU = 0
	
	for chip in entity.specificData.ChipData:
		var chipPannel = playerChipPanel.instantiate()
		entity.specificData.currentCPU += chip.CpuCost
		chipPannel.ChipData = chip
		chipPannel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPannel.connect("getDesc",on_play_focused)
		playerChips.add_child(chipPannel)
		
		PlayMenu[side].append(chipPannel)
		PlayMarkers.append(chipPannel.inBetween)
		
		side = swap(side)
	
	side = 0
	markerArray = [InvMarkers,PlayMarkers]

func clearPlayerChips():
	PlayMenu = [[],[]]
	PlayMarkers = [$PlayeFirst]
	for thing in playerChips.get_children():
		playerChips.remove_child(thing)
		thing.queue_free()

func getElements(entity):
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			playerElement.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			playerPhyEle.current_tab = k

func addChip(entity,chip):
	entity.specificData.chipData.append(chip)

func removeChip(entity,chip):
	entity.specificData.chipData.erase(chip)

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func on_inv_focused(data):
	makeNoise.emit(2)
	
	invChipTitle.clear()
	invChipTitle.append_text(str(data.ChipData.name, " Chip"))
	
	invChipDetails.clear()
	invChipDetails.append_text(str("[center]",data.ChipData.ChipType," Chip\nOwners:",
	data.currentPlayers,"[/center]"))
	
	invChipDisc.clear()
	invChipDisc.append_text(data.ChipData.description)

func on_play_focused(data):
	makeNoise.emit(2)
	
	playerChipTitle.clear()
	playerChipTitle.append_text(str(data.ChipData.name, " Chip"))
	
	playerChipDetails.clear()
	playerChipDetails.append_text(str("[center]",data.ChipData.ChipType," Chip[/center]"))
	
	playerChipDisc.clear()
	playerChipDisc.append_text(data.ChipData.description)

#-----------------------------------------
#HELPER FUNCTIONS
#-----------------------------------------
func swap(value) -> int:
	if value == 0:
		value += 1
	else:
		value -= 1
	return value
