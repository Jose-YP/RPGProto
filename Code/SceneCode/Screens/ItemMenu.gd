extends Control

@export var InvItemPanel: PackedScene
@export var playerItemPanel: PackedScene
@export var itemLimit: int = 8 #Might formally be 8 if I can implement 8 moves in a menu option
@export var inputButtonThreshold: float = 0.5
@export var scrollAmmount: int = 55
@export var scrollDeadzone: Vector2 = Vector2(280,420) #x is top value, y is bottom value
#Menus
@onready var itemInv: GridContainer = $VBoxContainer/HBoxContainer/ItemSelection/VBoxContainer/ChipSelection/GridContainer
@onready var playerItems: GridContainer = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CurrentItems/PanelContainer
@onready var InvMarkers: Array[Marker2D] = []
@onready var PlayMarkers: Array[Marker2D] = []
@onready var Arrow: Sprite2D = $Arrow
@onready var placeholderPos: Marker2D = $Marker2D
@onready var sortingOptions: OptionButton = $VBoxContainer/HBoxContainer/ItemSelection/VBoxContainer/INVENTORYTEXT/HBoxContainer/MarginContainer/Panel/OptionButton
@onready var insertNumPanel = $InsertNumber
#Descriptions
@onready var invItemTitle: RichTextLabel = $VBoxContainer/HBoxContainer/ItemSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var invItemDetails: RichTextLabel = $VBoxContainer/HBoxContainer/ItemSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var invItemDisc: RichTextLabel = $VBoxContainer/HBoxContainer/ItemSelection/VBoxContainer/Info/Description/RichTextLabel
@onready var playerItemTitle: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var playerItemDetails: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var playerItemDisc: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/Info/MarginContainer/Description/RichTextLabel
#Current Player Info
@onready var playerResource: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CharacterInfo/Character/RichTextLabel
@onready var playerElement: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CharacterInfo/Player1Element
@onready var playerPhyEle: TabContainer = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CharacterInfo/PlayerPhyElement1
@onready var playerBattleStats: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CharacterInfo/Stats/RichTextLabel
@onready var ItemText: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharItems/VBoxContainer/CharacterInfo/ItemBox/HBoxContainer/RichTextLabel

signal gearMenu
signal chipMenu
signal itemMenu
signal exitMenu
signal sort(type)
signal makeNoise(num)

var InvMenu: Array[Array] = [[],[]]
var PlayMenu: Array[Array] = [[],[]]
var currentInv: Array = []
var markerArray: Array = []
var markerIndex: int = 0
var side: int = 0
var num: int = 0
var playerIndex: int = 0
var tempIndex: int = 0
var inputHoldTime: float = 0.0
var choosingNum: bool = false
var movingItem: bool = false
var acrossPlayers: bool = false
var keepFocus
var grabbedItem
var wasChar

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	emit_signal("itemMenu")
	
	currentInv = Globals.ItemInventory.inventory
	InventoryFunctions.itemHandler(currentInv)
	getPlayerStats(playerIndex)
	getPlayerItems(playerIndex)
	getItemInventory()
	
	InvMenu[0][0].focus.grab_focus()

#-----------------------------------------
#PROCESSING
#-----------------------------------------
func _process(delta):
	if get_viewport().gui_get_focus_owner() == null: InvMenu[0][0].focus.grab_focus()
	if movingItem: movement()
	buttons()
	
	if movingItem or choosingNum:
		if not acrossPlayers or (acrossPlayers and tempIndex == playerIndex): keepFocus.grab_focus()
		if Arrow.global_position.y < scrollDeadzone.x:
			scrollUp()
			Arrow.global_position = markerArray[side][markerIndex].global_position
		elif Arrow.global_position.y > scrollDeadzone.y:
			scrollDown()
			Arrow.global_position = markerArray[side][markerIndex].global_position
		
		if Input.get_vector("Left", "Right", "Up", "Down") == Vector2(0.0,0.0): inputHoldTime = 0.0
		else: inputHoldTime += delta
		insertNumPanel.holding = inputHoldTime

func movement() -> void:
	var held: bool = (inputHoldTime == 0.0 or inputHoldTime > inputButtonThreshold)
	
	if Input.is_action_pressed("Left") and held:
		makeNoise.emit(2)
		if markerIndex%2 == 0 and markerIndex != 0: side = swap(side)
		else: markerIndex -= 1
		
		if markerIndex < 0:
			if side == 1:
				side = swap(side)
				markerIndex = 1
			else: markerIndex = 0
			
		if markerIndex > (markerArray[side].size() - 1): markerIndex = markerArray[side].size() - 1
		
		Arrow.global_position = markerArray[side][markerIndex].global_position
	
	if Input.is_action_pressed("Right") and held:
		markerIndex += 1
		if markerIndex > (markerArray[side].size() - 1): markerIndex = markerArray[side].size() - 1
		elif markerIndex%2 == 0 and markerArray[side][markerIndex].name != "Marker2D2":
			side = swap(side)
			markerIndex -= 2
			if markerIndex > (markerArray[side].size() - 1): markerIndex = markerArray[side].size() - 1
		
		Arrow.global_position = markerArray[side][markerIndex].global_position
	
	if Input.is_action_pressed("Up") and held:
		markerIndex -= 2
		if markerIndex < 0: markerIndex = 0
		
		Arrow.global_position = markerArray[side][markerIndex].global_position
	
	if Input.is_action_pressed("Down") and held:
		markerIndex += 2
		if markerArray[side][markerIndex].name == "Marker2D2": markerIndex -= 2
		if markerIndex > (markerArray[side].size() - 1): markerIndex = markerArray[side].size() - 1
		
		Arrow.global_position = markerArray[side][markerIndex].global_position

func buttons() -> void:
	if Input.is_action_just_pressed("Accept"):
		makeNoise.emit(0)
		
		if movingItem:
			if markerArray[side][markerIndex] == placeholderPos or markerArray[side][markerIndex].get_parent().inChar:
				if wasChar: sortPlayerItem(grabbedItem)
				elif acrossPlayers: sortPlayerItem(grabbedItem)
				else: addItem(grabbedItem)
					
			elif wasChar: removeItem(grabbedItem)
			
			
			movingItem = false
			setFocus(true)
			Arrow.hide()
		
		elif choosingNum:
			keepFocus = get_viewport().gui_get_focus_owner()
			movingItem = true
			setFocus(false)
			insertNumPanel.using = false
			choosingNum = false
			num = insertNumPanel.ammount.value
			insertNumPanel.hide()
			
			Arrow.global_position = get_viewport().gui_get_focus_owner().get_parent().inBetween.global_position
			Arrow.show()
		
		else:
			keepFocus = get_viewport().gui_get_focus_owner()
			choosingNum = true
			insertNumPanel.using = true
			
			var adress = getButtonIndex(keepFocus)
			side = adress.x
			markerIndex = adress.y
			
			wasChar = keepFocus.get_parent().inChar
			
			insertNumPanel.show()
			insertNumPanel.global_position = keepFocus.global_position + Vector2(150,0)
			insertNumPanel.maxNum = keepFocus.get_parent().itemData.maxItems
		
	if Input.is_action_just_pressed("Cancel"):
		makeNoise.emit(1)
		if movingItem:
			movingItem = false
			setFocus(true)
			Arrow.hide()
		elif choosingNum:
			insertNumPanel.using = false
			choosingNum = false
			insertNumPanel.hide()
			
		else: exitMenu.emit()
	
	if Input.is_action_just_pressed("X"): setAutofill(grabbedItem)
	
	if Input.is_action_just_pressed("Y"):
		sort.emit("Item")
		makeNoise.emit(1)
		var select = sortingOptions.selected
		print(select)
		select += 1
		if select >= 3: select = 0
		sortingOptions.select(select)
		sortingOptions.item_selected.emit(select)
	
	if not choosingNum:
		if Input.is_action_just_pressed("L"):
			makeNoise.emit(2)
			if movingItem:
				tempIndex = playerIndex
				acrossPlayers = true
				keepFocus.release_focus()
				if side == 1: markerIndex = 0
			
			playerIndex -= 1
			if playerIndex < 0: playerIndex = Globals.every_player_entity.size() - 1
			
			getPlayerStats(playerIndex)
			getPlayerItems(playerIndex)
			
			if get_viewport().gui_get_focus_owner() == null and not acrossPlayers and not PlayMenu[0][0] == null:
				PlayMenu[0][0].focus.grab_focus()
		
		if Input.is_action_just_pressed("R"):
			makeNoise.emit(2)
			if movingItem:
				tempIndex = playerIndex
				acrossPlayers = true
				if side == 1: markerIndex = 0
			
			playerIndex += 1
			if playerIndex > (Globals.every_player_entity.size() - 1): playerIndex = 0
			
			getPlayerStats(playerIndex)
			getPlayerItems(playerIndex)
			
			if get_viewport().gui_get_focus_owner() == null and not acrossPlayers and not PlayMenu[0][0] == null:
				PlayMenu[0][0].focus.grab_focus()
	
	#[chip,gear,item]
	if not movingItem: #ZR and ZL
		if Input.is_action_just_pressed("ZL"): gearMenu.emit()
		if Input.is_action_just_pressed("ZR"): chipMenu.emit()

#-----------------------------------------
#INVENTORY DOCK
#-----------------------------------------
func getItemInventory() -> void:
	for item in currentInv:
		var itemPanel = InvItemPanel.instantiate()
		itemPanel.itemData = item
		itemPanel.maxNum = item.maxCarry
		itemPanel.connect("getDesc",on_inv_focused)
		itemInv.add_child(itemPanel)
		itemPanel.focus.set_focus_mode(2)
		
		InvMenu[side].append(itemPanel)
		InvMarkers.append(itemPanel.inBetween)
		side = swap(side)
	
	side = 0

func update() -> void:
	InvMenu = [[],[]]
	InvMarkers = []
	var prevKeep
	
	if keepFocus == null:
		print("CCC")
		prevKeep = get_viewport().gui_get_focus_owner().get_parent().itemData
	
	for thing in itemInv.get_children(): #Delete previous inventory display
		if movingItem and thing == keepFocus.get_parent():
			prevKeep = thing.itemData
		itemInv.remove_child(thing)
		thing.queue_free()
	
	getPlayerStats(playerIndex)
	getPlayerItems(playerIndex)
	getItemInventory()
	
	for thing in itemInv.get_children():
		if thing.itemData == prevKeep: 
			print(thing.itemData.name)
			keepFocus = thing.focus
	
	acrossPlayers = false
	if movingItem and keepFocus != null:
		print("BBB")
		keepFocus.grab_focus()
	else:
		print("AAA")
		InvMenu[0][0].focus.grab_focus()

#-----------------------------------------
#PLAYER DOCK
#-----------------------------------------
func getPlayerStats(index) -> void:
	var entity = Globals.getStats(Globals.every_player_entity[index], Globals.every_player_entity[index].name ,Globals.every_player_entity[index].level)
	var resourceString = str(Globals.charColor(entity)," [color=red]HP: ",entity.MaxHP,"[/color]"
	,"\n [color=aqua]LP:",entity.specificData.MaxLP," [/color][color=green] TP: ",
	entity.MaxTP,"[/color][color=yellow] CPU: ",entity.specificData.MaxCPU,"[/color]")
	var stats = str("STR: ",entity.strength," \tTGH: ",entity.toughness," \tSPD: ",entity.speed,
	"\nBAL: ",entity.ballistics," \tRES: ",entity.resistance," \tLUK: ",entity.luck)
	var curremtItemText = str("[center][color=gray]Items",entity.itemData.size(),"/",itemLimit,"[/color]")
	
	playerResource.clear()
	playerBattleStats.clear()
	ItemText.clear()
	
	playerResource.append_text(resourceString)
	playerBattleStats.append_text(stats)
	ItemText.append_text(curremtItemText)
	
	getElements(entity)
	InventoryFunctions.miniItemHandler(entity.name,entity.itemData, currentInv)

func getPlayerItems(index) -> void:
	clearPlayerItems()
	
	var entity = Globals.every_player_entity[index]
	var entityNum = Globals.charNum(entity)
	
	for item in entity.itemData:
		var itemPannel = playerItemPanel.instantiate()
		itemPannel.itemData = item
		itemPannel.maxNum = item.maxItems
		itemPannel.currentNum = item.ownerArray[entityNum]
		if item.autofill & Globals.charFlag(entity): itemPannel.autofillOn = true
		
		itemPannel.connect("getDesc",on_play_focused)
		playerItems.add_child(itemPannel)
		
		PlayMenu[side].append(itemPannel)
		PlayMarkers.append(itemPannel.inBetween)
		
		side = swap(side)
	
	if PlayMenu[0].size() == 0:
		PlayMarkers.append(placeholderPos)
	else:
		PlayMarkers.append(PlayMenu[swap(side)][PlayMenu[side].size() - 1].final)
	side = 0
	markerArray = [InvMarkers,PlayMarkers]

func clearPlayerItems() -> void:
	PlayMenu = [[],[]]
	PlayMarkers = []
	for thing in playerItems.get_children():
		playerItems.remove_child(thing)
		thing.queue_free()

func getElements(entity) -> void:
	for k in range(4):
		if Globals.elementGroups[k] == entity.element: playerElement.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement: playerPhyEle.current_tab = k

func setAutofill(item) -> void:
	var entity = Globals.every_player_entity[playerIndex]
	var charaFlag = Globals.charFlag(entity)
	var autofilled = item.autofill & charaFlag
	
	if entity.itemData.size() < itemLimit and not autofilled:
		InventoryFunctions.itemAutofill(item, entity.name, true)
		InventoryFunctions.applyAutofill(entity, item)
		update()
	elif autofilled or InventoryFunctions.findItem(item, entity) != 90:
		InventoryFunctions.itemAutofill(item, entity.name, not autofilled)
		update()

func addItem(item) -> void:
	var entity = Globals.every_player_entity[playerIndex]
	var sameItemIndex = InventoryFunctions.findItem(item, entity)
	if acrossPlayers: entity = Globals.every_player_entity[tempIndex]
	
	if sameItemIndex != 90:
		entity.itemData[item] += num
		update()
	elif entity.itemData.size() < itemLimit:
		entity.itemData[item] = num
		update()

func removeItem(item) -> void:
	var entity = Globals.every_player_entity[playerIndex]
	if acrossPlayers: entity = Globals.every_player_entity[tempIndex]
	
	entity.itemData[item] -= num
	
	if entity.itemData[item] == 0:
		entity.itemData.erase(item)
		InventoryFunctions.itemAutofill(item, entity.name, false)
		InventoryFunctions.itemHandlerResult(item,0,entity.name,false)
	update()

func sortPlayerItem(item) -> void:
	var entity = Globals.every_player_entity[playerIndex]
	
	if acrossPlayers and entity.itemData.size() < itemLimit:
		removeItem(item)
		addItem(item)
	
	update()

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func on_inv_focused(data) -> void:
	makeNoise.emit(2)
	grabbedItem = data.itemData
	
	invItemTitle.clear()
	invItemTitle.append_text(str("[center]",data.itemData.name,"\nCurrent Total: ", data.itemData.currentItems,"[/center]"))
	
	invItemDetails.clear()
	invItemDetails.append_text(str("[center]OWNERS\n",
	data.currentPlayers,"[/center]"))
	
	invItemDisc.clear()
	invItemDisc.append_text(data.itemData.attackData.description)

func on_play_focused(data) -> void:
	makeNoise.emit(2)
	grabbedItem = data.itemData
	
	playerItemTitle.clear()
	playerItemTitle.append_text(str("[center]",data.itemData.name, "\nCurrent Total: ", data.itemData.currentItems,"[/center]"))
	
	playerItemDetails.clear()
	playerItemDetails.append_text(str("[center]OWNING\n",
	data.currentNum,"/",data.maxNum,"[/center]"))
	
	playerItemDisc.clear()
	playerItemDisc.append_text(data.itemData.attackData.description)

func _on_option_button_item_selected(index) -> void:
	makeNoise.emit(0)
	var newSort = sortingOptions.get_item_text(index)
	match newSort:
		"Sort Alpha": currentInv = Globals.ItemInventory.inventory
		"Sort Owners": currentInv = Globals.ItemInventory.inventorySort1
		"Sort Leftover": currentInv = Globals.ItemInventory.inventorySort2
	
	update()

func _on_insert_number_make_noise() -> void:
	makeNoise.emit(2)

#-----------------------------------------
#HELPER FUNCTIONS
#-----------------------------------------
func swap(value) -> int:
	if value == 0: value += 1
	else: value -= 1
	return value

func scrollUp() -> void:
	if side == 0: itemInv.get_parent().scroll_vertical -= scrollAmmount
	else: playerItems.get_parent().scroll_vertical -= scrollAmmount

func scrollDown() -> void:
	if side == 0: itemInv.get_parent().scroll_vertical += scrollAmmount
	else: playerItems.get_parent().scroll_vertical += scrollAmmount

func setFocus(value: bool) -> void:
	if side == 0: itemInv.get_parent().set_follow_focus(value)
	else: playerItems.get_parent().set_follow_focus(value)

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
				found = button * 2
				locSide = adress
				break
	
	if locSide == 1: found += 1
	
	return Vector2(dock, found)
