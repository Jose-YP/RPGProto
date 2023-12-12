extends "res://Code/Entity.gd"

#Make sure these can be refered to outside the code
#inside the code it just looks nicer
@onready var LPBar: TextureProgressBar = $LPBar
@onready var LPtext: RichTextLabel = $LPBar/RichTextLabel
@onready var menu: Control = $CanvasLayer
@onready var playerData = data.specificData
@onready var secondaryTabs = $CanvasLayer/TabContainer

signal startSelect(useMove)
signal moveSelected(useMove)
signal wait

#Current values only a player would have
var currentLP: int
var currentMenu: Array
var skills: Array = []
var items: Array = []
var tactics: Array = [null]
var toFill: Array = [attacks,skills,items]
var attacking: bool = false
var active: bool = false

#Set current values
func _ready():
	moreReady()
	currentLP = playerData.MaxLP
	for skill in data.skillData:
		skills.append(skill)
	items = data.itemData.keys()
	#debug code
	if data == null and playerData == null:
		print("playerData file not set")
	
	LPtext.text = str("LP: ",currentLP)
	HPtext.text = str("HP: ", currentHP)
	$CanvasLayer/TextEdit.text = str("GO! [",data.species,"] ",data.name)
	
#	for i in range(groups.size()):
#		currentMenu = get_tree().get_nodes_in_group(groups[i])
##		print(data.name, currentMenu)
#		for j in range(toFill[i].size()):
##			print(toFill[i],":",toFill[i][j].name)
#			currentMenu[j].text = toFill[i][j].name
#			print(data.name,":", skills[j].name,":",currentMenu[i],":", currentMenu[j].text)
func _process(_delta):
	if currentHP <= 0:
		currentHP = 0
		HPtext.text = str("HP: ", currentHP)
		
	if data.AilmentNum == 0:
		data.Ailment = "Healthy"
	if data.Ailment == "Overdrive":
		data.AilmentNum = 1

#-----------------------------------------
#MENU SIGNALS
#-----------------------------------------
func _on_canvas_layer_attack(i):
	if not attacking:
		match i:
			0:
				startSelect.emit(data.attackData)
			_:
				print("null")
	else:
		moveSelected.emit(data.attackData)
	
func _on_canvas_layer_skill(i):
	if attacking:
		moveSelected.emit(skills[i])
	else:
		startSelect.emit(skills[i])

func _on_canvas_layer_item(i):
	if attacking:
		moveSelected.emit(items[i].attackData)
	else:
		startSelect.emit(items[i].attackData)

func _on_canvas_layer_tactic(i):
	match i:
		0:
			wait.emit()
		1:
			if attacking:
				pass
			else:
				pass
		_:
			print("null")
