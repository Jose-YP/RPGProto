extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var usedPop: bool = false
var usedScrew: bool = false
var allies: Array = []
var opp: Array = []

func basicSelect(allowed) -> Move:
	var buffed: bool = false
	for buff in selfBuffStatus(): #BUFF IF NOT BUFFED
		if buff >= eData.selfBuffAmmountPreference:
			print(buff, eData.selfBuffAmmountPreference)
			buffed = true
	
	if not usedScrew and not buffed and randi_range(0,100) <= 10:
		actionMode = action.BUFF
		var buffs = getFlagMoves(allowed, "Buff")
		usedScrew = true
		print(buffs)
		return buffs[0]
	
	elif not usedPop:
		var foundWeak: bool = false
		for entity in groupElements("Opposing", "Elec"):
			if entity:
				foundWeak = true
		
		if foundWeak and randi_range(0,100) <= 10:
			var eleChange = getFlagMoves(allowed, "EleChange")
			actionMode = action.ELECHANGE
			usedPop = true
			print(eleChange)
			return eleChange[0]
	
	print(eData.oppHPPreference)
	var lowHPArray = groupLowHealth("Opposing", eData.oppHPPreference)
	var elementMoves = getElementMoves(allowed)
	var foundLow: int = 0
	print(lowHPArray)
	for entityLow in lowHPArray:
		if entityLow:
			foundLow += 1
	
	match foundLow:
		0:
			if randi_range(0,100) <= 65:
				
				print(getDamagingMoves(allowed))
				return getHighDamage(allowed)
			else:
				print(elementMoves)
				return elementMoves[0]
		1:
			actionMode = action.KILL
			print(getHighDamage(allowed))
			return getHighDamage(allowed)
		_:
			print(elementMoves)
			return elementMoves[0]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	#incase it doesn't work
	var defenderIndex: int = randi() % targetting.size()
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
		action.ELECHANGE:
			for entity in range(targetting.size()):
				if targetting[entity].tempElement == "Elec":
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
		action.ELECHANGE:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity].tempElement == "Elec":
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	actionMode = action.ETC
	return defenderIndex
