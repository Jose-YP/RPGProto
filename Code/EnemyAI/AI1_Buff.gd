extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var canBuff: bool = false
var hasItem: bool = false
var allies: Array = []
var opp: Array = []
var buffedNum: Array[int] = []
var buffedFlags: Array[int] = []
var usedBuffOn = null

func basicSelect(allowed) -> Move:
	#BUFF CHECK
	#--------------
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
			if (entity.data.attackBoost < eData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 1).size() != 0):
				usedBuffOn = entity
				return getFlagMoves(allowed, "Buff", 1).pick_random()
			
			if (entity.data.defenseBoost < eData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 2).size() != 0):
				usedBuffOn = entity
				return getFlagMoves(allowed, "Buff", 2).pick_random()
			
			if (entity.data.speedBoost < eData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 4).size() != 0):
				usedBuffOn = entity
				return getFlagMoves(allowed, "Buff", 4).pick_random()
			
			if (entity.data.luckBoost < eData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 8).size() != 0):
				usedBuffOn = entity
				return getFlagMoves(allowed, "Buff", 8).pick_random()
	
	#HEAL NUT CHECK
	#--------------
	var lowHPArray = groupLowHealth("Ally", eData.allyHPPreference)
	var foundLow: int = 0
	if (1 << 16) & selfItemProperties(): #Is there an item that heals?
		for entityLow in lowHPArray:
			if entityLow:
				foundLow += 1
				break
		
		if foundLow != 0 and randi_range(0,100) < 15:
			actionMode = action.HEAL
			hasItem = false
			return getHealMoves(allowed)[0]
	
	#DEFAULT ATTACK
	#--------------
	lowHPArray = groupLowHealth("Opposing", eData.oppHPPreference)
	foundLow = 0
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
func Single(targetting, _move):
	#incase it doesn't work
	var defenderIndex: int = randi() % targetting.size()
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing",eData.oppHPPreference)
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		
		action.HEAL:
			var seeking = groupLeastHealth("Ally", eData.allyHPPreference)
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		
		action.BUFF: #TO CHANGE
			for entity in range(targetting.size()): #Must have buff moves of that type to be viable
				if targetting[entity] == usedBuffOn:
					defenderIndex = entity
		
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	#Remember to reset Action Mode
	actionMode = action.ETC
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
					if targetting[entityGroup][entity] == usedBuffOn:
						defenderIndex = entityGroup
						break
		action.ETC:
			defenderIndex = randi() % targetting.size()
	
	actionMode = action.ETC
	return defenderIndex
