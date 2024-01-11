extends Control

@export var InvChipPanel: PackedScene
@export var playerChipPanel: PackedScene

#Menus
@onready var chipInv: GridContainer = $VBoxContainer/HBoxContainer/ChipSelection/Button/VBoxContainer/ChipSelection/GridContainer
@onready var playerChips: GridContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CurrentChips/PanelContainer
@onready var Docks: Array[Button] = [$VBoxContainer/HBoxContainer/ChipSelection/Button,$VBoxContainer/HBoxContainer/CurrentCharChips/Button]
#Descriptions
@onready var invChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/Button/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var invChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/Button/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var invChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/Button/VBoxContainer/Info/Description/RichTextLabel
@onready var playerChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var playerChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var playerChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/Info/Description/RichTextLabel
#Current Player Info
@onready var playerResource: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/Character/RichTextLabel
@onready var playerElement: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/Player1Element
@onready var playerPhyEle: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/PlayerPhyElement1
@onready var playerBattleStats: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/Stats/RichTextLabel
@onready var CPUText: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/RichTextLabel
@onready var CPUBar: TextureProgressBar = $VBoxContainer/HBoxContainer/CurrentCharChips/Button/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/EnemyTP

signal exitMenu

enum MenuTypes {DOCK, SUB, MOVING} 

var ChipIcon = preload("res://Icons/MenuIcons/icons-set-2_0000s_0029__Group_.png")
var InvMenu: Array[Array] = [[],[]]
var PlayMenu: Array[Array] = [[],[]]
var currentDock: int = 0
var side: int = 0
var num: int = 0
var playerIndex: int = 0
var CPUusage: int = 0
var currentMenu = MenuTypes.DOCK

#-----------------------------------------
#INITALIZATION AND PROCESSING
#-----------------------------------------
func _ready():
	InventoryFunctions.chipHandler()
	
	for chip in Globals.ChipInventory.inventory:
		var chipPanel = InvChipPanel.instantiate()
		chipPanel.chipData = chip
		chipPanel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPanel.connect("getDesc",on_inv_focused)
		chipInv.add_child(chipPanel)
		
		InvMenu[side].append(chipPanel)
		swap(side)
	
	side = 0
	Docks[0].grab_focus()
	
	getPlayerStats(playerIndex)
	getPlayerChips(playerIndex)

func _process(_delta):
	if Input.is_action_just_pressed("Left"):
		match currentMenu:
			MenuTypes.DOCK:
				swap(currentDock)
				Docks[currentDock].grab_focus()
			MenuTypes.SUB:
				pass
			MenuTypes.MOVING:
				pass
	
	if Input.is_action_just_pressed("Right"):
		match currentMenu:
			MenuTypes.DOCK:
				swap(currentDock)
				Docks[currentDock].grab_focus()
			MenuTypes.SUB:
				pass
			MenuTypes.MOVING:
				pass
	
	
	if Input.is_action_just_pressed("Accept"):
		match currentMenu:
			MenuTypes.DOCK:
				pass
			MenuTypes.SUB:
				pass
			MenuTypes.MOVING:
				pass
		
	if Input.is_action_just_pressed("Cancel"):
		match currentMenu:
			MenuTypes.DOCK:
				pass
			MenuTypes.SUB:
				pass
			MenuTypes.MOVING:
				pass
	
	if Input.is_action_just_pressed("ZL") or Input.is_action_just_pressed("ZR"):
		pass
	
	if Input.is_action_just_pressed("L"):
		playerIndex -= 1
		if playerIndex < 0:
			playerIndex = 2
		
		getPlayerStats(playerChips)
	
	if Input.is_action_just_pressed("R"):
		playerIndex += 1
		if playerIndex < 2:
			playerIndex = 0
		
		getPlayerStats(playerChips)
	
	if Input.is_action_just_pressed("X"):
		exitMenu.emit()
	
	if Input.is_action_just_pressed("Y"):
		pass

#-----------------------------------------
#INVENTORY DOCK
#-----------------------------------------

#-----------------------------------------
#PLAYER DOCK
#-----------------------------------------
func getPlayerStats(index):
	var entity = Globals.current_player_entities[index]
	var CPUtween = CPUBar.create_tween()
	var resourceString = str(Globals.charColor(entity)," [color=red]HP: ",entity.MaxHP,"[/color]"
	,"\n [color=aqua]LP:",entity.specificData.MaxLP," [/color][color=green]",
	entity.MaxTP,"[/color]")
	var stats = str("str: ",entity.strength,"\ttgh: ",entity.toughness,"\tspd: ",entity.speed,
	"\nbal: ",entity.ballistics,"\tres: ",entity.resistance,"\tluk: ",entity.luck)
	var currentCPUtext = str((entity.specificData.MaxCPU - CPUusage),"/",entity.specificData.MaxCPU,"\nCPU")
	
	playerResource.clear()
	playerBattleStats.clear()
	CPUText.clear()
	
	playerResource.append_text(resourceString)
	playerBattleStats.append_text(stats)
	CPUText.append_text(currentCPUtext)
	
	getElements(entity)
	
	var newValue = int(100*(float(entity.specificData.MaxCPU - CPUusage) / float(entity.specificData.MaxCPU)))
	CPUtween.tween_property(CPUBar, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)

func getPlayerChips(index):
	var entity = Globals.current_player_entities[index]
	for chip in entity.specificData.ChipData:
		var chipPannel = playerChipPanel.instantiate()
		entity.specificData.currentCPU += chip.CpuCost
		chipPannel.chipData = chip
		chipPannel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPannel.connect("getDesc",on_inv_focused)
		playerChips.add_child(chipPannel)
		
		PlayMenu[side].append(chipPannel)
		swap(side)
	
	side = 0

func getElements(entity):
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			playerElement.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			playerPhyEle.current_tab = k

func addChip():
	pass

func removeChip():
	pass

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func on_inv_focused(data):
	invChipTitle.clear()
	invChipTitle.append_text(str(data.chipData.name, " Chip"))
	
	invChipDetails.clear()
	invChipDetails.append_text(str("[center]",data.chipData.ChipType," Chip\nOwners:",
	data.currentPlayers,"[/center]"))
	
	invChipDisc.clear()
	invChipDisc.append_text(data.chipData.description)

#-----------------------------------------
#HELPER FUNCTIONS
#-----------------------------------------
func swap(value):
	if value == 0:
		value += 1
	else:
		value -= 1
