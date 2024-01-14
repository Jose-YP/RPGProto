extends Control

@export var InvChipPanel: PackedScene
@export var playerChipPanel: PackedScene
@export var scrollAmmount: int = 55
@export var scrollDeadzone: Vector2 = Vector2(280,420) #x is top value, y is bottom value
#Menus
@onready var chipInv: GridContainer = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/ChipSelection/GridContainer
@onready var playerChips: GridContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CurrentChips/PanelContainer
@onready var InvMarkers: Array[Marker2D] = []
@onready var PlayMarkers: Array[Marker2D] = []
@onready var Arrow: Sprite2D = $Arrow
@onready var placeholderPos: Marker2D = $Marker2D
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
var acrossPlayers: bool = false
var keepFocus
var grabbedChip

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	emit_signal("chipMenu")
	InventoryFunctions.chipHandler()
	
	getChipInventory()
	
	getPlayerStats(playerIndex)
	getPlayerChips(playerIndex)
	
	InvMenu[0][0].focus.grab_focus()

#-----------------------------------------
#PROCESSING
#-----------------------------------------
func _process(_delta):
	movement()
	buttons()
	if movingChip:
		keepFocus.grab_focus()
		if Arrow.global_position.y < scrollDeadzone.x:
			scrollUp()
			Arrow.global_position = markerArray[side][markerIndex].global_position
		elif Arrow.global_position.y > scrollDeadzone.y:
			scrollDown()
			Arrow.global_position = markerArray[side][markerIndex].global_position

func movement():
	if Input.is_action_just_pressed("Left"):
		if movingChip:
			makeNoise.emit(2)
			if markerIndex%2 == 0 and markerIndex != 0:
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
			if markerIndex%2 == 0:
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
			print(markerArray[side][markerIndex].get_parent() is Panel)
			if markerArray[side][markerIndex] == placeholderPos or markerArray[side][markerIndex].get_parent().inChar:
				if keepFocus.get_parent().inChar:
					print("Sort Player inventory")
				else:
					print("Place in character", markerArray[side][markerIndex].get_parent().inChar)
					addChip(grabbedChip)
			else:
				if keepFocus.get_parent().inChar:
					print("Removed from character", markerArray[side][markerIndex].get_parent().inChar)
					removeChip(grabbedChip)
				else:
					print("Sort Inventory", markerArray[side][markerIndex].get_parent().inChar)
			
			
			movingChip = false
			print(grabbedChip)
			Arrow.hide()
		
		else:
			keepFocus = get_viewport().gui_get_focus_owner()
			if keepFocus is OptionButton:
				pass
			else:
				movingChip = true
				var adress = getButtonIndex(keepFocus)
				side = adress.x
				markerIndex = adress.y
				
				Arrow.global_position = get_viewport().gui_get_focus_owner().get_parent().inBetween.global_position
				Arrow.show()
		
	if Input.is_action_just_pressed("Cancel"):
		makeNoise.emit(1)
		if movingChip:
			movingChip = false
			Arrow.hide()
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
		
		if movingChip:
			pass
		
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

#-----------------------------------------
#INVENTORY DOCK
#-----------------------------------------
func getChipInventory():
	for chip in Globals.ChipInventory.inventory:
		var chipPanel = InvChipPanel.instantiate()
		chipPanel.ChipData = chip
		chipPanel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPanel.connect("getDesc",on_inv_focused)
		chipInv.add_child(chipPanel)
		
		InvMenu[side].append(chipPanel)
		InvMarkers.append(chipPanel.inBetween)
		side = swap(side)
	
	InvMarkers.append(InvMenu[side][-1].final)
	side = 0

func update():
	InvMenu = [[],[]]
	InvMarkers = []
	for thing in chipInv.get_children():
		chipInv.remove_child(thing)
		thing.queue_free()
	
	getPlayerStats(playerIndex)
	getChipInventory()
	getPlayerChips(playerIndex)

func manualSort():
	pass

#-----------------------------------------
#PLAYER DOCK
#-----------------------------------------
func getPlayerStats(index):
	var entity = Globals.getStats(Globals.every_player_entity[index], Globals.every_player_entity[index].name ,Globals.every_player_entity[index].level)
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
	InventoryFunctions.miniChipHandler(entity.name,entity.specificData.ChipData)

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
	
	print(PlayMenu)
	if PlayMenu[side].size() == 0:
		PlayMarkers.append(placeholderPos)
	else:
		PlayMarkers.append(PlayMenu[side][-1].final)
	side = 0
	markerArray = [InvMarkers,PlayMarkers]

func clearPlayerChips():
	PlayMenu = [[],[]]
	PlayMarkers = []
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

func addChip(chip):
	var entity = Globals.every_player_entity[playerIndex]
	
	if chip.CpuCost < (entity.specificData.MaxCPU - entity.specificData.currentCPU):
		print("applied", chip.name)
		entity.specificData.ChipData.append(chip)
		update()

func removeChip(chip):
	var entity = Globals.every_player_entity[playerIndex]
	print("removed", chip.name)
	entity.specificData.ChipData.erase(chip)
	print(entity.specificData.ChipData)
	update()
	InvMenu[0][0].focus.grab_focus()

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func on_inv_focused(data):
	makeNoise.emit(2)
	grabbedChip = data.ChipData
	
	invChipTitle.clear()
	invChipTitle.append_text(str(data.ChipData.name, " Chip"))
	
	invChipDetails.clear()
	invChipDetails.append_text(str("[center]",data.ChipData.ChipType," Chip\nOwners:",
	data.currentPlayers,"[/center]"))
	
	invChipDisc.clear()
	invChipDisc.append_text(data.ChipData.description)

func on_play_focused(data):
	makeNoise.emit(2)
	grabbedChip = data.ChipData
	
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

func scrollUp() -> void:
	if side == 0:
		chipInv.get_parent().scroll_vertical -= scrollAmmount
	else:
		playerChips.get_parent().scroll_vertical -= scrollAmmount

func scrollDown() -> void:
	if side == 0:
		chipInv.get_parent().scroll_vertical += scrollAmmount
	else:
		playerChips.get_parent().scroll_vertical += scrollAmmount

func getButtonIndex(searching) -> Vector2:
	var menu: Array
	var found: int
	var locSide: int
	var dock: int
	
	searching = searching.get_parent()
	if searching.inChar:
		menu = InvMenu
		dock = 0
	else:
		menu = PlayMenu
		dock = 1
	
	for adress in range(menu.size()):
		for button in range(menu[adress].size()):
			if menu[adress][button] == searching:
				print("Found in, ",adress, "|", button)
				found = button * 2
				locSide = adress
				break
	
	if locSide == 1:
		found += 1
	
	return Vector2(dock, found)
