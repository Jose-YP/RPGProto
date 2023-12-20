extends "res://Code/SceneCode/Entity.gd"

@onready var EnemyLabel = $NameContainer/RichTextLabel
@onready var enemyData = data.specificData
@onready var ScanBox = $ScanBox
@onready var gettingScanned: bool = false

var enemyAI
var aiInstance
var description: String
var moveset: Array = []

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	moreReady()
	EnemyLabel.append_text(str("[b][",data.species,"][/b]",data.name))
	moveset = data.skillData + items
	moveset.append(data.attackData)
	
	match enemyData.AIType:#Determine which AI to use
		"Random":
			enemyAI = preload("res://Code/EnemyAI/EnemyRandom.gd")
		"Pick Off":
			enemyAI = preload("res://Code/EnemyAI/EnemyPickOff.gd")
		"Support":
			pass
			#enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Debuff":
			enemyAI = preload("res://Code/EnemyAI/EnemyDebuff.gd")
	
	aiInstance = enemyAI.new()
	makeDesc()
	$ScanBox/ScanDescription.append_text(description)

func _process(_delta):
	processer()
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)

#-----------------------------------------
#ENEMYAI
#-----------------------------------------
func chooseMove(TP,allies,opposing):
	var move
	var allowed = allowedMoveset(TP)
	
	match enemyData.AIType:
		"Random":
			move = aiInstance.RandomMove(allowed)
			if move is Item:
				move = move.attackData
			return move
		"Pick Off": #This Ai should KILL
			pass
		"Support": #This Ai should prioritize healing
			pass
		"Debuff": #This Ai should prioritize buffing moves
			move = aiInstance.ShouldDebuff(allowed,allies,opposing)
		_:
			pass

#-----------------------------------------
#TARGETTING TYPES
#-----------------------------------------
func SingleSelect(targetting,_move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			return trgt
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass

func GroupSelect(targetting,_move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			return trgt
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass
#-----------------------------------------
#UI CHANGES
#-----------------------------------------
func displayMove(move):
	InfoBox.show()
	Info.text = str(data.name, " used ", move.name)

func makeDesc():
	var foundWeak: bool
	var foundRes: bool
	var weak: String = ""
	var resist: String = ""
	var moveString: String = ""
	var itemString: String = ""
	var stats = str("str:",data.strength,"|tgh:",data.toughness,"|bal:",data.ballistics
	,"\nres:",data.resistance,"|spd:",data.speed,"|luk:",data.luck)
	
	for i in range(6):
		#Flag is the binary version of i
		var flag = 1 << i
		if flag & data.Weakness:
			foundWeak = true
			weak = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),weak)
		if flag & data.Resist:
			foundRes = true
			resist = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),resist)
	
	if foundWeak:
		weak = str("Weak: ", weak)
	if foundRes:
		resist = str("Res: ", resist)
	
	for move in moveset:
		if move.name == "Attack" or move.name == "Wait":
			continue
		
		if move is Item:
			if itemString != "":
				itemString = str(items,",","[",data.itemData.get(move),"/",move.maxItems,"]",move.name)
			else:
				itemString = str("[",data.itemData.get(move),"/",move.maxItems,"]",move.name)
			
		else:
			if moveString != "":
				moveString = str(moveString,",",move.name)
			else:
				moveString = str(move.name)
	
	if moveString != "":
		moveString = str("Moves: ", moveString)
	if itemString != "":
		itemString = str("Items:", itemString)
	
	description = str(weak,"\n",resist,"\n",stats,"\n",moveString,"\n",itemString)

func getScanned():
	pass

#-----------------------------------------
#PAYING ITEM&TP
#-----------------------------------------
func payCost(move):
	if move.CostType == "Item":
		for item in data.itemData:
			if item.name == move.name:
				data.itemData[item] -= move.cost
	
	return move.TPCost - (data.speed * (1 + data.speedBoost))

func allowedMoveset(TP):
	var allowed: Array = []
	for move in moveset:
		var use = move
		if move is Item:
			use = move.attackData
		
		var TPCost = use.TPCost - (data.speed * (1 + data.speedBoost))
		if Globals.currentAura == "LowTicks":
			TPCost = TPCost / 2
		
		if TP > TPCost:
			allowed.append(use)
	
	if allowed.size() == 0: #if they can't use anything else they have to wait
		allowed.append(data.waitData)
	
	return allowed
