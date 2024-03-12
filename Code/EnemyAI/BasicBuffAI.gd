extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var usedNut: bool = false
var allies: Array = []
var opp: Array = []

func basicSelect(allowed) -> Move:
	allOpposing = opp
	var buffedNum: Array[int] = []
	var i: int = 0
	for entity in groupBuffStatus("Ally"): #BUFF IF NOT BUFFED
		buffedNum[i] = 0
		print(groupBuffStatus("Ally"))
		for buff in entity:
			if buff > .1:
				buffedNum[i] += 1
		
		
	
	return

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
