extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var canBuff: bool = false
var usedNut: bool = false
var allies: Array = []
var opp: Array = []
var buffedNum: Array[int] = []
var buffedFlags: Array[int] = []

func basicSelect(allowed) -> Move:
	buffedNum = []
	buffedFlags = []
	allAllies = allies
	allOpposing = opp
	
	for entity in groupBuffStatus("Ally"): #BUFF IF NOT BUFFED
		buffedNum.append(0)
		buffedFlags.append(0)
		print(groupBuffStatus("Ally"))
		for buff in range(entity.size()):
			if entity[buff] > eData.allyBuffAmmountPreference:
				buffedFlags[-1] += 2^buff #1 for atk, 2, for def, 4 for spd, and 8 for luk
				buffedNum[-1] += 1
		
		print(buffedNum[-1]) #Check if they have proper ammount of buffs
		if buffedNum[-1] < eData.allyBuffNumPreference:
			canBuff = true
	
	if canBuff and randi_range(0,100) <= 60:
		actionMode = action.BUFF
		print(buffedFlags)
		print(getFlagMoves(allowed, "Buff", 1))
		for entity in buffedFlags: #Must have buff moves of that type to be viable
			if entity & 1 and getFlagMoves(allowed, "Buff", 1).size() != 0:
				return getFlagMoves(allowed, "Buff", 1).pick_random()
			
			elif entity & 2 and getFlagMoves(allowed, "Buff", 2).size() != 0:
				return getFlagMoves(allowed, "Buff", 2).pick_random()
			
			elif entity & 4 and getFlagMoves(allowed, "Buff", 4).size() != 0:
				return getFlagMoves(allowed, "Buff", 4).pick_random()
			
			elif entity & 8 and getFlagMoves(allowed, "Buff", 8).size() != 0:
				return getFlagMoves(allowed, "Buff", 8).pick_random()
	
	var lowHPArray = groupLowHealth("Opposing", eData.oppHPPreference)
	var foundLow: int = 0
	for entityLow in lowHPArray:
		if entityLow:
			foundLow += 1
	
	if foundLow == 0:
		var damaging = getDamagingMoves(allowed)
		return damaging.pick_random()
	else:
		actionMode = action.KILL
		return getHighDamage(allowed)

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting):
	#incase it doesn't work
	var defenderIndex: int = randi() % targetting.size()
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing")
			
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		action.BUFF: #TO CHANGE
			for entity in range(targetting.size()):
				if targetting[entity] == self:
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
					if targetting[entityGroup][entity] == self:
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	actionMode = action.ETC
	return defenderIndex
