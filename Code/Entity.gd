extends Node2D

@export var data: entityData

@onready var InfoBox: PanelContainer = $CurrentInfo
@onready var Info: RichTextLabel = $CurrentInfo/RichTextLabel
@onready var selected: Sprite2D = $Arrow
@onready var HPBar: TextureProgressBar = $HPBar
@onready var HPtext: RichTextLabel = $HPBar/RichTextLabel
@onready var currentCondition: RichTextLabel = $ConditionDisplay
@onready var AilmentImages = $AilmentDisplay/AilmentType.get_children()
@onready var XSoftTabs = $XSoftDisplay/HBoxContainer.get_children()
@onready var XSoftSlots = []
@onready var basicAttack = data.attackData
@onready var attacks: Array = [basicAttack]
@onready var items: Array = []

signal overdriveReady(overdrive)

var currentHP: int
var feedback: String
var TPArray: Array = []

#Determines which targetting system to use
enum target {
	SINGLE,
	GROUP,
	RANDOM,
	SELF,
	ALL,
	NONE}

#-----------------------------------------
#INITIALIZATION & PROCESSING
#-----------------------------------------
func _ready():
	moreReady()

func moreReady():#Make a function so it'll work on parent and child nodes
	currentHP = data.MaxHP
	HPtext.text = str("HP: ", currentHP)
	data.TempElement = data.element
	items = data.itemData.keys()
	
	for tab in $XSoftDisplay/HBoxContainer.get_children():
		XSoftSlots.append(tab.get_children())

func _process(_delta):
	processer()

func processer():
	if currentHP <= 0:
		currentHP = 0
		HPtext.text = str("HP: ", currentHP)
	
	for k in range(4):
		if Globals.elementGroups[k] == data.TempElement:
			$CurrentElement.current_tab = k
	
	for soft in range(data.XSoft.size()): #Show any XSofts that are on the entity
		var oneTrue = false
		for i in range(6):
			if data.XSoft[soft] == XSoftSlots[soft][i].name:
				$XSoftDisplay.show()
				XSoftTabs[soft].current_tab = i
				XSoftTabs[soft].show()
				oneTrue = true
			if not oneTrue:
				XSoftTabs[soft].hide()
	
	if data.XSoft.size() == 0: #If there are none, hide display
		$XSoftDisplay.hide()
	
	for i in range(AilmentImages.size()): #If the entity has any Ailments show them
		if data.Ailment == AilmentImages[i].name:
			$AilmentDisplay.show()
			$AilmentDisplay/AilmentType.current_tab = i
			$AilmentDisplay/AilmentNum.text = str(data.AilmentNum)
		
	if data.AilmentNum <= 0: #Otherwise hide the display
		data.Ailment = "Healthy"
		$AilmentDisplay.hide()
	if data.Ailment == "Overdrive": #Overdrive can only have an Ailment Num of 1
		data.AilmentNum = 1

#--------------------------------
#MOVE PROPERTYS
#-----------------------------------------
func attack(move, defender, user, property, aura):
	var attackStat: int
	var defenseStat: int
	var softMod: float = 0.0
	var offenseElement = user.data.TempElement
	var offensePhyEle = move.phyElement
	var critMod = 0
	var phyMod = 0
	var auraMod = 1
	feedback = ""
	
	#If a move has Neutral Element it will copy the user's element instead
	if move.element == "Neutral":
		offenseElement = user.data.element
	var elementMod = elementModCalc(offenseElement, defender.data.element)
	
	#Basic Attacks will use the user's PhyElement instead of the move's
	#Every other attack uses the move's PhyElement
	if move.name == "Attack" or move.name == "Crash" or move.name == "Burst":
		offensePhyEle = user.data.phyElement
	
	phyMod = phy_weakness(offensePhyEle, defender.data)
	if phyMod > .25:
		feedback = str("{",offensePhyEle," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",offensePhyEle," Resist}", feedback)
	
	if elementMod >= 1.25:
		feedback = str("{",offenseElement," Weak}", feedback)
	if elementMod <= .75:
		feedback = str("{",offenseElement," Resist}", feedback)
	
	var prev = softMod
	softMod += checkXSoft(offenseElement, defender)
	if prev < softMod:
		feedback = str("{",offenseElement," Soft}", feedback)
	prev = softMod
	softMod += checkXSoft(offensePhyEle, defender)
	if prev < softMod:
		feedback = str("{",offensePhyEle," Soft}", feedback)
	
	match property:
		"Physical":
			attackStat = user.data.strength
			defenseStat = defender.data.toughness
			if aura == "BodyBroken":
				feedback = str("{",aura,"}",feedback)
				auraMod = .5
		"Ballistic":
			attackStat = user.data.ballistics
			defenseStat = defender.data.resistance
			if aura == "WillWrecked":
				feedback = str("{",aura,"}",feedback)
				auraMod = .5
	
	if crit_chance(move,user,defender,aura):
		critMod = .25
		feedback = str("{Crit}", feedback)
	
	var totalFirstMod = 1 + user.data.attackBoost + phyMod + softMod + critMod
	var totalSecondMod = auraMod*elementMod
	#Get total attack power, subtract it by total defense then multiply by element mod*AuraMod
	var damage = ((randi_range(0,user.data.level) + move.Power + attackStat) * totalFirstMod)
	damage =  damage - ((1.25 * defenseStat) * (1 + defender.data.defenseBoost))
	damage = int(totalSecondMod*(damage))
	
	if damage <= 0:
		damage = 1
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func BOMB(move,defender):
	feedback = ""
	var softMod: float = 0
	var prev = softMod
	var phyMod: float = 0
	var elementMod = elementModCalc(move.element, defender.data.element)
	
	phyMod = phy_weakness(move.phyElement, defender.data)
	if phyMod > .25:
		feedback = str("{",move.phyElement," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",move.phyElement," Resist}", feedback)
	
	if elementMod >= 1.25:
		feedback = str("{",move.element," Weak}", feedback)
	elif elementMod <= .75:
		feedback = str("{",move.element," Resist}", feedback)
	
	softMod += checkXSoft(move.element, defender)
	if prev < softMod:
		feedback = str("{",move.element," Soft}", feedback)
	prev = softMod
	softMod += checkXSoft(move.phyElement, defender)
	if prev < softMod:
		feedback = str("{",move.phyElement," Soft}", feedback)
	
	#Bomb attack don't use attack or defense
	var damage = elementMod * (move.Power * (1 + phyMod + softMod))
	
	feedback = str(damage, " BOMB Damage!", feedback)
	return damage

func healHP(move,defender):
	var healAmmount = move.healing
	if move.percentage:
		healAmmount = int((float(move.healing)/100) * float(defender.data.MaxHP))
	
	feedback = str(healAmmount," HP Healed!")
	
	return healAmmount

func healAilment(move, defender):
	var canHeal = true
	if move.HealedAilment == "All":
		defender.data.AilmentNum -= move.HealAilAmmount
		defender.data.XSoft.pop_front()
	
	var category = ailmentCategory(defender)
	
	if category != "Mental" or category != "Nonmental":
		canHeal = false
	
	if (category == move.HealedAilment or defender.data.Ailment == move.HealedAilment 
	or move.HealedAilment == "Negative") and canHeal:
		defender.data.AilmentNum -= move.HealAilAmmount
		if defender.data.AilmentNum <= 0:
			defender.data.AilmentNum  = 0

func applyNegativeAilment(move,defender,user,preWin = false):
	if move.BaseAilment > 200:
		preWin = true
	
	#If the ailment calc returns true then apply ailment to defender
	if ailment_calc(move,defender,user) or preWin:
		#Raise number first so Ailment doesn't instantly become Healthy from process
		if defender.data.AilmentNum <= 3:
			defender.data.AilmentNum += move.AilmentAmmount
		
		if move.Ailment != defender.data.Ailment:
			defender.data.Ailment = move.Ailment

func applyPositiveAilment(move,defender):
	if ailmentCategory(defender) != "Mental" or  ailmentCategory(defender) != "Nonmental":
		if move.Ailment == "Protected":
			defender.data.AilmentNum += 1
			defender.data.Ailment = "Protected"
		else:
			defender.data.AilmentNum += 1
			defender.data.Ailment = "Overdrive"
			overdriveReady.emit(true)

func applyXSoft(move,defender,user,preWin = false,PreSoft = ""):
	var win = preWin
	var times = move.AilmentAmmount
	var ele
	
	if preWin or move.BaseAilment >= 200:
		win = true
	
	if not win:
		win = ailment_calc(move,defender,user)
	
	if HelperFunctions.emptyXSoftSlots(defender.data.XSoft) != 0 or defender.data.XSoft.size() < 3:
		if win:
			if PreSoft != "":
				ele = PreSoft
			elif move.Ailment == "PhySoft":
				ele = move.phyElement
			else:
				ele = determineXSoft(move,user)
	
	for i in times:
		defender.data.XSoft = HelperFunctions.NullorAppend(defender.data.XSoft,ele)

func buffStat(defender,boostType,boostAmmount = 1):#For actively buffing and debuffing moves
	if boostType & 1:
		defender.data.attackBoost += (boostAmmount * .3)
		buffStatManager(defender.get_node("Buffs/Attack"),defender.data.attackBoost)
	if boostType & 2:
		defender.data.defenseBoost += (boostAmmount * .3)
		buffStatManager(defender.get_node("Buffs/Defense"),defender.data.defenseBoost)
	if boostType & 4:
		defender.data.speedBoost += (boostAmmount * .3)
		buffStatManager(defender.get_node("Buffs/Speed"),defender.data.speedBoost)
	if boostType & 8:
		defender.data.luckBoost += (boostAmmount * .3)
		buffStatManager(defender.get_node("Buffs/Luck"),defender.data.luckBoost)

func buffCondition(move,defender):
	defender.data.Condition |= move.Condition
	currentCondition.text = HelperFunctions.Flag_to_String(defender.data.Condition, "Condition")

func buffElementChange(move,defender,user):
	var prev = defender.data.TempElement
	match move.ElementChange:
		"TWin":
			defender.data.TempElement = elementMatchup(true,defender.data.TempElement)
		"TLose":
			defender.data.TempElement = elementMatchup(false,defender.data.TempElement)
		"UWin":
			defender.data.TempElement = elementMatchup(true,user.data.TempElement)
		"ULose":
			defender.data.TempElement = elementMatchup(false,user.data.TempElement)
		_:
			defender.data.TempElement = move.ElementChange
	
	if prev == str(defender.data.TempElement):
		feedback = str("Element unchanged")
	else:
		feedback = str(prev," changed to ",defender.data.TempElement)
#-----------------------------------------
#MOVE HELPERS
#-----------------------------------------
func elementModCalc(userElement,defenderElement,PreMod = 0):
	var ElementModifier: float = 1
	
	match userElement:
		"Fire":
			match defenderElement:
				"Water":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Water":
			match defenderElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = .75 - PreMod
				_:
					ElementModifier = 1
		"Elec":
			match defenderElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Water":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Light":
			match defenderElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Comet":
			match defenderElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Water":
					ElementModifier = .75 - PreMod
				_:
					ElementModifier = 1
		"Aurora":
			match defenderElement:
				"Water":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = .75 - PreMod
				_:
					ElementModifier = 1
		"Aether":
			ElementModifier = 1.25 + PreMod
		_:
			ElementModifier = 1
	
	return ElementModifier

func elementMatchup(matchup,targetElement):
	var returnElement
	var elements = ["Fire","Water","Elec"]
	
	match targetElement:
		"Fire":
			if matchup:
				returnElement = "Elec"
			else:
				returnElement = "Water"
		"Water":
			if matchup:
				returnElement = "Fire"
			else:
				returnElement = "Elec"
		"Elec":
			if matchup:
				returnElement = "Water"
			else:
				returnElement = "Fire"
		_:
			returnElement = elements[randi()%elements.size()]
	
	return returnElement

func phy_weakness(user,defender,PreMod = 0):
	var PhyMod = 0
	
	if user == "Neutral":
		return 0
	if user == "All":
		PhyMod += .25 + PreMod
		return PhyMod
	
	var userFlag = HelperFunctions.String_to_Flag(user,"Element")
	
	#Search every possible flag in Weakness and resist
	#Make sure to check if the defender even has a weakness/resistance
	for i in range(6):
		#Flag is the binary version of i
		var flag = 1 << i
		#Check if it has a weakness if it does don't check resistance
		if defender.Weakness != null and defender.Weakness & flag != 0 and userFlag & flag != 0:
			PhyMod += .25  + PreMod
			continue
		
		#Check if it has a resistance otherwise
		if defender.Resist != null and defender.Resist & flag != 0 and userFlag & flag != 0:
			print(defender.Resist, flag, userFlag)
			PhyMod -= .25
	
	return PhyMod

func crit_chance(move,user,defender,aura):
	var crit = false
	var auraMod = 1
	if aura == "CritDouble":
		auraMod = 2
	
	var chance = move.BaseCrit + (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck)
	chance = chance - (defender.data.luck * sqrt(defender.data.luck) * (1 + defender.data.luckBoost))
	chance *= auraMod
	
	#evil tracia rng lol
	if chance > 100:
		chance = 99
	if chance <= 0:
		chance = 1
	
	if randi() % 100 <= chance:
		crit = true
		applyXSoft(move,user,defender,true,determineXSoft(move,user))
	
	return crit

func ailment_calc(move,user,defender):#Ailment chance is like crit chance except it also depends on element matchups
	var ailment = false
	var offenseElement = user.data.element
	
	if move.element != "neutral":
		offenseElement = move.element
	var elementMod = elementModCalc(offenseElement, defender.data.element)
	
	var chance = (move.BaseAilment + (elementMod * (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck))
	- (defender.data.luck * sqrt(defender.data.luck) * (1 + defender.data.luckBoost)))
	
	#Not evil for this
	if chance > 100:
		chance = 100
	if chance <= 0:
		chance = 0
	
	if randi() % 100 <= chance:
		ailment = true 
	
	return ailment

func ailmentCategory(defender):#Will check if an ailment fits under the boxes: Physical, Mental, Negative and/or Positive
	print("Defender Ailemnt: ",defender.data.Ailment)
	match defender.data.Ailment:
		"Healthy":
			return "Healthy"
		"Overdrive":
			return "Overdrive"
		"Protected":
			return "Protected"
		_:
			if (defender.data.Ailment == "Reckless" or defender.data.Ailment == "Miserable" or 
			defender.data.Ailment == "Miserable" or defender.data.Ailment == "Dumbfounded"):
				return "Mental"
			else:
				return "Nonmental"

func determineXSoft(move,user):
	match move.Ailment:
		"PhySoft":
			return move.PhyElement
		"EleSoft":
			return move.Element
		_:
			if move.phyElement != "Neutral":
				return move.phyElement
			elif move.element != "Neutral":
				return move.element
			else:
				return user.data.phyElement

func checkCondition(seeking,defender):
	var seekingFlag = HelperFunctions.String_to_Flag(seeking,"Condition")
	var found = false

	#Search every possible flag in condition
	#Make sure to check if the defender even has a weakness/resistance
	for i in range(9):
		#Flag is the binary version of i
		var flag = 1 << i
		if defender.Condition != null and defender.Condition & flag != 0 and defender.Condition & seekingFlag != 0:
			found = true

	return found

func checkXSoft(seeking,defender):
	var softAmmount: float = 0.0
	var k: int = 0
	if seeking == "Neutral":
		return 0
	
	for element in defender.data.XSoft:
		k += 1
		if seeking == element:
			softAmmount += .15
			break
	
	while k != (defender.data.XSoft.size()):
		if seeking == defender.data.XSoft[k]:
			softAmmount += .1
		k += 1
	
	return softAmmount

#-----------------------------------------
#UI CHANGES
#-----------------------------------------
func hideDesc():
	InfoBox.hide()
	Info.clear()

func displayQuick(quick):
	Info.text = quick
	InfoBox.show()
	$Timer.start()

func buffStatManager(type,ammount):#Called whenever a buffed stat is changed
	var label = type.get_child(0)
	label.text = str(100 * ammount,"%")
	
	if ammount > 0:
		type.modulate = Color(1, 0.278, 0.357, 0.671)
	elif ammount < 0:
		type.modulate = Color(0.58, 0.592, 0.541, 0.671)
	
	type.show()

func _on_timer_timeout():
	hideDesc()
