extends Control

@export var playerEntities: Array[entityData]
@export var enemyEntities: Array[entityData]

#PLAYER VARIABLES
@onready var playerChoices: Array[OptionButton] = [$PlayerSide/PlayerMenu/Player1/MenuButton,
$PlayerSide/PlayerMenu/Player2/MenuButton,$PlayerSide/PlayerMenu/Player3/MenuButton]
@onready var playerLevels: Array[SpinBox] = [$PlayerSide/PlayerMenu/Player1Level,
$PlayerSide/PlayerMenu/Player2Level,$PlayerSide/PlayerMenu/Player3Level]
@onready var playerStats: Array[RichTextLabel] = [$PlayerSide/PlayerDisplay/PlayerStats/Player1Stats/RichTextLabel,
$PlayerSide/PlayerDisplay/PlayerStats/Player2Stats/RichTextLabel,$PlayerSide/PlayerDisplay/PlayerStats/Player3Stats/RichTextLabel2]
@onready var playerElements: Array[TabContainer] = [$PlayerSide/PlayerDisplay/PlayerElements/Player1Element,
$PlayerSide/PlayerDisplay/PlayerElements/Player2Element,$PlayerSide/PlayerDisplay/PlayerElements/Player3Element]
@onready var playerPhyEle: Array[TabContainer] = [$PlayerSide/PlayerDisplay/PlayerPhyElements/PlayerPhyElement1,
$PlayerSide/PlayerDisplay/PlayerPhyElements/PlayerPhyElement2,$PlayerSide/PlayerDisplay/PlayerPhyElements/PlayerPhyElement3]
#ENEMY VARIABLES
@onready var enemyChoices: Array[OptionButton] = [$EnemySide/EnemyMenu/EnemyMenu1/Enemy1/MenuButton,
$EnemySide/EnemyMenu/EnemyMenu1/Enemy2/MenuButton,$EnemySide/EnemyMenu/EnemyMenu1/Enemy3/MenuButton]
@onready var enemiesShown: RichTextLabel = $EnemySide/EnemyDisplay/EnemyLineup/RichTextLabel
@onready var enemyElements: Array[TabContainer] = [$EnemySide/EnemyDisplay/EnemyElements/EnemyElement,
$EnemySide/EnemyDisplay/EnemyElements/EnemyElement2,$EnemySide/EnemyDisplay/EnemyElements/EnemyElement3]
@onready var enemyPhyEle: Array[TabContainer] = [$EnemySide/EnemyDisplay/EnemyElements/EnemyPhyElement,
$EnemySide/EnemyDisplay/EnemyElements/EnemyPhyElement2,$EnemySide/EnemyDisplay/EnemyElements/EnemyPhyElement3]
@onready var SFX: Array[AudioStreamPlayer] = [$SFX/Confirm,$SFX/Back,$SFX/Menu]

signal chipMenu
signal gearMenu
signal itemMenu

var Battle: PackedScene = load("res://Scene/Mains/Main.tscn")
var songList: Array[String] = ["res://Audio/Music/15-Blaire-Dame.wav","res://Audio/Music/Delve!!!.wav",
"res://Audio/Music/178.-Boss-Battle.wav"]
var playerNamesHold: Array[String] = ["DREAMER","Lonna","Damir","Pepper"]
var playerLevelsHold: Array[int] = [5,5,5,5]
var players: Array[entityData] = [null, null, null]
var enemies: Array[entityData] = [null, null, null]

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	for i in range(3):
		playerDescriptions(playerStats[i],i)
	for menu in (playerChoices + enemyChoices):
		menu.connect("pressed",_on_menu_button_pressed)
	
	Globals.inactive_player_entities.append(playerEntities[1])
	makeEnemyLineup()

#-----------------------------------------
#PLAYER SETUP
#-----------------------------------------
func playerDescriptions(description,i):
	var level = playerLevels[i].value
	var currentName = playerChoices[i].get_item_text(playerChoices[i].selected)
	description.append_text(makePlayerDesc(i,playerChoices[i].selected,currentName,level))
	players[i] = playerEntities[playerChoices[i].selected]

func makePlayerDesc(index,playerNum,currentName,level):
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
	description = str(charName,"\n",resourceStats,"\n",resist,"\n",stats,"\n",skillString,"\n\n",itemString)
	return description

func playerChoiceChanged(playerIndex,infoIndex): #First is for playerNames second is for playerChoices
	SFX[0].play()
	playerStats[infoIndex].clear()
	var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
	var level = getLevel(currentName)
	noRepeats(currentName, infoIndex, playerIndex, level)
	setPlayerGlobals()
	playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))
	playerLevels[infoIndex].value = level

#-----------------------------------------
#PLAYER HELPERS
#-----------------------------------------
func noRepeats(currentName, infoIndex, playerIndex, level):
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

func levelChange(level,infoIndex):
	SFX[2].play()
	playerStats[infoIndex].clear()
	var playerIndex = playerChoices[infoIndex].selected
	var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
	playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))
	saveLevels(currentName,level)

func saveLevels(char,level):
	for playerIndex in range(playerNamesHold.size()):
		if playerNamesHold[playerIndex] == char:
			playerLevelsHold[playerIndex] = int(level)

func getLevel(char):
	for playerIndex in range(playerNamesHold.size()):
		if playerNamesHold[playerIndex] == char:
			return playerLevelsHold[playerIndex]

func setPlayerGlobals():
	Globals.current_player_entities = []
	Globals.current_player_entities = players
	Globals.every_player_entity = players + Globals.inactive_player_entities

func setInactivePlayer(held):
	Globals.inactive_player_entities[0] = held

func getOldIndex(prevName) -> int:
	match prevName:
		"DREAMER":
			return 0
		"Lonna":
			return 1
		"Damir":
			return 2
		"Pepper":
			return 3
		_:
			print("Oh no")
			return 10

#-----------------------------------------
#ENEMY SETUP
#-----------------------------------------
func makeEnemyLineup():
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

func setEnemyGlobals():
	Globals.current_enemy_entities = []
	for i in range(3):
		if enemyChoices[i].selected != 6:
			Globals.current_enemy_entities.append(enemyEntities[enemyChoices[i].selected])

func enemyChoiceChanged(_index):
	SFX[0].play()
	makeEnemyLineup()

#-----------------------------------------
#GENERAL SETUP
#-----------------------------------------
func getElements(entity,ElementTab,PhyEleTab):
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			ElementTab.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			PhyEleTab.current_tab = k

#-----------------------------------------
#MISC TOGGLES
#-----------------------------------------
func _on_player_order_toggled(button_pressed):
	Globals.playerFirst = button_pressed
	if button_pressed:
		$PlayerFirstToggle/HBoxContainer/Label.text = "ON"
		SFX[0].play()
	else:
		$PlayerFirstToggle/HBoxContainer/Label.text = "OFF"
		SFX[1].play()

func _on_music_button_item_selected(index):
	if index == 0:
		Globals.currentSong = ""
	else:
		Globals.currentSong = songList[index - 1]
	SFX[0].play()

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_help_button_pressed():
	SFX[0].play()
	$HelpMenu.show()

func _on_exit_button_pressed():
	SFX[1].play()
	$HelpMenu.hide()

func _on_option_button_pressed():
	SFX[0].play()
	$OptionsMenu.show()

func _on_exit_option_pressed():
	SFX[1].play()
	$OptionsMenu.hide()

func _on_fight_button_pressed():
	setEnemyGlobals()
	setPlayerGlobals()
	
	get_tree().change_scene_to_packed(Battle)

func _on_menu_button_pressed():
	SFX[1].play()

func _on_chip_button_pressed():
	Globals.current_player_entities = players
	chipMenu.emit()

func _on_gear_button_pressed():
	Globals.current_player_entities = players
	gearMenu.emit()

func _on_item_button_pressed():
	Globals.current_player_entities = players
	itemMenu.emit()
