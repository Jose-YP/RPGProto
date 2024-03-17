extends Node

func basicSelect(allowed):
	var index = randi()%allowed.size()
	return allowed[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting, _move):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex

func Group(targetting, _move):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
