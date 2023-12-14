extends "res://Code/Entity.gd"

var moveset: Array = []

#Setup moveset
func _ready():
	moreReady()
	moveset = data.skillData + items
	moveset.append(data.attackData)
	print(data.name, moveset)

func _process(_delta):
	processer()
	
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)
			print(data.name, "'s ", thing, "gone")

func chooseMove():
	var index = randi()%moveset.size()
	return moveset[index]

func ERandomSingle(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
