extends "res://Code/SceneCode/Entities/enemy.gd"

func basicSelect(allowed):
	print("AAAA")
	var index = randi()%allowed.size()
	return allowed[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
