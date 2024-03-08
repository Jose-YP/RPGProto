extends "res://Code/SceneCode/Entities/Entity.gd"

@onready var EnemyLabel: RichTextLabel = $NameContainer/RichTextLabel
@onready var enemyData: Enemy = data.specificData
@onready var ScanBox: PanelContainer = $ScanBox
@onready var gettingScanned: bool = false

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

enum action{KILL, BUFF, ELECHANGE, ETC}

var actionMode: action = action.ETC

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	moreReady()
	EnemyLabel.append_text(str("[b][",data.species,"][/b]",data.name))
	moveset = data.skillData + items
	moveset.append(data.attackData)
	
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
	aiInstance.allies = allies
	allOpposing = opposing
	aiInstance.opp = allies
	var allowed = allowedMoveset(TP)
	
	#debugAIPerceive()
	move = aiInstance.basicSelect(allowed)
	if move is Item:
		move = move.attackData
	
	return move

func SingleSelect(targetting, _move):
	var trgt = aiInstance.Single(targetting)
	return trgt

func GroupSelect(targetting, _move):
	var trgt = aiInstance.Group(targetting)
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
		if damageMove == null:
			damageMove = move
			print(move.name, " Damage ", damageMove.Power)
		elif move.Power > damageMove.Power:
			damageMove = move
			print(move.name, " Damage ", damageMove.Power)
	
	return damageMove

#For Phy, Bal and BOMB moves
func getElementMoves(allowed,elementType = "") -> Array:
	var elementMoves: Array = []
	var phyBool: bool = false
	
	if elementType in ["Fire", "Water", "Elec"]:
		print("Checking Elements")
		phyBool = false
	elif elementType in ["Slash", "Crush", "Pierce"]:
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

func getHealMoves(allowed) -> Array:
	var healMoves: Array = []
	
	for move in allowed:
		if move.property & 16:
			print("Found heal move ", move.name)
			healMoves.append(move)
	
	return healMoves

#Works for buffs[stat,conditon,eleChange], ailments and aura moves
func getFlagMoves(allowed, property, specificType = "") -> Array: 
	var moveArray: Array = []
	var propertyFlag: int
	match property:
		"Buff":
			propertyFlag = 8
			specificType = int(specificType)
		"Debuff":
			propertyFlag = 8
			specificType = int(specificType)
		"Condition":
			propertyFlag = 8
			specificType = int(specificType)
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
			"Buff":
				var boostAmmount: bool = move.BoostAmmount > 0
				checking = move.BoostType
				boolAny = specificType == 0 and checking != 0 and boostAmmount
				boolSpecific = checking & specificType
			"Debuff":
				var boostAmmount: bool = move.BoostAmmount < 0
				checking = move.BoostType
				boolAny = specificType == 0 and checking != 0 and boostAmmount
				boolSpecific = checking & specificType
			"Condition":
				checking = move.Condition
				boolAny = specificType == 0 and checking != 0
				boolSpecific = checking & specificType
			"EleChange":
				checking = move.ElementChange
				boolAny = specificType == "" and checking != "None"
				boolSpecific = checking == specificType
			"Aura":
				checking = move.Aura
				boolAny = specificType == "" and checking != "None"
				boolSpecific = checking == specificType
			"Ailment":
				checking = move.Ailment
				boolAny = specificType == "" and checking != "None"
				boolSpecific = checking == specificType
		
		if (move.property & propertyFlag and (boolAny or boolSpecific)):
			print("Found move ", move.name)
			moveArray.append(move)
		else:
			print(move.property & propertyFlag, boolAny, boolSpecific)
	
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
func selfLeastHealth(limit: float) -> bool: #Returns if low health of self is lower than limit
	var leftover: float = float(currentHP)/data.MaxHP
	return leftover >= limit

func selfElement(desiredElement = "") -> bool: #Returns if element is what the user wants
	if desiredElement == "":
		return data.TempElement == desiredElement
	else:
		return true

func selfBuffStatus() -> Array: #Return what conditions is in self
	print(statBoostSlots)
	return statBoostSlots

func selfCondition() -> Array: #Every condition the self has
	var ConditionArray: Array =[]
	
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i#If it says seekingFlag is a bool, that means it couldn't find a value in String to Flag
		if data.Condition != null and data.Condition & flag != 0:
			ConditionArray.append(HelperFunctions.Flag_to_String(flag,"Condition"))
	
	return ConditionArray

func selfAilments() -> Array: #Return how ailment stack and current Ailment of self
	var ailment = [data.Ailment , data.AilmentNum]
	return ailment

#-----------------------------------------
#ENEMY PERCIEVE GROUP
#-----------------------------------------
func groupLeastHealth(group, limit: float = 1.0): #Returns ally with least health if they're below a threshold
	var leastHealth
	var currentLeftover: float = 1
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var leftover: float = float(entity.currentHP) / data.MaxHP
		if leftover < currentLeftover:
			leastHealth = entity
			currentLeftover = leftover
	
	if currentLeftover >= limit:
		print(leastHealth, leastHealth.data.name, type_string(typeof(leastHealth)))
		return leastHealth 
	else:
		return

func groupLowHealth(group, limit: float) -> Array: #How many allies are at custom defined low health
	var lowHealthGroup: Array[bool] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var leftover: float = float(entity.currentHP) / entity.data.MaxHP
		lowHealthGroup.append(leftover >= limit)
	
	return lowHealthGroup

func groupElements(group, desiredElement = "") -> Array: #Return ally elements or if they all meet Desired Element
	var groupElementsArray: Array = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		print(entity.data.TempElement)
		if desiredElement == "":
			groupElementsArray.append(entity.data.TempElement)
		else:
			groupElementsArray.append(entity.data.TempElement == desiredElement)
	
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
			var flag = 1 << i#If it says seekingFlag is a bool, that means it couldn't find a value in String to Flag
			if entity.data.Condition != null and entity.data.Condition & flag:
				conditionArray.append(HelperFunctions.Flag_to_String(flag,"Condition"))
		groupConditions.append(conditionArray)
	
	return groupConditions

func groupAilments(group) -> Array: #Return how ailment stack and current Ailment of allies
	var groupAilmentsArray: Array[Array] = []
	var effectiveGroup = getGroup(group)
	
	for entity in effectiveGroup:
		var ailment = [entity.data.Ailment , entity.data.AilmentNum]
		groupAilmentsArray.append(ailment)
	
	return groupAilmentsArray

func learnOpposing(): #REACTIONARY: Learn any other wierd tricks the players are using
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
#UI CHANGES
#-----------------------------------------
func displayMove(move) -> void:
	InfoBox.show()
	Info.text = str(data.name, " used ", move.name)

func makeDesc() -> void:
	var foundWeak: bool
	var foundRes: bool
	var weak: String = ""
	var resist: String = ""
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
		if flag & data.Resist:
			foundRes = true
			if flag & 512:
				resist = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")))
			else:
				resist = str(HelperFunctions.colorElements(HelperFunctions.Flag_to_String(flag,"Element")),", ",resist)
	
	if foundWeak:
		weak = str("Weak: ", weak)
	if foundRes:
		resist = str("Res: ", resist)
	
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
	if resist == "":
		resist = str("No Resistances")
	if moveString == "":
		moveString = str("Only Attacks")
	if itemString == "":
		itemString = str("No Items")
	
	description = str(weak,"\n",resist,"\n",stats,"\n",moveString,"\n",itemString)

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
	print("AILMENTS: ", groupAilments("Ally"))
	
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
	print("AILMENTS: ", groupAilments("Opposing"))
	
	print("-------------------------------------")
	print("\nOTHER PERCEPTION")
	print("-------------------------------------")
	print("TPS: ALLY:", allyCurrentTP, allyMaxTP)
	print("OPPOSING: ", opposingCurrentTP, opposingMaxTP)
