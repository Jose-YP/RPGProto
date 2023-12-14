extends "res://Code/Entity.gd"

#Make sure these can be refered to outside the code
#inside the code it just looks nicer
@onready var LPBar: TextureProgressBar = $LPBar
@onready var LPtext: RichTextLabel = $LPBar/RichTextLabel
@onready var menu: Control = $CanvasLayer
@onready var playerData = data.specificData
@onready var secondaryTabs = $CanvasLayer/TabContainer
@onready var firstButton = $CanvasLayer/Regularmenu/MarginContainer/GridContainer/Basic

signal startSelect(useMove)
signal moveSelected(useMove)
signal wait
signal boost
signal scan

#Current values only a player would have
var currentLP: int
var currentMenu: Array
var skills: Array = []
var itemAllowed: Array = [true,true,true]
var tactics: Array = [null]
var toFill: Array = [attacks,skills,items]
var active: bool = false
var overdrive: bool = true

#Set current values
func _ready():
	moreReady()
	
	currentLP = playerData.MaxLP
	attacks.append(playerData.slot2)
	attacks.append(playerData.slot3)
	for skill in data.skillData:
		skills.append(skill)
	
	#debug code
	if data == null and playerData == null:
		print("playerData file not set")
	
	LPtext.text = str("LP: ",currentLP)
	HPtext.text = str("HP: ", currentHP)
	$CanvasLayer/TextEdit.text = str("GO! [",data.species,"] ",data.name)

func _process(_delta):
	processer()
	var i = 0
	
	#Checking if any item has been fully used up
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			itemAllowed[i] = false
			print(data.name, "'s ", thing, "gone")
		i += 1

#-----------------------------------------
#MENU SIGNALS
#-----------------------------------------
func _on_canvas_layer_attack(i):
	if not Globals.attacking:
		match i:
			0:
				startSelect.emit(data.attackData)
			_:
				print("null")
	else:
		moveSelected.emit(data.attackData)

func _on_canvas_layer_skill(i):
	print("Skills")
	if Globals.attacking:
		moveSelected.emit(skills[i])
	else:
		startSelect.emit(skills[i])

func _on_canvas_layer_item(i):
	print(items)
	print(items[i].attackData.name)
	if Globals.attacking and itemAllowed[i]:
		moveSelected.emit(items[i].attackData)
	else:
		startSelect.emit(items[i].attackData)

func _on_canvas_layer_tactic(i):
	match i:
		0:
			wait.emit()
		1:
			boost.emit()
		2:
			scan.emit()
		_:
			print("null")
