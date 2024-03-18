extends "res://Code/SceneCode/Entities/Entity.gd"

@onready var EnemyLabel: RichTextLabel = $NameContainer/RichTextLabel
@onready var enemyData: Enemy = data.specificData
@onready var ScanBox: PanelContainer = $ScanBox
@onready var gettingScanned: bool = false

enum action{KILL, HEAL, AILHEAL, BUFF, DEBUFF, ELECHANGE, AILMENT, ETC}

#SELF VARIABLES
var enemyAI
var aiInstance
var description: String
var moveset: Array = []
#PERCEPTION VARIABLES
var allAllies: Array = []
var allOpposing: Array = []
var allyCurrentTP: int
var allyMaxTP: int
var opposingCurrentTP: int
var opposingMaxTP: int
var actionMode: action = action.ETC
var focusIndex: int

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	moreReady()
	EnemyLabel.append_text(str("[b][",data.species,"][/b]",data.name))
	moveset = data.skillData + items
	moveset.append(data.attackData)
	
	if enemyData.AICodePath != "":
		enemyAI = load(str(enemyData.AICodePath))
		aiInstance = enemyAI.new()
		aiInstance.eData = enemyData
	
	makeDesc()
	$ScanBox/ScanDescription.append_text(description)

func _process(_delta):
	processer()
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)

#-----------------------------------------
#BASIC STRUCTURE ENEMYAI
#-----------------------------------------
func chooseMove(TP,allies,opposing) -> Move:
	var move: Resource
	allyCurrentTP = TP
	allAllies = allies
	allOpposing = opposing
	if enemyData.AICodePath != "":
		aiInstance.allies = allies
		aiInstance.opp = opposing
		aiInstance.data = data
	var allowed = allowedMoveset(TP)
	
	#If wait is the only allowed move, use that
	if allowed[0] == data.waitData:
		return data.waitData
	elif enemyData.AICodePath != "":
		move = aiInstance.basicSelect(allowed)
	else:
		move = genericSelect(allowed)
	
	#SAFEGUARD
	if move == null:
		return data.waitData
	
	return move

func genericSelect(allowed) -> Move:
	var move: Move = null
	#Priority list and chances will be determined in enemy Data
	for i in range(enemyData.Priorities.size()):
		if randi_range(0,100) <= enemyData.PriorityChance[i]:
			match enemyData.Priorities[i]:
				"Attack": move = decideAttack(allowed)
				"Heal": move = decideHeal(allowed)
				"Buff": move = decideBuff(allowed)
				"Debuff": move = decideDebuff(allowed)
				"Condition": move = decideCondition(allowed)
				"Element": move = decideEleChange(allowed)
				"Ailment": move = decideAilment(allowed)
				"Aura": move = decideAura(allowed)
				"Summon": move = decideSummon(allowed)
				"Misc": 
					pass
			
			if move != null:
				return move
				
	return move

func genericSingle(targetting, _move):
	#incase it doesn't work
	var defenderIndex: int = randi() % targetting.size()
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing",enemyData.oppHPPreference)
			for entity in range(targetting.size()):
				if targetting[entity] == seeking:
					defenderIndex = entity
					break
		
		action.HEAL:
			var seeking = groupLeastHealth("Ally", enemyData.allyHPPreference)
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

func genericGroup(targetting, _move):
	var defenderIndex: int
	match actionMode:
		action.KILL:
			var seeking = groupLeastHealth("Opposing",enemyData.oppHPPreference)
			
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

func SingleSelect(targetting, move):
	var trgt
	if enemyData.AICodePath != "":
		trgt = aiInstance.Single(targetting, move)
	else:
		trgt = genericSingle(targetting,move)
	return trgt

func GroupSelect(targetting, move):
	var trgt
	if enemyData.AICodePath != "":
		trgt = aiInstance.Group(targetting, move)
	else:
		trgt = genericGroup(targetting, move)
	return trgt

#-----------------------------------------
#GET MOVE
#-----------------------------------------
func getDamagingMoves(allowed) -> Array:
	var damagingMoves: Array[Move] = []
	
	for move in allowed:
		if move.property & 1 or move.property & 2 or move.property & 4:
			damagingMoves.append(move)
	
	return damagingMoves

func getHighDamage(allowed) -> Move:
	var damageMove: Move
	
	for move in allowed:
		if move.property & 1 or move.property & 2 or move.property & 4:
			if damageMove == null:
				damageMove = move
			elif move.Power > damageMove.Power:
				damageMove = move
	
	return damageMove

#For Phy, Bal and BOMB moves
func getElementMoves(allowed,elementType = "") -> Array:
	var elementMoves: Array = []
	var phyBool: bool = false
	
	if elementType in ["Fire", "Water", "Elec"]:
		print("Checking Elements")
		phyBool = false
	elif elementType != "" and elementType in ["Slash", "Crush", "Pierce"]:
		print("Checking Phy Elements")
		phyBool = true
	
	for move in allowed:
		var moveProperty = move.property & 1 or move.property & 2 or move.property & 4
		var checkingEle = move.element
		if phyBool:
			checkingEle = move.phyElement
		
		if (moveProperty and ((elementType == "" and checkingEle != "Neutral")
		or checkingEle == elementType)):
			print("Found element move ", move.name)
			elementMoves.append(move)
	
	return elementMoves

func getHealMoves(allowed, type = "") -> Array:
	var healMoves: Array = []
	
	for move in allowed:
		if move.property & 16: match type:
			"HP":
				if move.healing > 0:
					print("Found heal HP move ", move.name)
					healMoves.append(move)
			"Ailment":
				if move.HealAilAmmount > 0:
					print("Found heal Ail move ", move.name)
					healMoves.append(move)
			"Revive":
				if move.revive == true:
					print("Found revive move ", move.name)
					healMoves.append(move)
			_:
				print("Found heal move ", move.name)
				healMoves.append(move)
	
	return healMoves

#Works for buffs[stat,conditon]
func getFlagMoves(allowed, property, specificType = 0) -> Array: 
	var moveArray: Array = []
	
	for move in allowed:
		var checking
		var boolAny: bool = false
		var boolSpecific: bool = false
		
		match property:
			"Buff":
				checking = move.BoostType
				boolAny = checking != 0 and move.BoostAmmount > 0
				boolSpecific = checking & specificType
			"Debuff":
				checking = move.BoostType
				boolAny = checking != 0 and move.BoostAmmount < 0
				boolSpecific = checking & specificType
			"Condition":
				checking = move.Condition
				boolAny = checking != 0
				boolSpecific = checking & specificType
		
		if specificType == 0:
			boolSpecific = true
		
		if move.property & 8 and boolAny and boolSpecific:
			moveArray.append(move)
	return moveArray

#works for eleChange, ailments and aura moves
func getEnumMoves(allowed, property, specificType = "") -> Array: 
	var moveArray: Array = []
	var propertyFlag: int
	match property:
		"EleChange":
			propertyFlag = 8
		"Aura":
			propertyFlag = 128
		"Ailment":
			propertyFlag = 256
	
	for move in allowed:
		var checking
		var boolAny
		var boolSpecific
		match property:
			"EleChange":
				checking = move.ElementChange
				boolAny = specificType == "" and checking != "None"
			"Aura":
				checking = move.Aura
				boolAny = specificType == "" and checking != "None"
			"Ailment":
				checking = move.Ailment
				boolAny = specificType == "" and checking != "None"
		
		boolSpecific = checking == specificType
		
		if (move.property & propertyFlag and (boolAny or boolSpecific)):
			print(move.property & propertyFlag, boolAny, boolSpecific)
			print("Found move ", move.name)
			moveArray.append(move)
	
	return moveArray

func getSummonMove(allowed) -> Move:
	for move in allowed:
		if move.property & 128:
			return move
	
	return null

func getSpecificMove(allowed, moveName) -> Move:
	for move in allowed:
		if move.name == moveName:
			return move
	
	return null

#-----------------------------------------
#ENEMY PERCIEVE SELF
#-----------------------------------------
func selfLeastHealth(limit: float) -> bool: 
	#Returns if low health of self is lower than limit
	var leftover: float = float(currentHP)/data.MaxHP
	return leftover >= limit

func selfElement(desiredElement = "") -> bool: 
	#Returns if element is what the user wants
	if desiredElement == "":
		return data.TempElement == desiredElement
	else:
		return true

func selfBuffStatus() -> Array: #Return what conditions is in self
	return statBoostSlots

func selfCondition() -> Array: #Every condition the self has
	var ConditionArray: Array =[]
	
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i
		if data.Condition != null and data.Condition & flag != 0:
			ConditionArray.append(HelperFunctions.Flag_to_String(flag,"Condition"))
	
	return ConditionArray

func selfAilments() -> Array: #Return how ailment stack and current Ailment of self
	var ailment = [data.Ailment , data.AilmentNum]
	return ailment

func selfItemProperties() -> int:
	var bitMask: int = 0
	#It only needs to check if a prooperty shows up once
	for item in data.itemData.keys():
		var properyBit = 1 << item.attackData.property
		bitMask |= properyBit
	return bitMask

#-----------------------------------------
#ENEMY PERCIEVE GROUP
#-----------------------------------------
func groupLeastHealth(group, limit: float = 1.0): 
	#Returns ally with least health if they're below a threshold
	var leastHealth
	var currentLeftover: float = 1
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var leftover: float = float(entity.currentHP) / entity.data.MaxHP
		if leftover < currentLeftover:
			leastHealth = entity
			currentLeftover = leftover
	
	if currentLeftover < limit:
		print(leastHealth, leastHealth.data.name, type_string(typeof(leastHealth)))
		return leastHealth 
	else:
		return

func groupLowHealth(group, limit: float) -> Array: 
	#How many allies are at custom defined low health
	var lowHealthGroup: Array[bool] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var leftover: float = float(entity.currentHP) / entity.data.MaxHP
		lowHealthGroup.append(leftover <= limit)
	
	return lowHealthGroup

func groupElements(group, desiredElement = "") -> Array: 
	#Return ally elements or if they all meet Desired Element
	var groupElementsArray: Array = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		if desiredElement == "":
			groupElementsArray.append(entity.data.TempElement)
		else:
			groupElementsArray.append(entity.data.TempElement == desiredElement)
	
	print(groupElementsArray)
	return groupElementsArray

func groupBuffStatus(group) -> Array: #Return every ally buffs
	var groupBuffs: Array[Array] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var buffs = [entity.data.attackBoost, entity.data.defenseBoost, entity.data.speedBoost, entity.data.luckBoost]
		groupBuffs.append(buffs)
	
	return groupBuffs

func groupCondition(group) -> Array: #Return what conditions is in every ally
	var groupConditions: Array[Array] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var conditionArray: Array = []
		for i in range(10):
			#Flag is the binary version of i
			var flag = 1 << i
			if entity.data.Condition != null and entity.data.Condition & flag:
				conditionArray.append(HelperFunctions.Flag_to_String(flag,"Condition"))
		groupConditions.append(conditionArray)
	
	return groupConditions

func groupAilments(group, category = false) -> Array: 
	#Return how ailment stack and current Ailment of allies
	var groupAilmentsArray: Array[Array] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var ailmentArray: Array
		if category:
			ailmentArray = [ailmentCategory(entity), entity.data.AilmentNum]
		else:
			ailmentArray = [entity.data.Ailment , entity.data.AilmentNum]
		groupAilmentsArray.append(ailmentArray)
	
	return groupAilmentsArray

func learnOpposing(): 
	#REACTIONARY: Learn any other wierd tricks the players are using
	pass

#-----------------------------------------
#ENEMY PERCIEVE OTHER
#-----------------------------------------
func internalizeAura():
	pass

func internalizeTP(type):
	match type:
		"Current":
			return allyCurrentTP > opposingCurrentTP
		"Max":
			return allyMaxTP > opposingMaxTP
		"Predict":
			return allyCurrentTP + allyMaxTP * .5
		"Hedge":
			return opposingCurrentTP + opposingMaxTP * .5

#-----------------------------------------
#GENERIC DECICION MAKING
#-----------------------------------------
func decideAttack(allowed):
	var lowHPArray: Array = groupLowHealth("Opposing", enemyData.oppHPPreference)
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

func decideHeal(allowed) -> Move:
	var lowHPArray: Array = groupLowHealth("Ally", enemyData.allyHPPreference)
	var foundLow: int = 0
	#Is there an item or move that heals?
	if getHealMoves(allowed, "HP").size() != 0: 
		for entityLow in lowHPArray:
			if entityLow:
				foundLow += 1
				break
		
		if foundLow != 0:
			actionMode = action.HEAL
			return getHealMoves(allowed, "HP").pick_random()
	
	if getHealMoves(allowed, "Ailment").size() != 0:
		var i: int = 0
		for entity in groupAilments("Ally", true):
			if ((entity[0] == "Mental" or entity[0] == "Chemical")
			and entity[1] > enemyData.allyAilmentPreference):
				actionMode = action.AILHEAL
				focusIndex = allAllies[i].ID
				return getHealMoves(allowed, "Ailment").pick_random()
			else: i += 1
	
	return null

func decideBuff(allowed) -> Move:
	if getFlagMoves(allowed, "Buff").size() == 0:
		return null
	
	var canBuff: bool = false
	var buffedNum: Array = []
	var buffedFlags: Array = []
	
	for entity in groupBuffStatus("Ally"): #BUFF IF NOT BUFFED
		buffedNum.append(0)
		buffedFlags.append(0)
		for buff in range(entity.size()):
			var buffFlag = int(pow(2,buff))
			if not (buffFlag & enemyData.allyBoostTypePreference): continue
			
			if entity[buff] > enemyData.allyBuffAmmountPreference:
				#1 for atk, 2, for def, 4 for spd, and 8 for luk
				buffedFlags[-1] += buffFlag
				buffedNum[-1] += 1
				print("FlagCurrently:", buffedFlags[-1])
		
		#Check if they have proper ammount of buffs
		if buffedNum[-1] < enemyData.allyBuffNumPreference:
			canBuff = true
	
	if canBuff:
		canBuff = false
		actionMode = action.BUFF
		
		for entity in allAllies: #Must have buff moves of that type to be viable
			focusIndex = entity.ID
			
			if (entity.data.attackBoost < enemyData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 1).size() != 0):
				return getFlagMoves(allowed, "Buff", 1).pick_random()
			
			if (entity.data.defenseBoost < enemyData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 2).size() != 0):
				return getFlagMoves(allowed, "Buff", 2).pick_random()
			
			if (entity.data.speedBoost < enemyData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 4).size() != 0):
				return getFlagMoves(allowed, "Buff", 4).pick_random()
			
			if (entity.data.luckBoost < enemyData.allyBuffAmmountPreference and 
			getFlagMoves(allowed, "Buff", 8).size() != 0):
				return getFlagMoves(allowed, "Buff", 8).pick_random()
	
	return null

func decideDebuff(allowed) -> Move:
	if getFlagMoves(allowed, "Debuff").size() == 0:
		return null
	
	var canDebuff: bool = false
	var debuffedNum: Array = []
	var debuffedFlags: Array = []
	
	for entity in groupBuffStatus("Opposing"): #DEBUFF IF NOT DEBUFFED
		debuffedNum.append(0)
		debuffedFlags.append(0)
		print("DEBUFF")
		for debuff in range(entity.size()):
			var debuffFlag = int(pow(2,debuff))
			if not (debuffFlag & enemyData.oppBoostTypePreference): continue
			
			if entity[debuff] > enemyData.oppBuffAmmountPreference:
				#1 for atk, 2, for def, 4 for spd, and 8 for luk
				debuffedFlags[-1] += debuffFlag 
				debuffedNum[-1] += 1
				print("FlagCurrently:", debuffedFlags[-1])
		
		#Check if they have proper ammount of buffs
		if debuffedNum[-1] < enemyData.oppBuffNumPreference:
			canDebuff = true
	
	if canDebuff:
		actionMode = action.DEBUFF
		
		for entity in allOpposing: #Must have buff moves of that type to be viable
			focusIndex = entity.ID
			if (entity.data.attackBoost < enemyData.oppBuffAmmountPreference and 
			getFlagMoves(allowed, "Debuff", 1).size() != 0):
				return getFlagMoves(allowed, "Debuff", 1).pick_random()
			
			if (entity.data.defenseBoost < enemyData.oppBuffAmmountPreference and 
			getFlagMoves(allowed, "Debuff", 2).size() != 0):
				return getFlagMoves(allowed, "Debuff", 2).pick_random()
			
			if (entity.data.speedBoost < enemyData.oppBuffAmmountPreference and 
			getFlagMoves(allowed, "Debuff", 4).size() != 0):
				return getFlagMoves(allowed, "Debuff", 4).pick_random()
			
			if (entity.data.luckBoost < enemyData.oppBuffAmmountPreference and 
			getFlagMoves(allowed, "Debuff", 8).size() != 0):
				return getFlagMoves(allowed, "Debuff", 8).pick_random()
	
	return null

func decideEleChange(allowed):
	if getEnumMoves(allowed, "EleChange").size() == 0:
		return null

func decideCondition(allowed):
	if getFlagMoves(allowed, "Condition").size() == 0:
		return null

func decideAilment(allowed):
	if getEnumMoves(allowed, "Ailment").size() == 0:
		return null
	
	var canAilm: bool = false
	
	for entity in groupAilments("Opposing", true):
		if (entity != "Mental" or entity != "Chemical"):
			canAilm = true
	
	if canAilm:
		for entity in allOpposing:
			if entity.data.AilmentNum < enemyData.oppAilmentPreference:
				focusIndex = entity.ID
				return getEnumMoves(allowed, "Ailment").pick_random()
	
	return null

func decideAura(_allowed):
	pass

func decideSummon(_allowed):
	pass

#-----------------------------------------
#UI CHANGES
#-----------------------------------------
func displayMove(move) -> void:
	InfoBox.show()
	Info.text = str(data.name, " used ", move.name)

func makeDesc() -> void:
	var foundWeak: bool
	var foundRes: bool
	var weak: String = ""
	var strong: String = ""
	var moveString: String = ""
	var itemString: String = ""
	var stats = str("str:",data.strength,"| tgh:",data.toughness," | bal:",data.ballistics
	,"\nres:",data.resistance," | spd:",data.speed," | luk:",data.luck)
	
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i
		if flag & data.Weakness:
			foundWeak = true
			if flag & 512: #Override all else if All is present
				weak = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")))
			else:
				weak = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),weak)
		if flag & data.strong:
			foundRes = true
			if flag & 512:
				strong = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")))
			else:
				strong = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),", ",strong)
	
	if foundWeak:
		weak = str("Weak: ", weak)
	if foundRes:
		strong = str("Res: ", strong)
	
	for move in moveset:
		if move.name == "Attack" or move.name == "Wait":
			continue
		
		if move is Item:
			if itemString != "":
				itemString = str(items,",","[",data.itemData.get(move),"/",move.maxItems,"]",move.name)
			else:
				itemString = str("[",data.itemData.get(move),"/",move.maxItems,"]",move.name)
			
		else:
			if moveString != "":
				moveString = str(moveString,",",move.name)
			else:
				moveString = str(move.name)
	
	if moveString != "":
		moveString = str("Moves: ", moveString)
	if itemString != "":
		itemString = str("Items:", itemString)
	
	if weak == "":
		weak = str("No Weaknesses")
	if strong == "":
		strong = str("No Resistances")
	if moveString == "":
		moveString = str("Only Attacks")
	if itemString == "":
		itemString = str("No Items")
	
	description = str(weak,"\n",strong,"\n",stats,"\n",moveString,"\n",itemString)

#-----------------------------------------
#PAYING ITEM&TP
#-----------------------------------------
func payCost(move) -> int:
	if move.CostType == "Item":
		for item in data.itemData:
			if item.name == move.name:
				data.itemData[item] -= move.cost
	
	return int(move.TPCost - (data.speed * (1 + data.speedBoost)))

func allowedMoveset(TP) -> Array:
	var allowed: Array = []
	for move in moveset:
		var use = move
		if move is Item:
			if data.itemData[move] == 0:
				print("Ran out of ", move.name)
				continue
			else:
				use = move.attackData
		
		var TPCost = use.TPCost - (data.speed * (1 + data.speedBoost))
		if Globals.currentAura == "LowTicks":
			TPCost = TPCost / 2
		
		if TP > TPCost:
			allowed.append(use)
	
	if allowed.size() == 0: #if they can't use anything else they have to wait
		allowed.append(data.waitData)
	
	return allowed

func getGroup(group: String) -> Array:
	if group == "Ally":
		return allAllies
	else:
		return allOpposing

#-----------------------------------------
#DEBUG
#-----------------------------------------
func debugAIPerceive() -> void:
	print("-------------------------------------")
	print("SELF PERCEPTION")
	print("-------------------------------------")
	print("LESS THAN HALF HP: ", selfLeastHealth(.5))
	print("IS ELEMENT FIRE: ", selfElement("Fire"))
	print("BUFFS: ", selfBuffStatus())
	print("CONDITIONS: ", selfCondition())
	print("AILMENTS: ", selfAilments())
	
	print("-------------------------------------")
	print("\nALLY PERCEPTION")
	print("-------------------------------------")
	print("ALLIES: ", allAllies)
	print("LEAST HEALTH ", groupLeastHealth("Ally"))
	print("LESS THAN 50% THOUGH? ", groupLeastHealth("Ally", .5))
	print("LESS THAN 90% HP: ", groupLowHealth("Ally", .9))
	print("ELEMENT: ", groupElements("Ally"))
	print("IS ELEMENT FIRE: ", groupElements("Ally", "Fire"))
	print("BUFFS: ", groupBuffStatus("Ally"))
	print("CONDITIONS: ", groupCondition("Ally"))
	print("AILMENTS: ", groupAilments("Ally", false))
	
	print("-------------------------------------")
	print("\nOPPOSING PERCEPTION")
	print("-------------------------------------")
	print("OPPOSING", allOpposing)
	print("LEAST HEALTH ", groupLeastHealth("Opposing"))
	print("LESS THAN 50% THOUGH? ", groupLeastHealth("Opposing", .5))
	print("LESS THAN 90% HP: ", groupLowHealth("Opposing", .9))
	print("ELEMENT: ", groupElements("Opposing"))
	print("IS ELEMENT FIRE: ", groupElements("Opposing", "Fire"))
	print("BUFFS: ", groupBuffStatus("Opposing"))
	print("CONDITIONS: ", groupCondition("Opposing"))
	print("AILMENTS: ", groupAilments("Opposing", false))
	
	print("-------------------------------------")
	print("\nOTHER PERCEPTION")
	print("-------------------------------------")
	print("TPS: ALLY:", allyCurrentTP, allyMaxTP)
	print("OPPOSING: ", opposingCurrentTP, opposingMaxTP)
