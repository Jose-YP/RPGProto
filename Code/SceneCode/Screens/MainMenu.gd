extends Control

@export var enemyEntities: Array[entityData]

#PLAYER VARIABLES
@onready var playerChoices: Array[OptionButton] = [%PlayerMenu1, %PlayerMenu2, %PlayerMenu3]
@onready var playerLevels: Array[SpinBox] = [%Player1Level, %Player2Level, %Player3Level]
@onready var playerStats: Array[RichTextLabel] = [%Stats1, %Stats2, %Stats3]
@onready var playerElements: Array[TabContainer] = [%PlayerElement1, %PlayerElement2, %PlayerElement3]
@onready var playerPhyEle: Array[TabContainer] = [%PlayerPhyElement1, %PlayerPhyElement2, %PlayerPhyElement3]
#ENEMY VARIABLES
@onready var enemyChoices: Array[OptionButton] = [%EnemyChoice1, %EnemyChoice2, %EnemyChoice3]
@onready var enemiesShown: RichTextLabel = $EnemySide/EnemyLineup/RichTextLabel
@onready var enemyElements: Array[TabContainer] = [%EnemyElement, %EnemyElement2, %EnemyElement3]
@onready var enemyPhyEle: Array[TabContainer] = [%EnemyPhyElement, %EnemyPhyElement2, %EnemyPhyElement3]
#OTHER VAR
@onready var orderButton: CheckButton = $PlayerFirstToggle/HBoxContainer/PlayerOrder
@onready var musicButton: OptionButton = $Navigation/MusicMenu/MenuButton

signal battleStart
signal chipMenu
signal gearMenu
signal itemMenu
signal makeNoise(num)
signal playTest(song)

var Battle: PackedScene = load("res://Scene/Mains/Main.tscn")
const songList: Array[String] = ["res://Audio/Music/15-Blaire-Dame.wav","res://Audio/Music/Delve!!!.wav",
"res://Audio/Music/178.-Boss-Battle.wav"]
const testSong = "res://Audio/Music/005 - WIFI Menu.mp3"
const playerNamesHold: Array[String] = ["DREAMER","Lonna","Damir","Pepper"]
var playerEntities: Array[entityData]
var playerLevelsHold: Array[int] = [5,5,5,5]
var players: Array[entityData] = [null, null, null]
var enemies: Array[entityData] = [null, null, null]
var optionsOpen: bool = false
var helpOpen: bool = false
var trueReady: bool = false

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	playerEntities = Globals.currentSave.every_player_entity
	var inactiveFound: int = 0
	
	for i in range(3):
		var playerNum = Globals.currentSave.current_party[i]
		playerChoices[i].selected = playerNum
		playerLevels[i].value = Globals.currentSave.every_player_entity[playerNum].level
		playerDescriptions(playerStats[i],i)
	for menu in (playerChoices + enemyChoices):
		menu.connect("pressed",_on_menu_button_pressed)
	
	for player in range(playerEntities.size()):
		var atLeatOne: bool = false
		playerLevelsHold[player] = playerEntities[player].level
		for check in Globals.currentSave.current_party:
			if playerEntities[player].name == Globals.currentSave.every_player_entity[check].name:
				atLeatOne = true
				break
		if not atLeatOne:
			if Globals.inactive_player_entities.size() < inactiveFound + 1:
				Globals.inactive_player_entities.append(playerEntities[player])
			else:
				Globals.inactive_player_entities[inactiveFound] = playerEntities[player]
			inactiveFound += 1
	
	setPlayerGlobals()
	makeEnemyLineup()
	
	$Navigation/Buttons/ItemButton.grab_focus()
	trueReady = true

func _process(_delta):
	if not optionsOpen and not helpOpen:
		if Input.is_action_just_pressed("Accept"):
			if get_viewport().gui_get_focus_owner() is OptionButton:
				get_viewport().gui_get_focus_owner().show_popup()
			else:
				print("AA")
				print(get_viewport().gui_get_focus_owner())
				get_viewport().gui_get_focus_owner().emit_signal("pressed")
		
		if Input.is_action_just_pressed("Cancel"):
			_on_help_button_pressed()
		
		if Input.is_action_just_pressed("Y"):
			var currentSelect = musicButton.selected
			if currentSelect + 1 > musicButton.item_count - 1:
				musicButton.selected = 0
			else:
				musicButton.selected += 1
		
		if Input.is_action_just_pressed("X"):
			print(not orderButton.button_pressed)
			orderButton.toggled.emit(not orderButton.button_pressed)
			orderButton.button_pressed = not orderButton.button_pressed
			
		if Input.is_action_just_pressed("Start"):
			_on_fight_button_pressed()
		
		if Input.is_action_just_pressed("Select"):
			_on_option_button_pressed()
	else:
		if Input.is_action_just_pressed("Accept"):
			print("AFUEUIEU")
	
	if helpOpen:
		if Input.is_anything_pressed():
			_on_exit_button_pressed()

#-----------------------------------------
#PLAYER SETUP
#-----------------------------------------
func playerDescriptions(description,i) -> void:
	var level = playerLevels[i].value
	var currentName = playerChoices[i].get_item_text(playerChoices[i].selected)
	description.clear()
	description.append_text(makePlayerDesc(i,playerChoices[i].selected,currentName,level))
	players[i] = playerEntities[playerChoices[i].selected]

func makePlayerDesc(index,playerNum,currentName,level) -> String:
	var entity = Globals.getStats(playerEntities[playerNum],currentName,str(level))
	var foundRes = false
	var resist: String
	var skillString: String
	var itemString: String
	var description: String
	var skills = entity.skillData
	var items = entity.itemData
	var charName = str("[",entity.species,"]\nlv.",level, Globals.charColor(entity))
	
	var resourceStats = str("[color=red]HP: ",entity.MaxHP,"[/color]\n[color=aqua]LP: ",
	entity.specificData.MaxLP,"[/color]\n[color=green]TP:", entity.MaxTP,"[/color]\n[color=yellow]"
	,"CPU:",entity.specificData.MaxCPU,"[/color]")
	
	var stats = str("str: ",entity.strength,"\ttgh: ",entity.toughness,"\tspd: ",entity.speed,
	"\nbal: ",entity.ballistics,"\tres: ",entity.resistance,"\tluk: ",entity.luck)
	
	players[index] = entity.duplicate()
	
	for i in range(6):
		#Flag is the binary version of i
		var flag = 1 << i
		if flag & entity.Resist:
			foundRes = true
			resist = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),resist)
	if foundRes:
		resist = str("Res: ", resist)
	
	for move in skills:
		if skillString != "":
			skillString = str(skillString,",",move.name)
		else:
			skillString = str(move.name)
	for item in items:
		if itemString != "":
			itemString = str(itemString,",","[i][",entity.itemData.get(item),"/",item.maxItems,"][/i]",item.name)
		else:
			itemString = str("[i][",entity.itemData.get(item),"/",item.maxItems,"][/i]",item.name)
	
	if skillString != "":
		skillString = str("Moves: ", skillString)
	if itemString != "":
		itemString = str("Items:", itemString)
	
	getElements(entity,playerElements[index],playerPhyEle[index])
	
	playerEntities[playerNum] = entity
	Globals.currentSave.every_player_entity[playerNum] = entity
	description = str(charName,"\n",resourceStats,"\n",resist,"\n",stats,"\n",skillString,"\n\n",itemString)
	
	return description

func playerChoiceChanged(playerIndex,infoIndex) -> void: #First is for playerNames second is for playerChoices
	makeNoise.emit(0)
	playerStats[infoIndex].clear()
	var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
	var level = getLevel(currentName)
	noRepeats(currentName, infoIndex)
	playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))
	playerLevels[infoIndex].value = level

func levelChange(level,infoIndex) -> void:
	if trueReady:
		makeNoise.emit(2)
		playerStats[infoIndex].clear()
		var playerIndex = playerChoices[infoIndex].selected
		var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
		playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))
		saveLevels(currentName,level)

#-----------------------------------------
#PLAYER HELPERS
#-----------------------------------------
func noRepeats(currentName, infoIndex) -> void:
	var result: bool = true
	var hold = players[infoIndex]
	var prevIndex: int = getOldIndex(hold.name)
	var prevLevel = getLevel(hold.name)
	
	for index in range(players.size()):
		if index == infoIndex:
			continue
		
		if players[index].name == currentName:
			result = false
			playerStats[index].clear()
			playerChoices[index].select(prevIndex)
			playerStats[index].append_text(makePlayerDesc(index,prevIndex,hold.name,prevLevel))
			
			playerLevels[index].value = prevLevel
	
	if result:
		setInactivePlayer(hold)

func saveLevels(chara,level) -> void:
	for playerIndex in range(playerNamesHold.size()):
		if playerNamesHold[playerIndex] == chara:
			playerLevelsHold[playerIndex] = int(level)

func getLevel(chara) -> int:
	for playerIndex in range(playerNamesHold.size()):
		if playerNamesHold[playerIndex] == chara:
			return playerLevelsHold[playerIndex]
	
	return 5

func setPlayerGlobals() -> void:
	Globals.current_player_entities = []
	Globals.current_player_entities = players #This has order for battles
	
	for player in range(players.size()): #Make sure players are updated into their correct positions
		var charNum =  Globals.charNum(players[player])
		Globals.currentSave.current_party[player] = charNum
		Globals.currentSave.every_player_entity[charNum] = players[player]
	
	for player in range(Globals.inactive_player_entities.size()):
		var charNum =  Globals.charNum(Globals.inactive_player_entities[player])
		Globals.currentSave.every_player_entity[charNum] = Globals.inactive_player_entities[player]
	
	Globals.every_player_entity = players + Globals.inactive_player_entities

func setInactivePlayer(held) -> void:
	Globals.inactive_player_entities[0] = held

func getOldIndex(prevName: String) -> int:
	match prevName:
		"DREAMER": return 0
		"Lonna": return 1
		"Damir": return 2
		"Pepper": return 3
	
	return 10

#-----------------------------------------
#ENEMY SETUP
#-----------------------------------------
func makeEnemyLineup() -> void:
	enemiesShown.clear()
	var enLiString: String
	for i in range(enemyChoices.size()):
		var enemyEntity
		if enemyChoices[i].selected != 6:
			enemyElements[i].show()
			enemyPhyEle[i].show()
			enemyEntity  = enemyEntities[enemyChoices[i].selected].duplicate()#enemyChoices[i].get_item_text(enemyChoices[i].selected)
			enLiString = str(enLiString, i+1,". ","[",enemyEntity.species,"]\t",enemyEntity.name,"\n\n\n")
			getElements(enemyEntities[enemyChoices[i].selected],enemyElements[i],enemyPhyEle[i])
		else:
			enemyElements[i].hide()
			enemyPhyEle[i].hide()
	
	enemiesShown.append_text(enLiString)

func setEnemyGlobals() -> void:
	Globals.current_enemy_entities = []
	for i in range(3):
		if enemyChoices[i].selected != 6:
			Globals.current_enemy_entities.append(enemyEntities[enemyChoices[i].selected])

func enemyChoiceChanged(_index) -> void:
	makeNoise.emit(0)
	makeEnemyLineup()

#-----------------------------------------
#GENERAL SETUP
#-----------------------------------------
func getElements(entity,ElementTab,PhyEleTab) -> void:
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			ElementTab.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			PhyEleTab.current_tab = k

#-----------------------------------------
#MISC TOGGLES
#-----------------------------------------
func _on_player_order_toggled(button_pressed: bool) -> void:
	Globals.playerFirst = button_pressed
	if button_pressed:
		$PlayerFirstToggle/HBoxContainer/Label.text = "ON"
		makeNoise.emit(0)
	else:
		$PlayerFirstToggle/HBoxContainer/Label.text = "OFF"
		makeNoise.emit(1)

func _on_music_button_item_selected(index: int) -> void:
	if index == 0:
		Globals.currentSong = ""
	else:
		Globals.currentSong = songList[index - 1]
	makeNoise.emit(0)

func _on_menu_button_pressed() -> void:
	makeNoise.emit(1)

func _on_options_menu_test_music(toggled_on: bool):
	if toggled_on:
		playTest.emit(testSong)
	else:
		playTest.emit("stop")

#-----------------------------------------
#POPUPS
#-----------------------------------------
func _on_help_button_pressed() -> void:
	makeNoise.emit(0)
	helpOpen = true
	$Navigation/HelpMenu.show()

func _on_exit_button_pressed() -> void:
	makeNoise.emit(1)
	helpOpen = false
	$Navigation/HelpMenu.hide()

func _on_option_button_pressed() -> void:
	makeNoise.emit(0)
	optionsOpen = true
	$OptionsMenu.show()

func _on_options_menu_main() -> void:
	playTest.emit("stop")
	makeNoise.emit(1)
	optionsOpen = false
	$OptionsMenu.hide()

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_fight_button_pressed() -> void:
	setEnemyGlobals()
	setPlayerGlobals()
	
	battleStart.emit()

func _on_chip_button_pressed() -> void:
	setPlayerGlobals()
	chipMenu.emit()

func _on_gear_button_pressed() -> void:
	setPlayerGlobals()
	gearMenu.emit()

func _on_item_button_pressed() -> void:
	setPlayerGlobals()
	itemMenu.emit()
