extends Node

func basicDecide():
	pass

func verifyMove(move,opposing,allies,PrioitizeAttack = true): #Attacks don't need to be verified unless checking for side effects
	var should = true
	
	for target in (opposing + allies):
		if (move.property & 1 != 0 or move.property & 2 != 0 or move.property & 4 != 0) and PrioitizeAttack:
			return true
		
		else:
			if move.property & 8:
				if move.boostAmmount != 0:
					should = (verifyBuff(target,move) != verifyDebuff(target,move))
				if move.Condition != 0:
					should = verifyCondition(target.data,move)
				
			if move.property & 16:
				should = verifyHealHP(target) or verifyHealAilment(target.data)
			if move.property & 32:
				should = verifyAura(move)
			if move.property & 64:
				should = verifySummon(target,move)
			if move.property & 128:
				should = verifyAilment(target.data,move)
	
	return should

func verifyBuff(target,move): #Check if target already has high buffs
	var should = true
	var stats = [target.data.attackBoost, target.data.defenseBoost, target.data.speedBoost, target.data.luckBoost]
	
	for stat in range(stats.size()):
		if move.boostType & HelperFunctions.String_to_Flag(Globals.statTypes[stat],"Boost") == 0:
			print("can boost", Globals.statTypes[stat])
			if stats[stat] >= .5:
				should = false
	
	return should

func verifyDebuff(target,move): #Check if target already has high debuffs
	var should = true
	var stats = [target.data.attackBoost, target.data.defenseBoost, target.data.speedBoost, target.data.luckBoost]
	
	for stat in range(stats.size()):
		if move.boostType & HelperFunctions.String_to_Flag(Globals.statTypes[stat],"Boost") == 0:
			print("can debuff", Globals.statTypes[stat])
			if stats[stat] <= -.5:
				should = false
	
	return should

func verifyCondition(targetData,move): #Check if target already has the ailment
	var should = true
	if move.Condition & targetData == 0:
		should = false
	return should

func verifyHealHP(target): #Check if target even needs to be healed
	var should
	if target.currentHP != (target.data.maxHP * .8):
		should = false
	return should

func verifyHealAilment(target): #Check if target even needs to have ailments healed
	var should
	if target.data.AilmentNum == 0:
		should = false
	return should

func verifyAura(move): #Check if aura isn't already up
	var should = true
	
	if Globals.currentAura == move.aura:
		should = false
	
	return should

func verifySummon(_target,_move): #Check if an entity can even be summoned
	pass

func verifyAilment(targetData,_move): #Check if target doesn't already have max Ailments
	var should = true
	if targetData.AilmentNum > 2:
		should = false
	return should
