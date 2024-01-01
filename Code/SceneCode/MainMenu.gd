extends Node2D

@export var playerEntities: Array[entityData]
@export var enemyEntities: Array[entityData]

@onready var playerChoices: Array = [$PlayerMenu/Player1/MenuButton,$PlayerMenu/Player2/MenuButton,$PlayerMenu/Player3/MenuButton]
@onready var playerLevels: Array = [$PlayerMenu/Player1Level,$PlayerMenu/Player2Level,$PlayerMenu/Player3Level]
@onready var playerStats: Array = [$PlayerStats/Player1Stats/RichTextLabel,$PlayerStats/Player2Stats/RichTextLabel,$PlayerStats/Player3Stats/RichTextLabel2]
@onready var playerElements: Array = [$PlayerElements/Player1Element,$PlayerElements/Player2Element,$PlayerElements/Player3Element]
@onready var playerPhyEle: Array = [$PlayerPhyElements/PlayerPhyElement1,$PlayerPhyElements/PlayerPhyElement2,$PlayerPhyElements/PlayerPhyElement3]
@onready var enemyChoices: Array = [$EnemyMenu/EnemyMenu1/Enemy1/MenuButton,$EnemyMenu/EnemyMenu1/Enemy2/MenuButton,$EnemyMenu/EnemyMenu1/Enemy3/MenuButton]
@onready var enemiesShown: RichTextLabel = $EnemyLineup/RichTextLabel
@onready var enemyElements: Array = [$EnemyElements/EnemyElement,$EnemyElements/EnemyElement2,$EnemyElements/EnemyElement3]
@onready var enemyPhyEle: Array = [$EnemyElements/EnemyPhyElement,$EnemyElements/EnemyPhyElement2,$EnemyElements/EnemyPhyElement3]
@onready var SFX: Array[AudioStreamPlayer] = [$SFX/Confirm,$SFX/Back,$SFX/Menu]

var Battle: PackedScene = load("res://Scene/Main.tscn")
var songList:Array = ["res://Audio/Music/15-Blaire-Dame.wav","res://Audio/Music/Delve!!!.wav","res://Audio/Music/178.-Boss-Battle.wav"]
var playerNames: Array = ["DREAMER","Lonna","Damir","Pepper"]
var players: Array
var enemies: Array

func _ready():
	for i in range(3):
		playerDescriptions(playerStats[i],i)
	for menu in (playerChoices + enemyChoices):
		menu.connect("pressed",_on_menu_button_pressed)
	
	makeEnemyLineup()

func playerDescriptions(description,i):
	var level = playerLevels[i].value
	var currentName = playerChoices[i].get_item_text(playerChoices[i].selected)
	description.append_text(makePlayerDesc(i,playerChoices[i].selected,currentName,level))
	playerNames[i] = playerEntities[playerChoices[i].selected]

func makePlayerDesc(index,playerNum,currentName,level):
	var entity = Globals.getStats(playerEntities[playerNum],currentName,str(level))
	var foundRes = false
	var resist: String
	var skillString: String
	var itemString: String
	var description: String
	var skills = entity.skillData
	var items = entity.itemData
	var charName = str("[",entity.species,"]\nlv.",level, entity.name)
	var resourceStats = str("[color=red]HP: ",entity.MaxHP,"[/color]\n[color=aqua]LP: ",entity.specificData.MaxLP,"[/color]\n[color=green]TP:", entity.MaxTP,"[/color]")
	var stats = str("str: ",entity.strength,"\ttgh: ",entity.toughness,"\tspd: ",entity.speed,"\nbal: ",entity.ballistics,"\tres: ",entity.resistance,"\tluk: ",entity.luck)
	
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

func makeEnemyLineup():
	enemiesShown.clear()
	var enLiString: String
	for i in range(enemyChoices.size()):
		var enemyEntity
		if enemyChoices[i].selected != 6:
			enemyElements[i].show()
			enemyPhyEle[i].show()
			enemyEntity  = enemyEntities[enemyChoices[i].selected]#enemyChoices[i].get_item_text(enemyChoices[i].selected)
			enLiString = str(enLiString, i+1,". ","[",enemyEntity.species,"]\t",enemyEntity.name,"\n\n\n")
			getElements(enemyEntities[enemyChoices[i].selected],enemyElements[i],enemyPhyEle[i])
		else:
			enemyElements[i].hide()
			enemyPhyEle[i].hide()
	
	enemiesShown.append_text(enLiString)

func getElements(entity,ElementTab,PhyEleTab):
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			ElementTab.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			PhyEleTab.current_tab = k

func playerChoiceChanged(playerIndex,infoIndex): #First is for playerNames second is for playerChoices
	SFX[0].play()
	playerStats[infoIndex].clear()
	var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
	var level = playerLevels[infoIndex].value
	playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))

func levelChange(level,infoIndex):
	SFX[2].play()
	playerStats[infoIndex].clear()
	var playerIndex = playerChoices[infoIndex].selected
	var currentName = playerChoices[infoIndex].get_item_text(playerIndex)
	playerStats[infoIndex].append_text(makePlayerDesc(infoIndex,playerIndex,currentName,level))

func enemyChoiceChanged(_index):
	SFX[0].play()
	makeEnemyLineup()

func _on_music_button_item_selected(index):
	if index == 0:
		Globals.currentSong = ""
	else:
		Globals.currentSong = songList[index - 1]

func _on_help_button_pressed():
	SFX[0].play()
	$HelpMenu.show()

func _on_exit_button_pressed():
	SFX[1].play()
	$HelpMenu.hide()

func _on_fight_button_pressed():
	Globals.current_player_entities = []
	Globals.current_enemy_entities = []
	
	for i in range(3):
		Globals.current_player_entities.append(playerEntities[playerChoices[i].selected])
		if enemyChoices[i].selected != 6:
			Globals.current_enemy_entities.append(enemyEntities[enemyChoices[i].selected])
	
	get_tree().change_scene_to_packed(Battle)

func _on_menu_button_pressed():
	SFX[1].play()
