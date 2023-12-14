extends Node2D

@export var data: entityData

@onready var quickInfo: TextEdit = $CurrentInfo
@onready var selected: Sprite2D = $Arrow
@onready var HPBar: TextureProgressBar = $HPBar
@onready var HPtext: RichTextLabel = $HPBar/RichTextLabel
@onready var AilmentImages = $AilmentDisplay/AilmentType.get_children()
@onready var XSoftTabs = $XSoftDisplay/HBoxContainer.get_children()
@onready var XSoftSlots = []
@onready var basicAttack = data.attackData
@onready var attacks: Array = [basicAttack]
@onready var items: Array = []


signal overdriveReady(overdrive)

var currentHP: int
var feedback: String
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
	attacks.append(data.attackData)
	items = data.itemData.keys()
	
	for tab in $XSoftDisplay/HBoxContainer.get_children():
		XSoftSlots.append(tab.get_children())
	
	#debug code
	if data == null:
		print("entityData file not set")

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
		
		pass
	
	if data.AilmentNum == 0: #Otherwise hide the display
		data.Ailment = "Healthy"
		$AilmentDisplay.hide()
	if data.Ailment == "Overdrive": #Overdrive can only have an Ailment Num of 1
		data.AilmentNum = 1

#--------------------------------
#MOVE PROPERTYS
#-----------------------------------------
func attack(move, defender, user, property, aura = ""):
	print(user)
	
	var attackStat: int
	var defenseStat: int
	var offenseElement = user.data.element
	var critMod = 0
	var phyMod = 0
	var auraMod = 1
	feedback = ""
	
	#If a move has Neutral Element it will copy the user's element instead
	if move.element == "neutral":
		offenseElement = user.data.element
	var elementMod = elementModCalc(offenseElement, defender.data.element)
	
	#Basic Attack will use the user's PhyElement instead of the move's
	#Every other attack uses the move's PhyElement
	if move.name == "Attack":
		phyMod = phy_weakness(user.data.phyElement, defender.data)
		if phyMod > .25:
			feedback = str("[",user.data.phyElement," Weak]", feedback)
		elif phyMod < 0:
			feedback = str("[",user.data.phyElement," Resist]", feedback)
	else:
		phyMod = phy_weakness(move.phyElement, defender.data)
		if phyMod > .25:
			feedback = str("[",move.phyElement," Weak]", feedback)
		elif phyMod < 0:
			feedback = str("[",move.phyElement," Resist]", feedback)
	
	if elementMod >= 1.25:
		feedback = str("[",offenseElement," Weak]", feedback)
	if elementMod <= .75:
		feedback = str("[",offenseElement," Resist]", feedback)
	
	match property:
		"Physical":
			attackStat = user.data.strength
			defenseStat = defender.data.toughness
			if aura == "BodyBreak":
				auraMod = .5
		"Ballistic":
			attackStat = user.data.ballistics
			defenseStat = defender.data.resistance
			if aura == "WillWreck":
				auraMod = .5
	
	if crit_chance(move,user,defender):
		critMod = .25
		feedback = str("[Crit]", feedback)
	
	#Get total attack power, subtract it by total defense then multiply by element mod
	var damage = ((randi_range(0,user.data.level) + move.Power + attackStat) * (1 + user.data.attackBoost + phyMod + critMod))
	damage =  damage - ((1.25 * defenseStat) * (1 + defender.data.defenseBoost))
	damage = int((auraMod)*(elementMod)*(damage))
	
	if damage <= 0:
		damage = 1
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func BOMB(move,defender):
	var phyMod = 0
	feedback = ""
	var elementMod = elementModCalc(move.element, defender.data.element)
	
	phyMod = phy_weakness(move.phyElement, defender.data)
	if phyMod > .25:
		feedback = str("[",move.phyElement," Weak]", feedback)
	elif phyMod < 0:
		feedback = str("[",move.phyElement," Resist]", feedback)
	
	if elementMod >= 1.25:
		feedback = str("[",move.phyElement," Weak]", feedback)
	elif elementMod <= .75:
		feedback = str("[",move.phyElement," Resist]", feedback)
	
	#Bomb attack don't use attack or defense
	var damage = elementMod * (move.Power * (1 + phyMod))
	
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
	var checking = checkAilment(defender.data)
	if checking != "Mental" or checking != "Nonmental":
		canHeal = false
	
	if (checking == move.HealedAilment or defender.data.Ailment == move.HealedAilment 
	or move.HealedAilment == "Negative") and canHeal:
		defender.data.AilmentNum -= move.HealAilAmmount
		feedback = str(feedback," -",move.HealAilAmmount,defender.data.Ailment)
		if defender.data.AilmentNum <= 0:
			defender.data.AilmentNum  = 0

func applyNegativeAilment(move,defender,user,preWin = false):
	#If the ailment calc returns true then apply ailment to defender
	if ailment_calc(move,defender,user) or preWin:
		feedback = str("+",move.AilmentAmmount," ",feedback)
		#Raise number first so Ailment doesn't instantly become Healthy from process
		if defender.AilmentNum <= 3:
			defender.AilmentNum += move.AilmentAmmount
		
		if move.Ailment != defender.Ailment:
			defender.Ailment = move.Ailment

func applyPositiveAilment(move,defender):
	if checkAilment(defender) != "Mental" or  checkAilment(defender) != "Nonmental":
		if move.Ailment == "Protected":
			defender.Ailment = "Protected"
			defender.AilmentNum += 1
		else:
			defender.Ailment = "Overdrive"
			overdriveReady.emit(true)

func applyXSoft(move,defender,user,preWin = false,PreSoft = ""):
	if defender.data.XSoft.size() != 3:
		if ailment_calc(move,defender,user) or preWin:
			if PreSoft != "":
				defender.data.XSoft.append(PreSoft)
			elif move.Ailment == "PhySoft":
				defender.data.XSoft.append(user.data.PhyElement)
			else:
				defender.data.XSoft.append(user.data.TempElement)

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
	defender.Condition |= move.Condition

func buffElementChange(move,defender,user):
	print(defender.data.TempElement)
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
	var ElementModifier: float
	
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
			PhyMod -= .25
	
	return PhyMod

func crit_chance(move,user,defender):
	var crit = false
	var chance = move.BaseCrit + (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck)
	chance = chance - (defender.data.luck * sqrt(defender.data.luck) * (1 + defender.data.luckBoost))
	
	#evil tracia rng lol
	if chance > 100:
		chance = 99
	if chance <= 0:
		chance = 1
	
	if randi() % 100 <= chance:
		crit = true 
	
	return crit

func ailment_calc(move,user,defender):#Ailment chance is like crit chance except it also depends on element matchups
	var ailment = false
	var offenseElement = user.data.element
	
	if move.element != "neutral":
		offenseElement = move.element
	var elementMod = elementMatchup(offenseElement, defender.data.element)
	
	var chance = (move.BaseAilment + (elementMod * (1 + user.luckBoost) * user.luck * sqrt(user.luck))
	- (defender.luck * sqrt(defender.luck) * (1 + defender.luckBoost)))
	
	#Not evil for this
	if chance > 100:
		chance = 100
	if chance <= 0:
		chance = 0
	
	if randi() % 100 <= chance:
		ailment = true 
	
	return ailment

func checkAilment(defender):#Will check if an ailment fits under the boxes: Physical, Mental, Negative and/or Positive
	print("Defender Ailemnt: ",defender.Ailment)
	match defender.Ailment:
		"Healthy":
			return "Healthy"
		"Overdrive":
			return "Overdrive"
		"Protected":
			return "Protected"
		_:
			if (defender.Ailment == "Reckless" or defender.Ailment == "Miserable" or 
			defender.Ailment == "Miserable" or defender.Ailment == "Dumbfounded"):
				return "Mental"
			else:
				return "Nonmental"

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

#-----------------------------------------
#UI CHANGES
#-----------------------------------------
func displayDesc(desc):
	pass

func displayQuick(quick):
	quickInfo.text = quick
	quickInfo.show()
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
	quickInfo.hide()
	quickInfo.text = ""
