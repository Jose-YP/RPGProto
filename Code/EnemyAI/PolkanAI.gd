extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var usedPop: bool = false
var usedScrew: bool = false
var allies: Array = []
var opp: Array = []
var debug: bool = true

func basicSelect(allowed) -> Move:
	allOpposing = opp
	var buffed: bool = false
	for buff in selfBuffStatus(): #BUFF IF NOT BUFFED
		if buff >= eData.selfBuffAmmountPreference or buff == null:
			buffed = true
	
	if not usedScrew and not buffed and randi_range(0,100) <= 10:
		actionMode = action.BUFF
		var buffs = getFlagMoves(allowed, "Buff")
		usedScrew = true
		return buffs[0]
	
	elif not usedPop:
		var foundWeak: bool = false
		
		for entity in groupElements("Opposing", "Elec"):
			if entity:
				print("Elec found")
				foundWeak = true
				break
		
		if foundWeak and (randi_range(0,100) <= 10 or debug):
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
			if randi_range(0,100) <= 55:
				var damaging = getDamagingMoves(allowed)
				print("Print damaging moves", damaging)
				return damaging.pick_random()
			else:
				print("Element moves", elementMoves)
				return elementMoves[0]
		1:
			actionMode = action.KILL
			print("High Damage", getHighDamage(allowed))
			return getHighDamage(allowed)
		_:
			print("Element default", elementMoves)
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
				print("Looking for", self)
				if targetting[entity] == self:
					defenderIndex = entity
					break
		action.ELECHANGE:
			for entity in range(targetting.size()):
				print(targetting[entity].data.name)
				if (targetting[entity].data.TempElement == "Elec"
				 and targetting[entity].has_node("CanvasLayer")):
					defenderIndex = entity
					break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	return defenderIndex

func Group(targetting):
	var defenderIndex: int
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
					print("looking for", self)
					if targetting[entityGroup][entity] == self:
						defenderIndex = entityGroup
						break
		action.ELECHANGE:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if (targetting[entityGroup][entity].data.TempElement == "Elec" 
					and targetting[entityGroup][entity].has_node("CanvasLayer")):
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	actionMode = action.ETC
	return defenderIndex
