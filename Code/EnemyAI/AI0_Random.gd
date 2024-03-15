extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var allies: Array = []
var opp: Array = []

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
			   
