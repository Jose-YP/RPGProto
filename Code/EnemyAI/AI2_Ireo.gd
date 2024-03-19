extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var firstMove: bool = true
var prepared: bool = false
var usedBlackHole: bool = false
var searchFor: String = ""
var allies: Array = []
var opp: Array = []

func basicSelect(allowed) -> Move:
	var blackHole: Move = getSpecificMove(allowed, "Black Hole")
	var endurian: Move = getSpecificMove(allowed, "Endurian")
	allOpposing = opp
	
	#Ireo will always use blackhole first
	if firstMove and blackHole != null:
		firstMove = false
		return blackHole
	
	#When they're low health prepare the endurian then use blackhole again
	if selfLeastHealth(eData.selfHPPreference) and not usedBlackHole:
		if prepared and blackHole != null:
			usedBlackHole = true
			return blackHole
		elif endurian != null:
			actionMode = action.CONDITION
			prepared = true
			return endurian
	
	#When not doing either, remove blackhole and endurian
	allowed.erase(blackHole)
	allowed.erase(endurian)
	print(allowed)
	
	#CHeck if they can or will use Overdrive/Burst
	var ailment: Array = selfAilments()
	var overdrive: Move = getSpecificMove(allowed, "Overdrive")
	var burst: Move = getSpecificMove(allowed, "Burst")
	var coughSyrup: Move = getSpecificMove(allowed, "Cough Syrup")
	
	if ailment[0] != "Overdrive" and randi_range(0,100) <= 60 and overdrive != null:
		if ailment[1] > 1 and coughSyrup != null:
			actionMode = action.AILHEAL
			return coughSyrup
		return overdrive
	
	elif ailment[0] == "Overdrive" and randi_range(0,100) <= 30 and burst != null:
		return burst
	
	allowed.erase(overdrive)
	allowed.erase(burst)
	allowed.erase(coughSyrup)
	print(allowed)
	
	var oppElements: Array = groupElements("Opposing")
	var elementMap: Dictionary = {"Fire" : 0, "Water" : 0, "Elec" : 0, "Neutral" : 0}
	var ghoul: Move = getSpecificMove(allowed, "Galactic Ghoul")
	#Count every value
	for i in oppElements:
		elementMap[i] += 1
	
	for element in oppElements:
		if element == elementMatchup(false, data.TempElement) and randi_range(0,100) >= 30:
			actionMode = action.SEARCHATTACK
			searchFor = element
			return getSpecificMove(allowed, "Attack")
		elif (element == "Fire" or elementMap[element] > 1) and randi_range(0,100) >= 20 and ghoul != null:
			searchFor = element
			actionMode = action.SEARCHATTACK
			return ghoul
	
	return allowed.pick_random()

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting, _move):
	#incase it doesn't work
	var defenderIndex: int = randi() % targetting.size()
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing")
			
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		action.SEARCHATTACK:
			for entity in range(targetting.size()):
				if targetting[entity].data.TempElement == searchFor:
					defenderIndex = entity
					break 
		action.ETC:
			defenderIndex = randi() % targetting.size()
		_:
			for entity in range(targetting.size()):
				if targetting[entity] == self:
					defenderIndex = entity
					break
	
	actionMode = action.ETC
	return defenderIndex

func Group(targetting, _move):
	var defenderIndex: int
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing")
			
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity] == seeking:
						defenderIndex = entityGroup
						break
		action.SEARCHATTACK:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity].data.TempElement == searchFor:
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
		_:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity] == self:
						defenderIndex = entityGroup
						break
	
	actionMode = action.ETC
	return defenderIndex
