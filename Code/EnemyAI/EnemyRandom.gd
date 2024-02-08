extends "res://Code/SceneCode/Entities/enemy.gd"

func basicSelect(moveset):
	print("AAAA")
	var index = randi()%moveset.size()
	return moveset[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
