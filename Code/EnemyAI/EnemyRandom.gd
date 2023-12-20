extends Node

func RandomMove(moveset):
	var index = randi()%moveset.size()
	return moveset[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
