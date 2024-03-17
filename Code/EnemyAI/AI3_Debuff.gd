extends "res://Code/SceneCode/Entities/enemy.gd"

#It needs to have these redefined from enemy, to here
var eData: Enemy
var canBuff: bool = false
var canDebuff: bool = false
var hasItem: bool = false
var debug: bool = true
var allies: Array = []
var opp: Array = []
var buffedNum: Array[int] = []
var buffedFlags: Array[int] = []
var debuffedNum: Array[int] = []
var debuffedFlags: Array[int] = []

func basicSelect(allowed) -> Move:
	buffedNum = []
	buffedFlags = []
	debuffedNum = []
	debuffedFlags = []
	allAllies = allies
	allOpposing = opp
	
	print("DEBUFF", groupBuffStatus("Opposing"))
	for entity in groupBuffStatus("Opposing"): #DEBUFF IF NOT DEBUFFED
		debuffedNum.append(0)
		debuffedFlags.append(0)
		for debuff in range(entity.size()):
			var debuffFlag = int(pow(2,debuff))
			if not (debuffFlag & eData.oppBoostTypePreference): continue
			
			if entity[debuff] > eData.oppBuffAmmountPreference:
				#1 for atk, 2, for def, 4 for spd, and 8 for luk
				debuffedFlags[-1] += debuffFlag
				debuffedNum[-1] += 1
		
		#Check if they have proper ammount of buffs
		if debuffedNum[-1] > eData.oppBuffNumPreference:
			canDebuff = true
	
	if canDebuff and randi_range(0,100) <= 45:
		canDebuff = false
		actionMode = action.DEBUFF
		
		for entity in (opp.size()): #Must have buff moves of that type to be viable
			
			focusIndex = opp[entity].ID
			
			if (debuffedFlags[entity] & 1 and 
			getFlagMoves(allowed, "Debuff", 1).size() != 0):
				return getFlagMoves(allowed, "Debuff", 1).pick_random()
			
			if (debuffedFlags[entity] & 2 and 
			getFlagMoves(allowed, "Debuff", 2).size() != 0):
				return getFlagMoves(allowed, "Debuff", 2).pick_random()
			
			if (debuffedFlags[entity] & 4 and 
			getFlagMoves(allowed, "Debuff", 4).size() != 0):
				return getFlagMoves(allowed, "Debuff", 4).pick_random()
			
			if (debuffedFlags[entity] & 8 and 
			getFlagMoves(allowed, "Debuff", 8).size() != 0):
				return getFlagMoves(allowed, "Debuff", 8).pick_random()
	
	for entity in groupBuffStatus("Ally"): #BUFF IF NOT BUFFED
		buffedNum.append(0)
		buffedFlags.append(0)
		for buff in range(entity.size()):
			#Skip any stats ai doesn't care about
			var buffFlag = int(pow(2,buff))
			if not (buffFlag & eData.allyBoostTypePreference): continue
			
			if entity[buff] < eData.allyBuffAmmountPreference:
				#1 for atk, 2, for def, 4 for spd, and 8 for luk
				buffedFlags[-1] += buffFlag
				buffedNum[-1] += 1
		
		#Check if they have proper ammount of buffs
		if buffedNum[-1] > eData.allyBuffNumPreference:
			canBuff = true
	
	if canBuff and randi_range(0,100) <= 40:
		canBuff = false
		actionMode = action.BUFF
		
		for entity in range(allies.size()): #Must have buff moves of that type to be viable
			focusIndex = allies[entity].ID
			
			if (buffedFlags[entity] | 1
			 and getFlagMoves(allowed, "Buff", 1).size() != 0):
				return getFlagMoves(allowed, "Buff", 1).pick_random()
			
			if (buffedFlags[entity] | 2
			 and getFlagMoves(allowed, "Buff", 2).size() != 0):
				return getFlagMoves(allowed, "Buff", 2).pick_random()
			
			if (buffedFlags[entity] | 4
			 and getFlagMoves(allowed, "Buff", 4).size() != 0):
				return getFlagMoves(allowed, "Buff", 4).pick_random()
			
			if (buffedFlags[entity] | 8
			 and getFlagMoves(allowed, "Buff", 8).size() != 0):
				return getFlagMoves(allowed, "Buff", 8).pick_random()
	
	
	#HEAL CHECK
	#--------------
	var lowHPArray = groupLowHealth("Ally", eData.allyHPPreference)
	var foundLow: int = 0
	#Is there an item that heals?
	if getHealMoves(allowed, "Ailment").size() != 0 and randi_range(0,100) < 30:
		for entity in groupAilments("Ally", true):
			if ((entity[0] == "Mental" or entity[0] == "Chemical")
			and entity[1] > eData.allyAilmentPreference):
				actionMode = action.AILHEAL
				focusIndex = entity.ID
				return getHealMoves(allowed, "Ailment").pick_random()
	
	if getHealMoves(allowed, "HP").size() != 0 and randi_range(0,100) < 30: 
		for entityLow in lowHPArray:
			if entityLow:
				foundLow += 1
				break
		
		if foundLow != 0:
			actionMode = action.HEAL
			return getHealMoves(allowed, "HP").pick_random()
	
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
		
		action.ETC:
			defenderIndex = randi() % targetting.size()
		
		_:
			for entity in range(targetting.size()): 
				if targetting[entity].ID == focusIndex:
					defenderIndex = entity
	
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
		
		action.ETC:
			defenderIndex = randi() % targetting.size()
			
		_:
			for entityGroup in range(targetting.size()):
				for entity in range(targetting[entityGroup].size()):
					if targetting[entityGroup][entity].ID == focusIndex:
						defenderIndex = entityGroup
						break
	
	actionMode = action.ETC
	return defenderIndex
