extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var canBuff: bool = false
var usedItem: bool = false
var debug: bool = true
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
		for buff in range(entity.size()):
			if entity[buff] > eData.allyBuffAmmountPreference:
				print(entity[buff], "vs", eData.allyBuffAmmountPreference)
				print(buff)
				#1 for atk, 2, for def, 4 for spd, and 8 for luk
				buffedFlags[-1] += int(pow(2,buff)) 
				buffedNum[-1] += 1
				print("FlagCurrently:", buffedFlags[-1])
		
		#Check if they have proper ammount of buffs
		if buffedNum[-1] < eData.allyBuffNumPreference:
			canBuff = true
	
	if canBuff and randi_range(0,100) <= 60:
		canBuff = false
		actionMode = action.BUFF
		
		for entity in allies: #Must have buff moves of that type to be viable
			if (entity.data.attackBoost < .2 and 
			getFlagMoves(allowed, "Buff", 1).size() != 0):
				return getFlagMoves(allowed, "Buff", 1).pick_random()
			
			if (entity.data.defenseBoost < .2 and 
			getFlagMoves(allowed, "Buff", 2).size() != 0):
				return getFlagMoves(allowed, "Buff", 2).pick_random()
			
			if (entity.data.speedBoost < .2 and 
			getFlagMoves(allowed, "Buff", 4).size() != 0):
				return getFlagMoves(allowed, "Buff", 4).pick_random()
			
			if (entity.data.luckBoost < .2 and 
			getFlagMoves(allowed, "Buff", 8).size() != 0):
				return getFlagMoves(allowed, "Buff", 8).pick_random()
	
	var lowHPArray = groupLowHealth("Opposing", eData.oppHPPreference)
	var foundLow: int = 0
	for entityLow in lowHPArray:
		if entityLow:
			foundLow += 1
	
	if foundLow == 0 or randi_range(0,100) < 25:
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
			var seeking = groupLeastHealth("Opposing",eData.oppHPPreference)
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
			var seeking = groupLeastHealth("Opposing",eData.oppHPPreference)
			
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
