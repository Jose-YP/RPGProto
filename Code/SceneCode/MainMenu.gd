extends Node2D

@export var playerEntities: Array[entityData]

@onready var playerChoices: Array = [$PlayerMenu/Player1/MenuButton,$PlayerMenu/Player2/MenuButton,$PlayerMenu/Player3/MenuButton]
@onready var playerLevels: Array = [$PlayerMenu/Player1Level,$PlayerMenu/Player2Level,$PlayerMenu/Player3Level]
@onready var playerStats: Array = [$PlayerStats/Player1Stats/RichTextLabel,$PlayerStats/Player2Stats/RichTextLabel,$PlayerStats/Player3Stats/RichTextLabel2]
@onready var playerElements: Array = [$PlayerElements/Player1Element,$PlayerElements/Player2Element,$PlayerElements/Player3Element]
@onready var playerPhyEle: Array = [$PlayerPhyElements/PlayerPhyElement1,$PlayerPhyElements/PlayerPhyElement2,$PlayerPhyElements/PlayerPhyElement3]
@onready var enemyChoices: Array = [$EnemyMenu/EnemyMenu1/Enemy1/MenuButton,$EnemyMenu/EnemyMenu1/Enemy2/MenuButton,$EnemyMenu/EnemyMenu1/Enemy3/MenuButton,$EnemyMenu/EnemyMenu2/Enemy4/MenuButton,$EnemyMenu/EnemyMenu2/Enemy5/MenuButton]
@onready var enemyLineup: RichTextLabel = $EnemyLineup/RichTextLabel

var Battle: PackedScene = load("res://NewMain.tscn")
var players: Array = ["DREAMER","Lonna","Damir","Pepper"]
var playerEntity: Array
var enemies: Array

func _ready():
	for i in range(3):
		playerDescriptions(playerStats[i],i)

func _process(_delta):
	pass

func playerDescriptions(description,i):
	var level = playerLevels[i].value
	var playerName = playerChoices[i].get_item_text(playerChoices[i].selected)
	print(playerName)
	description.append_text(makeDesc(i,playerChoices[i].selected,playerName,level))

func makeDesc(index,playerNum,playerName,level):
	var entity = playerEntities[playerNum]
	var foundRes = false
	var resist: String
	var skillString: String
	var itemString: String
	var description: String
	
	Globals.getStats(entity,playerName,str(level))
	
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
		
		print(entity.itemData.get(item))
		if itemString != "":
			itemString = str(itemString,",","[",entity.itemData.get(item),"/",item.maxItems,"]",item.name)
		else:
			itemString = str("[",entity.itemData.get(item),"/",item.maxItems,"]",item.name)
	
	if skillString != "":
		skillString = str("Moves: ", skillString)
	if itemString != "":
		itemString = str("Items:", itemString)
	
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			playerElements[index].current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			playerPhyEle[index].current_tab = k
	
	description = str(charName,"\n",resourceStats,"\n",resist,"\n",stats,"\n",skillString,"\n\n",itemString)
	return description

func playerChoiceChanged(playerIndex,infoIndex): #First is for players second is for playerChoices
	playerStats[infoIndex].clear()
	var playerName = playerChoices[infoIndex].get_item_text(playerIndex)
	var level = playerLevels[infoIndex].value
	playerStats[infoIndex].append_text(makeDesc(infoIndex,playerIndex,playerName,level))

func levelChange(level,infoIndex):
	playerStats[infoIndex].clear()
	var playerIndex = playerChoices[infoIndex].selected
	var playerName = playerChoices[infoIndex].get_item_text(playerIndex)
	playerStats[infoIndex].append_text(makeDesc(infoIndex,playerIndex,playerName,level))

func enemyChoiceChanged(index):
	print(enemyChoices[index])

func _on_help_button_pressed():
	pass # Replace with function body.

func _on_fight_button_pressed():
	pass # Replace with function body.
