extends "res://Code/Entity.gd"

@onready var EnemyLabel = $NameContainer/RichTextLabel
@onready var enemyData = data.specificData

var enemyAI
var aiInstance
var moveset: Array = []

#Setup moveset
func _ready():
	moreReady()
	EnemyLabel.append_text(str("[b][",data.species,"][/b]",data.name))
	moveset = data.skillData + items
	moveset.append(data.attackData)
	print(enemyData.AIType)
	
	match enemyData.AIType:#Determine which AI to use
		"Random":
			enemyAI = preload("res://Code/EnemyAI/EnemyRandom.gd")
		"Pick Off":
			enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Support":
			enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Debuff":
			enemyAI = preload("res://Code/EnemyAI/Test.gd")
	
	aiInstance = enemyAI.new()

func _process(_delta):
	processer()
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)
			print(data.name, "'s ", thing, "gone")

#TEMPLATE
#match enemyData.AIType:
#		"Random":
#			pass
#		"Pick Off":
#			pass
#		"Support":
#			pass
#		"Debuff":
#			pass
#		_:
#			pass

#-----------------------------------------
#EnemyAI
#-----------------------------------------
func chooseMove():
	var move
	match enemyData.AIType:
		"Random":
			move = aiInstance.RandomMove(moveset)
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
	var target
	match enemyData.AIType:
		"Random":
			target = aiInstance.Single(targetting)
			print(move.name, target)
			return target
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass
		_:
			pass

func GroupSelect(targetting,move):
	var target
	match enemyData.AIType:
		"Random":
			target = aiInstance.Single(targetting)
			print(move.name, target)
			return target
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass
		_:
			pass
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
