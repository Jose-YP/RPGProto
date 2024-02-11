extends "res://Code/SceneCode/Entities/enemy.gd"

func basicSelect(allowed):
	print("AAAAAA")
	var index = randi()%allowed.size()
	return allowed[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex

func Group(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
