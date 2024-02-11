extends "res://Code/SceneCode/Entities/enemy.gd"

var chanceArrayIndex = 0

func basicSelect(allowed):
	var index = randi()%allowed.size()
	var buffed: bool = false
	
	for buff in selfBuffStatus():
		if buff >= enemyData.selfBuffAmmountPreference:
			buffed = true
	
	if not buffed:
		pass
	
	return allowed[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
