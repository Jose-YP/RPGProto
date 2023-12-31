extends Node

func shouldDebuff(moveset,allies,opposing):
	#var index = randi()%moveset.size()
	var debuffs = getDebuffs(moveset)
	var usableDebuffs: Array = []
	var usableBuffs: Array = shouldBuff(moveset, allies)
	var usableMoves: Array = shouldMove(moveset)
	var usingMove
	
	for opponent in opposing:
		var stats = [opponent.data.attackBoost, opponent.data.defenseBoost, opponent.data.speedBoost, opponent.data.luckBoost]
		for stat in range(stats.size()):
			if stats[stat] >= 0:
				for move in debuffs:
					print(HelperFunctions.flag_to_String(move.boostType,"Boost"))
					if move.boostType & HelperFunctions.String_to_Flag(Globals.statTypes[stat],"Boost") == 0:
						usableDebuffs.append(move)
	
	
	if randi_range(0,100) > 30 and usableDebuffs.size() != 0: #70% chance to debuff if there are debuffs availible
		print("Will debuff", usableDebuffs)
		usingMove = usableDebuffs.pick_random()
		if EnemyAiGlobal.verifyMove(usingMove,allies,opposing):
			return usableDebuffs.pick_random()
	
	if randi_range(0,100) > 40 and usableBuffs.size() != 0: #60% chance to buff if there are buffs availible
		print("Will buff", usableBuffs)
		return usableBuffs.pick_random()
	
	else:
		print("Will attack", usableMoves)
		return usableMoves.pick_random()

func shouldBuff(moveset,allies):
	var buffs = getBuffs(moveset)
	var usableBuffs: Array = []
	
	for ally in allies:
		var stats = [ally.data.attackBoost, ally.data.defenseBoost, ally.data.speedBoost, ally.data.luckBoost]
		for stat in range(stats.size()):
			if stats[stat] >= 0:
				for move in buffs:
					print(HelperFunctions.flag_to_String(move.boostType,"Boost"))
					if move.boostType & HelperFunctions.String_to_Flag(Globals.statTypes[stat],"Boost") == 0:
						usableBuffs.append(move)
	
	return usableBuffs

func shouldMove(moveset):
	var moves: Array = []
	
	for move in moveset:
		if not move.property & 8 == 0:
			moves.append(move)
	
	return moves

func getDebuffs(moveset):
	var debuffs: Array = []
	
	for move in moveset:
		if move.property & 8 and move.boostAmmount < 0:
			print(move.name)
			debuffs.append(move)
	
	return debuffs

func getBuffs(moveset):
	var buffs: Array = []
	
	for move in moveset:
		if move.property & 8 and move.boostAmmount > 0:
			print(move.name)
			buffs.append(move)
	
	return buffs

#-----------------------------------------
#TARGETTING
#-----------------------------------------
#func Single(targetting):
#	var defenderIndex
#	var prevTarget = targetting[0]
#	for target in targetting:
#		if prevTarget.
#
#	return defenderIndex
