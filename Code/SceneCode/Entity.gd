extends Node2D

@export var data: entityData

@onready var InfoBox: PanelContainer = $CurrentInfo
@onready var Info: RichTextLabel = $CurrentInfo/RichTextLabel
@onready var selected: Sprite2D = $Arrow
@onready var HPBar: TextureProgressBar = $HPBar
@onready var HPtext: RichTextLabel = $HPBar/RichTextLabel
@onready var currentCondition: RichTextLabel = $ConditionDisplay
@onready var AilmentImages = $AilmentDisplay/HBoxContainer/AilmentType.get_children()
@onready var XSoftTabs = $XSoftDisplay/HBoxContainer.get_children()
@onready var XSoftSlots: Array = []
@onready var statBoostSprites: Array = [$Buffs/Attack,$Buffs/Defense,$Buffs/Speed,$Buffs/Luck]
@onready var statBoostSlots: Array = [data.attackBoost, data.defenseBoost, data.speedBoost, data.luckBoost]
@onready var attacks: Array = [data.attackData]
@onready var items: Array = []

signal ailmentSound(type)
signal critical

var currentHP: int = 0
var targetCount: int = 0
var chargeUsed: bool = false
var ampUsed: bool = false
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
	
	if data.XSoft.size() == 0: #If there are none, hide display
		$XSoftDisplay.hide()
	
	for i in range(AilmentImages.size()): #If the entity has any Ailments show them
		if data.Ailment == AilmentImages[i].name:
			$AilmentDisplay.show()
			$AilmentDisplay/HBoxContainer/AilmentType.current_tab = i
			$AilmentDisplay/HBoxContainer/AilmentNum.text = str(data.AilmentNum)
		
	if data.AilmentNum <= 0: #Otherwise hide the display
		data.Ailment = "Healthy"
		$AilmentDisplay.hide()
	if data.AilmentNum > 3:
		data.AilmentNum = 3
	if data.Ailment == "Overdrive": #Overdrive can only have an Ailment Num of 1
		data.AilmentNum = 1
	
	statBoostSlots = [data.attackBoost, data.defenseBoost, data.speedBoost, data.luckBoost]

#-----------------------------------------
#MOVE PROPERTYS
#-----------------------------------------
func attack(move, receiver, user, property, currentAura):
	var attackStat: int
	var defenseStat: int
	var softMod: float = 0.0
	var overdriveMod: float = 0.0
	var offenseElement = user.data.TempElement
	var offensePhyEle = move.phyElement
	var critMod = 0
	var phyMod = 0
	var chargeMod = 1
	var auraMod = 1
	feedback = ""
	
	#If a move has Neutral Element it will copy the user's element instead
	if move.element == "Neutral":
		offenseElement = user.data.element
	var elementMod = elementModCalc(offenseElement, receiver.data.element)
	
	#Basic Attacks will use the user's PhyElement instead of the move's
	#Every other attack uses the move's PhyElement
	if move.name == "Attack" or move.name == "Crash" or move.name == "Burst":
		offensePhyEle = user.data.phyElement
	
	phyMod = phy_weakness(offensePhyEle, receiver.data)
	if phyMod > .25:
		feedback = str("{",offensePhyEle," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",offensePhyEle," Resist}", feedback)
	
	if elementMod >= 1.25:
		feedback = str("{",offenseElement," Weak}", feedback)
	if elementMod <= .75:
		feedback = str("{",offenseElement," Resist}", feedback)
	
	var prev = softMod
	softMod += checkXSoft(offenseElement, receiver)
	if prev < softMod:
		feedback = str("{",offenseElement," Soft}", feedback)
	prev = softMod
	softMod += checkXSoft(offensePhyEle, receiver)
	if prev < softMod:
		feedback = str("{",offensePhyEle," Soft}", feedback)
	
	match property:
		"Physical":
			attackStat = user.data.strength
			defenseStat = receiver.data.toughness
			if currentAura == "BodyBroken":
				feedback = str("{",currentAura,"}",feedback)
				auraMod = .5
			if checkCondition("Charge",user):
				feedback = str("{Charged}",feedback)
				chargeMod = 2.5
				chargeUsed = true
		"Ballistic":
			attackStat = user.data.ballistics
			defenseStat = receiver.data.resistance
			if currentAura == "WillWrecked":
				feedback = str("{",currentAura,"}",feedback)
				auraMod = .5
			if checkCondition("Amp",user):
				feedback = str("{Amped}",feedback)
				chargeMod = 2.5
				ampUsed = true
	
	if crit_chance(move,user,receiver,currentAura):
		critMod = .25
		feedback = str("{Crit}", feedback)
	
	if user.data.Ailment == "Overdrive":
		overdriveMod = .25
	
	var totalFirstMod = 1 + user.data.attackBoost + phyMod + softMod + critMod + overdriveMod
	var totalSecondMod = chargeMod*auraMod*elementMod
	#Get total attack power, subtract it by total defense then multiply by element mod*AuraMod
	var damage = ((randi_range(0,user.data.level) + move.Power + attackStat) * totalFirstMod)
	damage =  damage - ((1.25 * defenseStat) * (1 + receiver.data.defenseBoost))
	damage = int(totalSecondMod*(damage))
	
	if damage <= 0:
		damage = 1
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func BOMB(move,receiver):
	feedback = ""
	var softMod: float = 0
	var prev = softMod
	var phyMod: float = 0
	var elementMod = elementModCalc(move.element, receiver.data.element)
	
	phyMod = phy_weakness(move.phyElement, receiver.data)
	if phyMod > .25:
		feedback = str("{",move.phyElement," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",move.phyElement," Resist}", feedback)
	
	if elementMod >= 1.25:
		feedback = str("{",move.element," Weak}", feedback)
	elif elementMod <= .75:
		feedback = str("{",move.element," Resist}", feedback)
	
	softMod += checkXSoft(move.element, receiver)
	if prev < softMod:
		feedback = str("{",move.element," Soft}", feedback)
	prev = softMod
	softMod += checkXSoft(move.phyElement, receiver)
	if prev < softMod:
		feedback = str("{",move.phyElement," Soft}", feedback)
	
	#Bomb attack don't use attack or defense
	var damage = elementMod * (move.Power * (1 + phyMod + softMod))
	
	feedback = str(damage, " BOMB Damage!", feedback)
	return damage

func healHP(move,receiver):
	var healAmmount = move.healing
	if move.percentage:
		healAmmount = int((float(move.healing)/100) * float(receiver.data.MaxHP))
	
	feedback = str(healAmmount," HP Healed!")
	
	return healAmmount

func healAilment(move, receiver):
	var canHeal = true
	if move.HealedAilment == "All":
		receiver.data.AilmentNum -= move.HealAilAmmount
		receiver.data.XSoft.resize(3-move.HealAilAmmount)
		canHeal = false
		receiver.XSoftDisplay()
		
	
	var category = ailmentCategory(receiver)
	if category != "Mental" and category != "Nonmental":
		canHeal = false
	
	if (category == move.HealedAilment or receiver.data.Ailment == move.HealedAilment 
	or move.HealedAilment == "Negative") and canHeal:
		receiver.data.AilmentNum -= move.HealAilAmmount
		canHeal = false
		
		if receiver.data.AilmentNum <= 0:
			receiver.data.AilmentNum  = 0
		
	if (move.HealedAilment == "XSoft" or move.HealedAilment == "Negative") and canHeal:
		for i in range(move.HealAilAmmount):
			receiver.data.XSoft.pop_front()
		
		receiver.XSoftDisplay()

func healKO(receiver):
	receiver.data.KO = false

func applyNegativeAilment(move,receiver,user,preWin = false):
	if move.BaseAilment > 200:
		preWin = true
	
	#If the ailment calc returns true then apply ailment to receiver
	if ailment_calc(move,receiver,user) or preWin:
		#Raise number first so Ailment doesn't instantly become Healthy from process
		ailmentSound.emit(move.Ailment)
		
		if receiver.data.AilmentNum < 3:
			receiver.data.AilmentNum += move.AilmentAmmount
		
		if move.Ailment != receiver.data.Ailment:
			receiver.data.Ailment = move.Ailment

func applyPositiveAilment(move,receiver):
	if ailmentCategory(receiver) != "Mental" or  ailmentCategory(receiver) != "Nonmental":
		ailmentSound.emit(move.Ailment)
		if move.Ailment == "Protected":
			receiver.data.AilmentNum += 1
			receiver.data.Ailment = "Protected"
		else:
			receiver.data.AilmentNum += 1
			receiver.data.Ailment = "Overdrive"

func applyXSoft(move,receiver,user,preWin = false,PreSoft = ""):
	var win = preWin
	var times = move.AilmentAmmount
	var ele
	
	if preWin or move.BaseAilment >= 200:
		win = true
	
	if not win:
		win = ailment_calc(move,receiver,user)
	
	print(HelperFunctions.emptyXSoftSlots(receiver.data.XSoft) != 0 or data.XSoft.size() < 3)
	if HelperFunctions.emptyXSoftSlots(receiver.data.XSoft) != 0:
		if win:
			if PreSoft != "":
				ele = PreSoft
			elif move.Ailment == "PhySoft":
				ele = move.phyElement
			else:
				ele = determineXSoft(move,user)
	
	for i in range(times):
		receiver.data.XSoft = HelperFunctions.NullorAppend(receiver.data.XSoft,ele)
		print(receiver.data.XSoft)
	
	receiver.XSoftDisplay()

func buffStat(receiver,boostType,boostAmmount = 1):#For actively buffing and debuffing moves
	if boostType & 1:
		receiver.data.attackBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("Buffs/Attack"),receiver.data.attackBoost)
	if boostType & 2:
		receiver.data.defenseBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("Buffs/Defense"),receiver.data.defenseBoost)
	if boostType & 4:
		receiver.data.speedBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("Buffs/Speed"),receiver.data.speedBoost)
	if boostType & 8:
		receiver.data.luckBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("Buffs/Luck"),receiver.data.luckBoost)

func buffCondition(move,receiver):
	receiver.data.Condition |= move.Condition
	receiver.buffConditionDisplay()
	if checkCondition("Targetted", receiver):#Targetted will last until 
		targetCount = 2

func buffElementChange(move,receiver,user):
	var prev = receiver.data.TempElement
	match move.ElementChange:
		"TWin":
			receiver.data.TempElement = elementMatchup(true,receiver.data.TempElement)
		"TLose":
			receiver.data.TempElement = elementMatchup(false,receiver.data.TempElement)
		"UWin":
			receiver.data.TempElement = elementMatchup(true,user.data.TempElement)
		"ULose":
			receiver.data.TempElement = elementMatchup(false,user.data.TempElement)
		_:
			receiver.data.TempElement = move.ElementChange
	
	if prev == str(receiver.data.TempElement):
		feedback = str("Element unchanged")
	else:
		feedback = str(prev," changed to ",receiver.data.TempElement)

#-----------------------------------------
#MOVE HELPERS
#-----------------------------------------
func elementModCalc(userElement,receiverElement,PreMod = 0):
	var ElementModifier: float = 1
	
	match userElement:
		"Fire":
			match receiverElement:
				"Water":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Water":
			match receiverElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = .75 - PreMod
				_:
					ElementModifier = 1
		"Elec":
			match receiverElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Water":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Light":
			match receiverElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
				_:
					ElementModifier = 1
		"Comet":
			match receiverElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Water":
					ElementModifier = .75 - PreMod
				_:
					ElementModifier = 1
		"Aurora":
			match receiverElement:
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

func phy_weakness(user,receiver,PreMod = 0):
	var PhyMod = 0
	
	if user == "Neutral":
		return 0
	
	if receiver.Weakness & 64 != 0:
		PhyMod += .25 + PreMod
		return PhyMod
	
	if receiver.Resist & 64 != 0:
		PhyMod -= .25 + PreMod
		return PhyMod
	
	var userFlag = HelperFunctions.String_to_Flag(user,"Element")
	
	#Search every possible flag in Weakness and resist
	#Make sure to check if the receiver even has a weakness/resistance
	for i in range(6):
		#Flag is the binary version of i
		var flag = 1 << i
		#Check if it has a weakness if it does don't check resistance
		if receiver.Weakness != null and receiver.Weakness & flag != 0 and userFlag & flag != 0:
			PhyMod += .25  + PreMod
			continue
		
		#Check if it has a resistance otherwise
		if receiver.Resist != null and receiver.Resist & flag != 0 and userFlag & flag != 0:
			PhyMod -= .25
	
	return PhyMod

func crit_chance(move,user,receiver,currentAura):
	var crit = false
	var auraMod = 1
	if currentAura == "CritDouble":
		auraMod = 2
	
	var chance = move.BaseCrit + (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck)
	chance = chance - (receiver.data.luck * sqrt(receiver.data.luck) * (1 + receiver.data.luckBoost))
	chance *= auraMod
	
	#evil tracia rng lol
	if chance > 100:
		chance = 99
	if chance <= 0:
		chance = 1
	
	if randi() % 100 <= chance:
		crit = true
		critical.emit()
		if move.Ailment != "None":
			applyNegativeAilment(move,receiver,user,true)
		else:
			applyXSoft(move,receiver,user,true,determineXSoft(move,user))
	
	return crit

func ailment_calc(move,user,receiver):#Ailment chance is like crit chance except it also depends on element matchups
	var ailment = false
	var offenseElement = user.data.element
	
	if move.element != "neutral":
		offenseElement = move.element
	var elementMod = elementModCalc(offenseElement, receiver.data.element)
	
	var chance = (move.BaseAilment + (elementMod * (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck))
	- (receiver.data.luck * sqrt(receiver.data.luck) * (1 + receiver.data.luckBoost)))
	
	#Not evil for this
	if chance > 100:
		chance = 100
	if chance <= 0:
		chance = 0
	
	if randi() % 100 <= chance:
		ailment = true
	
	return ailment

func ailmentCategory(receiver):#Will check if an ailment fits under the boxes: Physical, Mental, Negative and/or Positive
	match receiver.data.Ailment:
		"Healthy":
			return "Healthy"
		"Overdrive":
			return "Overdrive"
		"Protected":
			return "Protected"
		_:
			if (receiver.data.Ailment == "Reckless" or receiver.data.Ailment == "Miserable" or 
			receiver.data.Ailment == "Miserable" or receiver.data.Ailment == "Dumbfounded"):
				return "Mental"
			else:
				return "Nonmental"

func determineXSoft(move,user):
	if move.name == "Attack" or move.name == "Burst": #XSoft
		print(user.data.phyElement)
		return user.data.phyElement
	
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
				print(user.data.phyElement)
				return user.data.phyElement

func checkCondition(seeking,receiver):
	var seekingFlag = HelperFunctions.String_to_Flag(seeking,"Condition")
	var found = false
	#Search every possible flag in condition
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i#If it says seekingFlag is a bool, that means it couldn't find a value in String to Flag
		if receiver.data.Condition != null and receiver.data.Condition & flag != 0 and receiver.data.Condition & seekingFlag != 0:
			found = true
			break
	return found

func checkXSoft(seeking,receiver):
	var softAmmount: float = 0.0
	var k: int = 0
	if seeking == "Neutral":
		return 0
	
	for element in receiver.data.XSoft:
		k += 1
		if seeking == element:
			softAmmount += .15
			break
	
	while k != (receiver.data.XSoft.size()):
		if seeking == receiver.data.XSoft[k]:
			softAmmount += .1
		k += 1
	
	return softAmmount

#-----------------------------------------
#STATUS CONDITION HANDLDLING
#-----------------------------------------
func removeCondition(seeking,receiver):
	var seekingFlag = HelperFunctions.String_to_Flag(seeking,"Condition")
	#Search every possible flag in condition
	#Make sure to check if the receiver even has a weakness/resistance
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i
		if receiver.data.Condition != null and receiver.data.Condition & flag != 0 and receiver.data.Condition & seekingFlag != 0:
			receiver.data.Condition = receiver.data.Condition & ~seekingFlag
			receiver.currentCondition.text = HelperFunctions.Flag_to_String(receiver.data.Condition, "Condition")

func statBoostHandling():
	for boost in range(statBoostSlots.size()):
		if statBoostSlots[boost] > 0:
			statBoostSlots[boost] -= .05
			buffStatManager(statBoostSprites[boost],statBoostSlots[boost])
		
		elif statBoostSlots[boost] < 0:
			statBoostSlots[boost] += .05
			buffStatManager(statBoostSprites[boost],statBoostSlots[boost])
		
		if statBoostSlots[boost] == 0:
			statBoostSprites[boost].hide()

func midTurnAilments(Ailment, currentAura):
	var stillAttack = true
	match Ailment:
		"Reckless":
			var chance = 25
			var damage = 0
			if data.AilmentNum >= 2:
				chance *= 2
			
			if randi() % 100 <= chance:
				damage = attack(data.attackData, self, self, "Physical", currentAura)
				tweenDamage(self, .6, str("Couldn't attack, took ",damage," Self-inflicted Damage"))
				stillAttack = false
			elif data.AilmentNum == 3:
				damage = attack(data.attackData, self, self, "Physical", currentAura)
				tweenDamage(self, .6, str("Took ",damage," Self-inflicted Damage"))
				
			feedback = ""
		"Stun":
			stillAttack = false
			data.AilmentNum -= 1
			displayQuick("Stunned")
	
	return stillAttack

func reactionaryAilments(Ailment):
	match Ailment:
		"Rust":
			if data.AilmentNum >= 1:
				data.defenseBoost -= .2
				if data.AilmentNum >= 2:
					data.attackBoost -= .2
					if data.AilmentNum == 3:
						data.speedBoost -= .2
			statBoostHandling()
		"Miserable":
			pass

func endPhaseAilments(Ailment):
	match Ailment:
		"Poison":
			var damage = int(data.MaxHP * data.AilmentNum * .066)
			currentHP -= damage
			
			tweenDamage(self, .4, str("Took ",damage," Poison Damage"))

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

func tweenDamage(targetting,tweenTiming,infomation):
	var tween = targetting.HPBar.create_tween()
	var prevValue = HPBar.value
	targetting.displayQuick(infomation)
	
	if checkCondition("Endure",targetting):
		targetting.currentHP = 1
		removeCondition("Endure",targetting)
	
	targetting.HPtext.text = str("HP: ",targetting.currentHP)
	await tween.tween_property(targetting.HPBar, "value",
	int(100 * float(targetting.currentHP) / float(targetting.data.MaxHP)),tweenTiming).set_trans(4).set_ease(1)
	
	if prevValue > HPBar.value: #only do this if the entity has taken damage
		targetting.reactionaryAilments(targetting.data.Ailment)
	
	infomation = ""

func buffStatManager(type,ammount):#Called whenever a buffed stat is changed
	var label = type.get_child(0)
	if ammount > .6:
		ammount = .6
	
	var textStore = str(100 * ammount,"%")
	if int(ammount) == 0:
		type.hide()
	
	if ammount != 0:
		label.text = textStore
		type.show()
	
	if ammount > 0:
		type.modulate = Color(1, 0.278, 0.357, 0.671)
		
	elif ammount < 0:
		type.modulate = Color(0.58, 0.592, 0.541, 0.671)

func buffConditionDisplay():
	var conditionString: String = ""
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i
		if data.Condition != null and data.Condition & flag != 0:
			if conditionString != "":
				conditionString = str(HelperFunctions.Flag_to_String(flag,"Condition"),"\n",conditionString)
			else:
				conditionString = str(HelperFunctions.Flag_to_String(flag,"Condition"))
	
	currentCondition.text = conditionString

func XSoftDisplay():
	for soft in range(data.XSoft.size()): #Show any XSofts that are on the entity
		var oneTrue = false
		for i in range(6):
			if data.XSoft[soft] == XSoftSlots[soft][i].name:
				print(data.XSoft)
				print("Found XSoft",data.XSoft[soft],"=",XSoftSlots[soft][i].name,"Tab:",i)
				$XSoftDisplay.show()
				XSoftTabs[soft].current_tab = i
				XSoftTabs[soft].show()
				oneTrue = true
		
		if not oneTrue:
			print(XSoftTabs[soft],"||",oneTrue)
			XSoftTabs[soft].hide()

func _on_timer_timeout():
	hideDesc()
