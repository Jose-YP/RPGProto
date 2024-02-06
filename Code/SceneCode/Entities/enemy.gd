extends "res://Code/SceneCode/Entities/Entity.gd"

@onready var EnemyLabel = $NameContainer/RichTextLabel
@onready var enemyData = data.specificData
@onready var ScanBox = $ScanBox
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

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	moreReady()
	EnemyLabel.append_text(str("[b][",data.species,"][/b]",data.name))
	moveset = data.skillData + items
	moveset.append(data.attackData)
	
	match enemyData.AIType:#Determine which AI to use
		"Random":
			enemyAI = preload("res://Code/EnemyAI/EnemyRandom.gd")
		"Pick Off":
			enemyAI = preload("res://Code/EnemyAI/EnemyPickOff.gd")
		"Support":
			pass
			#enemyAI = preload("res://Code/EnemyAI/Test.gd")
		"Debuff":
			enemyAI = preload("res://Code/EnemyAI/EnemyDebuff.gd")
	
	aiInstance = enemyAI.new()
	makeDesc()
	$ScanBox/ScanDescription.append_text(description)

func _process(_delta):
	processer()
	#deletes items after using all of them
	for thing in data.itemData:
		if data.itemData[thing] <= 0:
			moveset.erase(thing)

#-----------------------------------------
#ENEMYAI
#-----------------------------------------
func chooseMove(TP,allies,opposing) -> Move:
	var move: Resource
	allyCurrentTP = TP
	allAllies = allies
	allOpposing = opposing
	var allowed = allowedMoveset(TP)
	
	debugAIPerceive()
	
	match enemyData.AIType:
		"Random":
			move = aiInstance.RandomMove(allowed)
			if move is Item:
				move = move.attackData
			return move
		"Pick Off": #This Ai should KILL
			pass
		"Support": #This Ai should prioritize healing
			pass
		"Debuff": #This Ai should prioritize buffing moves
			move = aiInstance.ShouldDebuff(allowed,allies,opposing)
		_:
			pass
	
	return move

#-----------------------------------------
#ENEMY PERCIEVE SELF
#-----------------------------------------
func selfLeastHealth(limit: float) -> bool: #Returns if low health of self is lower than limit
	var leftover: float = float(currentHP)/data.MaxHP
	return leftover >= limit

func selfElement(desiredElement = ""): #Returns if element is what the user wants
	if desiredElement == "":
		return data.TempElement == desiredElement
	else:
		return true

func selfBuffStatus() -> Array: #Return what conditions is in self
	var buffs = [data.attackBoost, data.defenseBoost, data.speedBoost, data.luckBoost]
	return buffs

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
func groupLeastHealth(group, limit: float): #Returns ally with least health if they're below a threshold
	var leastHealth
	var currentLeftover: float = 1
	
	for entity in group:
		var leftover: float = float(entity.currentHP) / data.MaxHP
		if leftover < currentLeftover:
			leastHealth = entity
			currentLeftover = leftover
	
	if currentLeftover >= limit:
		print(leastHealth, type_string(typeof(leastHealth)))
		return leastHealth 
	else:
		return null

func groupLowHealth(group, limit: float) -> Array: #How many allies are at custom defined low health
	var lowHealthGroup: Array[bool] = []
	
	for entity in group:
		var leftover: float = float(entity.currentHP) / entity.data.MaxHP
		lowHealthGroup.append(leftover >= limit)
	
	return lowHealthGroup

func groupElements(group, desiredElement = "") -> Array: #Return ally elements or if they all meet Desired Element
	var groupElementsArray: Array = []
	
	for entity in group:
		if desiredElement == "":
			groupElementsArray.append(entity.data.TempElement)
		else:
			groupElementsArray.append(entity.data.TempElement == desiredElement)
	
	return groupElementsArray

func groupBuffStatus(group) -> Array: #Return every ally buffs
	var groupBuffs: Array[Array] = []
	
	for entity in group:
		var buffs = [entity.data.attackBoost, entity.data.defenseBoost, entity.data.speedBoost, entity.data.luckBoost]
		groupBuffs.append(buffs)
	
	return groupBuffs

func groupCondition(group) -> Array: #Return what conditions is in every ally
	var groupConditions: Array[Array] = []
	
	for entity in group:
		var conditionArray: Array
		for i in range(10):
			#Flag is the binary version of i
			var flag = 1 << i#If it says seekingFlag is a bool, that means it couldn't find a value in String to Flag
			if entity.data.Condition != null and entity.data.Condition & flag:
				conditionArray.append(HelperFunctions.Flag_to_String(flag,"Condition"))
		groupConditions.append(conditionArray)
	
	return groupConditions

func groupAilments(group) -> Array: #Return how ailment stack and current Ailment of allies
	var groupAilmentsArray: Array[Array] = []
	
	for entity in group:
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

func internalizeTP():
	pass

#-----------------------------------------
#TARGETTING TYPES
#-----------------------------------------
func SingleSelect(targetting,_move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			return trgt
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
			pass

func GroupSelect(targetting,_move):
	var trgt
	match enemyData.AIType:
		"Random":
			trgt = aiInstance.Single(targetting)
			return trgt
		"Pick Off":
			pass
		"Support":
			pass
		"Debuff":
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
	print("LESS THAN HALF HP: ", groupLeastHealth(allAllies, .5))
	print("ELEMENT: ", groupElements(allOpposing))
	print("IS ELEMENT FIRE: ", groupElements(allAllies, "Fire"))
	print("BUFFS: ", groupBuffStatus(allAllies))
	print("CONDITIONS: ", groupCondition(allAllies))
	print("AILMENTS: ", groupAilments(allAllies))
	
	print("-------------------------------------")
	print("\nOPPOSING PERCEPTION")
	print("-------------------------------------")
	print("OPPOSING", allOpposing)
	print("LESS THAN HALF HP: ", groupLeastHealth(allOpposing, .5))
	print("ELEMENT: ", groupElements(allOpposing))
	print("IS ELEMENT FIRE: ", groupElements(allOpposing, "Fire"))
	print("BUFFS: ", groupBuffStatus(allOpposing))
	print("CONDITIONS: ", groupCondition(allOpposing))
	print("AILMENTS: ", groupAilments(allOpposing))
	
	print("-------------------------------------")
	print("\nOTHER PERCEPTION")
	print("-------------------------------------")
	print("TPS: ALLY:", allyCurrentTP, allyMaxTP)
	print("OPPOSING: ", opposingCurrentTP, opposingMaxTP)
