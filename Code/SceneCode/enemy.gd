extends "res://Code/SceneCode/Entity.gd"

@onready var EnemyLabel = $NameContainer/RichTextLabel
@onready var enemyData = data.specificData

var enemyAI
var aiInstance
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
			pass
			#enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Support":
			pass
			#enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Debuff":
			pass
			#enemyAI = preload("res://Code/EnemyAI/Test.gd")
	
	aiInstance = enemyAI.new()

func _process(_delta):
	processer()
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)

#-----------------------------------------
#ENEMYAI
#-----------------------------------------
func chooseMove(TP):
	var move
	var allowed = allowedMoveset(TP)
	
	match enemyData.AIType:
		"Random":
			move = aiInstance.RandomMove(allowed)
			if move is Item:
				print("move was item", move, move is Item)
				move = move.attackData
				print("Now using", move)
			print(move.name)
			return move
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass
		_:
			pass

#-----------------------------------------
#TARGETTING TYPES
#-----------------------------------------
func SingleSelect(targetting,move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			print(move.name, trgt)
			return trgt
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass

func GroupSelect(targetting,move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			print(move.name, trgt)
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

#-----------------------------------------
#PAYING ITEM&TP
#-----------------------------------------
func payCost(move):
	if move.CostType == "Item":
		print("Using Item")
		for item in data.itemData:
			if item.name == move.name:
				data.itemData[item] -= move.cost
	
	print("Used", move.name)
	return move.TPCost - (data.speed * (1 + data.speedBoost))

func allowedMoveset(TP):
	var allowed: Array = []
	for move in moveset:
		var use = move
		if move is Item:
			use = move.attackData
		
		var TPCost = use.TPCost - (data.speed * (1 + data.speedBoost))
		if TP > TPCost:
			allowed.append(use)
	
	print(allowed)
	return allowed
