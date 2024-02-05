extends Control

@export var gearPanel: PackedScene
@export var inputButtonThreshold: float = 1.0
@export var scrollAmmount: int = 55
@export var scrollDeadzone: Vector2 = Vector2(280,420) #x is top value, y is bottom value

#Menu
@onready var gearInv: GridContainer = %Inventoryu
#Descriptions 
@onready var oldGearTitle: RichTextLabel = %OldTitle
@onready var oldGearDisc: RichTextLabel = %OldDec
@onready var newGearTitle: RichTextLabel = %NewTitle
@onready var newGearDisc: RichTextLabel = %NewDesc
#Current Player Info
@onready var playerResource: RichTextLabel = %NamenResource
@onready var playerElement: TabContainer = %Player1Element
@onready var playerPhyEle: TabContainer = %PlayerPhyElement1
@onready var playerBattleStats: RichTextLabel = %BattleStats
@onready var CPUText: RichTextLabel = %CPUTEXT
@onready var CPUBar: TextureProgressBar = %EnemyTP
@onready var ItemText: RichTextLabel = %ItemNum

signal chipMenu
signal gearMenu
signal itemMenu
signal exitMenu
signal makeNoise(num)

var allGear: Array[Array] = [[],[],[],[]]
var currentInv: Array[Array] = [[],[]]
var inputHoldTime: float = 0.0
var playerIndex: int = 0
var side: int = 0
var currentFocus

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	for gear in Globals.GearInventory.inventory:
		match gear.Char:
			"DREAMER": allGear[0].append(gear)
			"Lonna": allGear[1].append(gear)
			"Damir": allGear[2].append(gear)
			"Pepper": allGear[3].append(gear)
	
	update()

#-----------------------------------------
#PROCESSING
#-----------------------------------------
func _process(_delta):
	if (Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right") 
	or Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("Down")):
		makeNoise.emit(2)
	
	if Input.is_action_just_pressed("Accept"):
		makeNoise.emit(0)
		swapGear()
		get_viewport().gui_get_focus_owner()
	
	if Input.is_action_just_pressed("Cancel"):
		makeNoise.emit(1)
		Globals.currentSave.GearInventory = Globals.GearInventory
		exitMenu.emit()
	
	if Input.is_action_just_pressed("L"):
		makeNoise.emit(2)
		playerIndex -= 1
		if playerIndex < 0:
			playerIndex = Globals.every_player_entity.size() - 1
		
		update()
		if get_viewport().gui_get_focus_owner() == null:
			currentInv[0][0].focus.grab_focus()
	
	if Input.is_action_just_pressed("R"):
		makeNoise.emit(2)
		playerIndex += 1
		if playerIndex > Globals.every_player_entity.size() - 1:
			playerIndex = 0
		
		update()
		if get_viewport().gui_get_focus_owner() == null:
			currentInv[0][0].focus.grab_focus()
	
	#[chip,gear,item]
	if Input.is_action_just_pressed("ZL"):
		Globals.currentSave.GearInventory = Globals.GearInventory
		chipMenu.emit()
		
	if Input.is_action_just_pressed("ZR"):
		Globals.currentSave.GearInventory = Globals.GearInventory
		itemMenu.emit()

#-----------------------------------------
#MAIN DOCk
#-----------------------------------------
func getPlayerStats(index) -> void:
	var entity = Globals.getStats(Globals.every_player_entity[index], Globals.every_player_entity[index].name ,Globals.every_player_entity[index].level)
	var resourceString = str(Globals.charColor(entity),"\n[color=red]HP: ",entity.MaxHP,"[/color]"
	," [color=aqua]LP:",entity.specificData.MaxLP,"\n[/color][color=green] TP: ",
	entity.MaxTP,"[/color][color=yellow] CPU: ",entity.specificData.MaxCPU,"[/color]")
	var stats = str("[center]STRENGTH: ",entity.strength," \tTOUGHNESS: ",entity.toughness," \tSPEED: ",entity.speed,
	"\nBALLISTICS: ",entity.ballistics," \tRESISTANCE: ",entity.resistance," \tLUCK: ",entity.luck,"[/center]")
	var currentCPUtext = str((entity.specificData.MaxCPU - entity.specificData.currentCPU),"/",entity.specificData.MaxCPU,"\nCPU")
	var currentItemText = str("[center][color=gray]Items\n",entity.itemData.size(),"/4[/color]")
	
	playerResource.clear()
	playerBattleStats.clear()
	CPUText.clear()
	ItemText.clear()
	
	playerResource.append_text(resourceString)
	playerBattleStats.append_text(stats)
	CPUText.append_text(currentCPUtext)
	ItemText.append_text(currentItemText)
	
	CPUBar.value = int(100*(float(entity.specificData.MaxCPU - entity.specificData.currentCPU) / float(entity.specificData.MaxCPU)))
	
	getElements(entity)

func getPlayerGear(index) -> void:
	clearPlayerGear()
	
	var entity = Globals.every_player_entity[index]
	
	for gear in allGear[Globals.charNum(entity)]:
		var pannel = gearPanel.instantiate()
		pannel.gearData = gear
		pannel.chara = entity.name
		
		pannel.connect("getDesc",on_panel_focused)
		pannel.connect("getEquipped", on_equipped)
		gearInv.add_child(pannel)
		currentInv[side].append(pannel)
		
		side = swap(side)
	
	side = 0

func getGearDesc(gear) -> String:
	var entity = Globals.every_player_entity[playerIndex]
	var gearString
	
	if gear.Strength != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Strength"), gear.Strength, gearString, "Strength:\t")
	if gear.Toughness != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Toughness"), gear.Toughness, gearString, "Toughness:\t")
	if gear.Ballistics != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Ballistics"), gear.Ballistics, gearString, "Ballistics:\t")
	if gear.Resistance != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Resistance"), gear.Resistance, gearString, "Resistance:\t")
	if gear.Speed != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Speed"), gear.Speed, gearString, "Speed:\t")
	if gear.Luck != 0:
		gearString = statString(Globals.getBaseStats(entity.name,entity.level,"Luck"), gear.Luck, gearString, "Luck:\t")
	
	if gear.calcBonus & 1:
		gearString = str(ifStringEmpty(gearString),"\n[center]Drain HP by", gear.calcAmmount * 100,
		"% of your offensive damage\n CURRENT TOTAL:",entity.drainCalcAmmount * 100,"%[/center]")
	if gear.calcBonus & 2:
		gearString = str(ifStringEmpty(gearString),"\n[center]Raise chance to hit Ailments by", gear.calcAmmount * 100,
		"%\n CURRENT TOTAL: ",entity.ailmentCalcAmmount * 100,"%[/center]")
	if gear.calcBonus & 4:
		gearString = str(ifStringEmpty(gearString),"\n[center]Crit Chance Raised by", gear.calcAmmount * 100,
		"%\n CURRENT TOTAL: ",entity.critCalcAmmount * 100,"%[/center]")
	if gear.calcBonus & 8:
		gearString = str(ifStringEmpty(gearString),"\n[center]Everyone's Element modifier raised by", gear.calcAmmount * 100,
		"%\n CURRENT TOTAL: ",entity.groupElementMod * 100,"%[/center]")
	
	match gear.miscCalc:
		"Explode":
			gearString = str(ifStringEmpty(gearString),"\n[center]15% chance to explode after getting hit[/center]")
		"LPDrain":
			gearString = str(ifStringEmpty(gearString),"\n[center]Drain 10% of your offensive damage as LP[/center]")
		"DumbfoundedCrit":
			gearString = str(ifStringEmpty(gearString),"\n[center]Crits now apply Dumbfounded instead of XSoft[/center]")
	
	return gearString

func clearPlayerGear() -> void:
	for thing in gearInv.get_children():
		gearInv.remove_child(thing)
		thing.queue_free()

func getElements(entity) -> void:
	for k in range(4):
		if Globals.elementGroups[k] == entity.element: playerElement.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement: playerPhyEle.current_tab = k

func update() -> void:
	currentInv = [[],[]]
	for thing in gearInv.get_children(): #Delete previous inventory display
		gearInv.remove_child(thing)
		thing.queue_free()
	
	getPlayerGear(playerIndex)
	getPlayerStats(playerIndex)
	
	currentInv[0][0].focus.grab_focus()

#-----------------------------------------
#MANAGING GEAR
#-----------------------------------------
func swapGear():
	var entity = Globals.every_player_entity[playerIndex]
	if entity.specificData.GearData != null:
		entity.specificData.GearData.equipped = false
	InventoryFunctions.gearApply(entity, currentFocus.gearData)
	update()

#-----------------------------------------
#SIGNALS
#-----------------------------------------
func on_panel_focused(data) -> void:
	currentFocus = data
	newGearTitle.clear()
	newGearDisc.clear()
	
	newGearTitle.append_text(str("[center][u]VIEWING GEAR[/u]\n",data.gearData.name,"[/center]"))
	newGearDisc.append_text(str(getGearDesc(data.gearData)))

func on_equipped(data) -> void:
	oldGearTitle.clear()
	oldGearDisc.clear()
	
	oldGearTitle.append_text(str("[center][u]CURRENT GEAR[/u]\n",data.gearData.name,"[/center]"))
	oldGearDisc.append_text(str(getGearDesc(data.gearData)))

#-----------------------------------------
#HELPER FUNCTIONS
#-----------------------------------------
func swap(value) -> int:
	if value == 0: value += 1
	else: value -= 1
	return value

func statString(playerStat, stat, string, statName) -> String:
	var tempString = str(statName, playerStat)
	
	string = ifStringEmpty(string)
	
	if stat > 0:
		tempString = str(tempString," + [color=red]", stat, "[/color]")
	else:
		tempString = str(tempString," - [color=aqua]", -1 * stat, "[/color]")
	
	return str(string, tempString)

func ifStringEmpty(string) -> String:
	if string != null:
		string = str(string,"\n")
	else:
		string = str("")
	return str(string)
