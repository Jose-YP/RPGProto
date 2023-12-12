extends "res://Code/Entity.gd"

func ERandomSingle(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
