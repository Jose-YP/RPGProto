extends "res://Code/Entity.gd"

#Make sure these can be refered to outside the code
#inside the code it just looks nicer
@onready var LPBar: TextureProgressBar = $LPBar
@onready var LPtext: RichTextLabel = $LPBar/RichTextLabel
@onready var menu: Control = $CanvasLayer
@onready var playerData = data.specificData
@onready var secondaryTabs = $CanvasLayer/TabContainer
@onready var firstButton = $CanvasLayer/Regularmenu/MarginContainer/GridContainer/Basic

signal canPayFor(menuIndex, buttonIndex, yes)
signal startSelect(useMove)
signal moveSelected(useMove)
signal wait
signal boost
signal scan
signal cancel

#Current values only a player would have
var currentLP: int
var currentMenu: Array
var skills: Array = []
var tactics: Array = []
var moveset: Array = []
var descriptions: Array
var overdrive: bool = true
var active: bool = false
var dead: bool = false
var displaying: bool = false

#Set current values
func _ready():
	moreReady()
	currentLP = playerData.MaxLP
	
	for basic in playerData.Basics:
		attacks.append(basic)
	
	for skill in data.skillData:
		skills.append(skill)
	
	tactics = [playerData.Tactics1,playerData.Tactics2,playerData.Tactics3,playerData.Tactics4]
	
	
	LPtext.text = str("LP: ",currentLP)
	HPtext.text = str("HP: ", currentHP)
	$CanvasLayer/TextEdit.text = str("GO! [",data.species,"] ",data.name)

func _process(_delta):
	processer()
	
	if data.Ailment == "Overdrive":
		overdrive = true
		overdriveReady.emit(overdrive)

#-----------------------------------------
#COST MANAGEMENT
#-----------------------------------------
	#targetting.HPBar, "value",
#	int(100 * float(targetting.currentHP) / float(targetting.data.MaxHP)),tweenTiming).set_trans(Tween.TRANS_BOUNCE)
func payCost(move):
	match move.CostType:
		"HP":
			currentHP -= (data.MaxHP * move.cost)
			var CostTween = $HPBar.create_tween()
			CostTween.tween_property(HPBar, "value", int(100 * float(currentHP) / float(data.MaxHP)),.1).set_trans(CostTween.TRANS_CIRC)
			HPtext.text = str("HP: ",currentHP)
		
		"LP":
			currentLP -= int(move.cost)
			var CostTween = $LPBar.create_tween()
			CostTween.tween_property(LPBar, "value", int(100 * float(currentLP) / float(playerData.MaxLP)),.1).set_trans(CostTween.TRANS_CIRC)
			LPtext.text = str("LP: ",currentLP)
			
		"Overdrive":
			data.AilmentNum = 0
			overdrive = false
			overdriveReady.emit(overdrive)
		
		"Item":
			for item in data.itemData:
				if item.name == move.name:
					data.itemData[item] -= move.cost
	
	return move.TPCost - (data.speed * (1 + data.speedBoost))

func displayDesc(category,num):
	var TrueTPCost = int(TPArray[category][num] - (data.speed * (1 + data.speedBoost)))
	var desc = str(descriptions[category][num])
	if category == 2: #For items only
		var itemNum = data.itemData.get(moveset[category][num])
		desc = str("[i]"+"[",itemNum,desc)
	
	Info.clear()
	InfoBox.show()
	if TrueTPCost < 0:
		Info.append_text(str("[color=green]TP: +",TrueTPCost*-1,"[/color] ",desc))
	else:
		Info.append_text(str("[color=green]TP: ",TrueTPCost,"[/color] ",desc))

#-----------------------------------------
#MENU SIGNALS
#-----------------------------------------
func _on_canvas_layer_attack(i):
	
	if Globals.attacking:
		moveSelected.emit(attacks[i])
	else:
		startSelect.emit(attacks[i])

func _on_canvas_layer_skill(i):
	if Globals.attacking:
		moveSelected.emit(skills[i])
	else:
		startSelect.emit(skills[i])

func _on_canvas_layer_item(i):
	if Globals.attacking:
		moveSelected.emit(items[i].attackData)
	else:
		startSelect.emit(items[i].attackData)

func _on_canvas_layer_tactic(i):
	if Globals.attacking:
		moveSelected.emit(tactics[i])
	else:
		startSelect.emit(tactics[i])

func _on_canvas_layer_cancel():
	cancel.emit()

func _on_canvas_layer_focusing(focus,menuI,buttonI,newOne):
	if menuI == 0:
		hideDesc()
		displaying = false
	else:
		if buttonI != 4:
			if not displaying or newOne:
				displayDesc(menuI-1,buttonI)
				displaying = true
		
	focus.grab_focus()
