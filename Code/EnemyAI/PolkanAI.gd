extends "res://Code/SceneCode/Entities/enemy.gd"

func basicSelect(allowed):
	var buffed: bool = false
	
	for buff in selfBuffStatus():
		if buff >= enemyData.selfBuffAmmountPreference:
			print(buff, enemyData.selfBuffAmmountPreference)
			buffed = true
	
	if not buffed and randi_range(0,100) <= 10:
		actionMode = action.BUFF
		return getFlagMoves(allowed, "Stats")
	
	else:
		var lowHPArray = groupLowHealth("Opposing", enemyData.oppHPPreference)
		var elementMoves = getElementMoves(allowed)
		var foundLow: int = 0
		print(lowHPArray)
		for entityLow in lowHPArray:
			if entityLow:
				foundLow += 1
		
		match foundLow:
			0:
				if randi_range(0,100) <= 65:
					return getHighDamage(allowed)
				else:
					return elementMoves[0]
			1:
				actionMode = action.KILL
				return getHighDamage(allowed)
			_:
				return elementMoves[0]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	var defenderIndex: int
	print(targetting)
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing")
			
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		action.BUFF:
			for entity in range(targetting.size()):
				if targetting[entity] == self:
					defenderIndex = entity
					break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	return defenderIndex

func Group(targetting):
	var defenderIndex: int
	print(targetting)
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing")
			
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity] == seeking:
						defenderIndex = entityGroup
						break
		action.BUFF:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity] == self:
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	actionMode = action.ETC
	return defenderIndex
