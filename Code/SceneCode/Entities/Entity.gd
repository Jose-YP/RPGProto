extends Node2D

@export var data: entityData

@onready var InfoBox: PanelContainer = $BackUI/CurrentInfo
@onready var Info: RichTextLabel = $BackUI/CurrentInfo/RichTextLabel
@onready var selected: TextureRect = $FrontUI/Arrow
@onready var HPBar: TextureProgressBar = $BackUI/HPBar
@onready var HPtext: RichTextLabel = $BackUI/HPBar/RichTextLabel
@onready var currentCondition: RichTextLabel = $FrontUI/ConditionDisplay
@onready var AilmentImages = $BackUI/AilmentDisplay/HBoxContainer/AilmentType.get_children()
@onready var XSoftTabs = $BackUI/XSoftDisplay/HBoxContainer.get_children()
@onready var XSoftSlots: Array = []
@onready var statBoostSprites: Array = [%Attack, %Defense, %Speed, %Luck]
@onready var statBoostSlots: Array = [data.attackBoost, data.defenseBoost, data.speedBoost, data.luckBoost]
@onready var attacks: Array = [data.attackData]
@onready var items: Array = []

signal ailmentSound(type)
signal xsoftSound
signal explode(user)
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

func moreReady() -> void:#Make a function so it'll work on parent and child nodes
	currentHP = data.MaxHP
	HPtext.text = str("HP: ", currentHP)
	data.TempElement = data.element
	items = data.itemData.keys()
	
	for tab in $BackUI/XSoftDisplay/HBoxContainer.get_children():
		XSoftSlots.append(tab.get_children())

func _process(_delta):
	processer()

func processer() -> void:
	if currentHP <= 0:
		currentHP = 0
		HPtext.text = str("HP: ", currentHP)
	
	for k in range(4):
		if Globals.elementGroups[k] == data.TempElement:
			$BackUI/CurrentElement.current_tab = k
	
	if data.XSoft.size() == 0: #If there are none, hide display
		$BackUI/XSoftDisplay.hide()
	
	for i in range(AilmentImages.size()): #If the entity has any Ailments show them
		if data.Ailment == AilmentImages[i].name:
			$BackUI/AilmentDisplay.show()
			$BackUI/AilmentDisplay/HBoxContainer/AilmentType.current_tab = i
			$BackUI/AilmentDisplay/HBoxContainer/AilmentNum.text = str(data.AilmentNum)
		
	if data.AilmentNum <= 0: #Otherwise hide the display
		data.Ailment = "Healthy"
		$BackUI/AilmentDisplay.hide()
	if data.AilmentNum > 3:
		data.AilmentNum = 3
	if data.Ailment == "Overdrive": #Overdrive can only have an Ailment Num of 1
		data.AilmentNum = 1
	
	statBoostSlots = [data.attackBoost, data.defenseBoost, data.speedBoost, data.luckBoost]

#-----------------------------------------
#MOVE PROPERTYS
#-----------------------------------------
func attack(move, receiver, user, property) -> int:
	var attackStat: int
	var defenseStat: int
	var weakRes: float = 0.0
	var lightMod: float = 1
	var softMod: float = 0.0
	var overdriveMod: float = 0.0
	var offenseElement = user.data.TempElement
	var offensePhyEle = move.phyElement
	var currentAura = Globals.currentAura
	var EleMod = Globals.groupEleMod + user.data.soloElementMod + receiver.data.soloElementMod
	var critMod = 0
	var phyMod = 0
	var chargeMod = 1
	var auraMod = 1
	var elementMod
	var sameEle = user.data.sameElement or receiver.data.sameElement
	feedback = ""
	
	#If a move has Neutral Element it will copy the user's element instead
	if move.element == "Neutral":
		weakRes = element_weak_resist(user.data.TempElement, receiver)
		elementMod = elementModCalc(user.data.TempElement, receiver.data.TempElement,EleMod, sameEle)
	else:
		weakRes = element_weak_resist(offenseElement, receiver)
		elementMod = elementModCalc(offenseElement, receiver.data.TempElement,EleMod, sameEle)
	
	if move.element == "Light" and receiver.data.stellar == "Stellar":
		lightMod = 2
	elif move.element == "Light" and receiver.data.stellar == "Hybrid":
		lightMod = 1.5
	
	#Basic Attacks will use the user's PhyElement instead of the move's
	#Every other attack uses the move's PhyElement
	if move.name == "Attack" or move.name == "Crash" or move.name == "Burst":
		offensePhyEle = user.data.phyElement
	
	phyMod = phy_weakness(offensePhyEle, receiver.data)
	if phyMod > .25:
		feedback = str("{",offensePhyEle," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",offensePhyEle," Resist}", feedback)
	
	if elementMod >= 1.25 or weakRes >= .25:
		feedback = str("{",offenseElement," Weak}", feedback)
	if elementMod <= .75 or weakRes <= -.5:
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
	
	var totalFirstMod: float = 1 + user.data.attackBoost + phyMod + softMod + critMod + overdriveMod + weakRes
	totalFirstMod = clamp(totalFirstMod, .001, 6)
	var totalSecondMod: float = chargeMod*auraMod*elementMod*lightMod
	#Get total attack power, subtract it by total defense then multiply by element mod*AuraMod
	var damage = ((randi_range(0,user.data.level) + move.Power + attackStat) * totalFirstMod)
	damage =  damage - ((1.25 * defenseStat) * (1 + receiver.data.defenseBoost))
	damage = int(totalSecondMod * (damage))
	
	damage = clamp(damage, 1, 1000)
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func BOMB(move,receiver, user) -> int:
	feedback = ""
	var sameEle = user.data.sameElement or receiver.data.sameElement
	var lightMod: float = 1.0
	var softMod: float = 0.0
	var weakRes: float = element_weak_resist(move.element, receiver)
	var prev: float = softMod
	var phyMod: float = phy_weakness(move.phyElement, receiver.data)
	var EleMod: float = Globals.groupEleMod + user.data.soloElementMod + receiver.data.soloElementMod
	var elementMod: float = elementModCalc(move.element, receiver.data.TempElement, EleMod, sameEle)
	var attackStat: int = 0
	
	if phyMod > .25:
		feedback = str("{",move.phyElement," Weak}", feedback)
	elif phyMod < 0:
		feedback = str("{",move.phyElement," Resist}", feedback)
	
	if elementMod >= 1.25:
		feedback = str("{",move.element," Weak}", feedback)
	elif elementMod <= .75:
		feedback = str("{",move.element," Resist}", feedback)
	
	if move.element == "Light" and receiver.data.stellar == "Stellar":
		lightMod = 2
	elif move.element == "Light" and receiver.data.stellar == "Hybrid":
		lightMod = 1.5
	
	softMod += checkXSoft(move.element, receiver)
	if prev < softMod:
		feedback = str("{",move.element," Soft}", feedback)
	prev = softMod
	softMod += checkXSoft(move.phyElement, receiver)
	if prev < softMod:
		feedback = str("{",move.phyElement," Soft}", feedback)
	
	if user.data.ItemChange & 1:
		attackStat += int(user.data.strength * .75)
	if user.data.ItemChange & 2:
		attackStat += int(user.data.ballistics * .75)
	
	#Bomb attack don't use attack or defense
	var firstMod = clamp(1 + phyMod + softMod + weakRes, .01, 6)
	var damage = lightMod * elementMod * ((move.Power + attackStat) * firstMod)
	
	feedback = str(damage, " BOMB Damage!", feedback)
	return damage

func healHP(move,receiver) -> int:
	var healAmmount = move.healing
	if move.percentage:
		healAmmount = int((float(move.healing)/100) * float(receiver.data.MaxHP))
	
	feedback = str(healAmmount," HP Healed!")
	
	return healAmmount

func healAilment(move, receiver) -> void:
	var canHeal = true
	if move.HealedAilment == "All":
		receiver.data.AilmentNum -= move.HealAilAmmount
		receiver.data.XSoft.resize(3-move.HealAilAmmount)
		canHeal = false
		receiver.XSoftDisplay()
		
	
	var category = ailmentCategory(receiver)
	if category != "Mental" and category != "Chemical":
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

func healKO(receiver) -> void:
	receiver.data.KO = false

func applyNegativeAilment(move,receiver,user,preWin = false, override = "") -> void:
	var ailment = move.Ailment
	var ailmentNum = move.AilmentAmmount
	if move.BaseAilment > 200:
		preWin = true
	if override != "":
		ailment = override
		ailmentNum = 1
	
	#If the ailment calc returns true then apply ailment to receiver
	if preWin or ailment_calc(move,receiver,user):
		#Raise number first so Ailment doesn't instantly become Healthy from process
		ailmentSound.emit(ailment)
		
		if receiver.data.AilmentNum < 3:
			receiver.data.AilmentNum += ailmentNum
		
		if ailment != receiver.data.Ailment:
			receiver.data.Ailment = ailment

func applyPositiveAilment(move,receiver) -> void:
	if ailmentCategory(receiver) != "Mental" or  ailmentCategory(receiver) != "Chemical":
		ailmentSound.emit(move.Ailment)
		if move.Ailment == "Protected":
			receiver.data.AilmentNum += 1
			receiver.data.Ailment = "Protected"
		else:
			receiver.data.AilmentNum += 1
			receiver.data.Ailment = "Overdrive"

func applyXSoft(move,receiver,user,preWin = false,PreSoft = "") -> void:
	var win = preWin
	var times = move.AilmentAmmount
	var ele
	
	if preWin or move.BaseAilment >= 200:
		win = true
	
	if not win:
		win = ailment_calc(move,receiver,user)
	
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
	
	receiver.XSoftDisplay()
	xsoftSound.emit()

func buffStat(receiver,boostType,boostAmmount = 1) -> void:#For actively buffing and debuffing moves
	if boostType & 1:
		receiver.data.attackBoost += (boostAmmount * .3)
		print("AAA")
		buffStatManager(receiver.get_node("FrontUI/Buffs/Attack"),receiver.data.attackBoost)
	if boostType & 2:
		receiver.data.defenseBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("FrontUI/Buffs/Defense"),receiver.data.defenseBoost)
	if boostType & 4:
		receiver.data.speedBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("FrontUI/Buffs/Speed"),receiver.data.speedBoost)
	if boostType & 8:
		receiver.data.luckBoost += (boostAmmount * .3)
		buffStatManager(receiver.get_node("FrontUI/Buffs/Luck"),receiver.data.luckBoost)

func buffCondition(move,receiver) -> void:
	receiver.data.Condition |= move.Condition
	receiver.buffConditionDisplay()
	if checkCondition("Targetted", receiver):#Targetted will last until 
		targetCount = 2

func buffElementChange(move,receiver,user) -> void:
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

func drain(damage, ammount) -> int:
	var healAmmount = int(damage * ammount)
	return healAmmount

#-----------------------------------------
#MOVE HELPERS
#-----------------------------------------
func elementModCalc(userElement,receiverElement,PreMod,sameEle) -> float:
	var ElementModifier: float = 1
	var sameEleMod: float = 1
	
	if sameEle:
		sameEle = .75 - PreMod
	
	match userElement:
		"Fire":
			match receiverElement:
				"Water":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
				"Fire":
					ElementModifier = sameEleMod
		"Water":
			match receiverElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = .75 - PreMod
				"Water":
					ElementModifier = sameEleMod
		"Elec":
			match receiverElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Water":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = sameEleMod
		"Light":
			match receiverElement:
				"Fire":
					ElementModifier = .75 - PreMod
				"Elec":
					ElementModifier = 1.25 + PreMod
		"Comet":
			match receiverElement:
				"Fire":
					ElementModifier = 1.25 + PreMod
				"Water":
					ElementModifier = .75 - PreMod
		"Aurora":
			match receiverElement:
				"Water":
					ElementModifier = 1.25 + PreMod
				"Elec":
					ElementModifier = .75 - PreMod
		"Aether":
			ElementModifier = 1.25 + PreMod
	
	#So negative values don't make negative damage
	return clamp(ElementModifier, .01, 6)

func elementMatchup(matchup,targetElement) -> String:
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

func element_weak_resist(userElement,reciever) -> float:
	var weakResMod: float = 0.0
	var userFlag = HelperFunctions.String_to_Flag(userElement, "Element")
	
	for i in range(10):
		var flag = 1 << i
		if userFlag & flag or flag & 512: #512 is for All Resist
			if flag & reciever.data.Weakness:
				weakResMod += .1
			if flag & reciever.data.Resist:
				weakResMod -= .25
	
	return weakResMod

func phy_weakness(user,receiver,PreMod = 0) -> float:
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
	for i in range(10):
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

func crit_chance(move,user,receiver,currentAura) -> bool:
	var crit = false
	var auraMod = 1
	if currentAura == "CritDouble":
		auraMod = 2
	
	var chance = move.BaseCrit + (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck)
	chance = chance - (receiver.data.luck * sqrt(receiver.data.luck) * (1 + receiver.data.luckBoost))
	chance *= auraMod
	
	#evil tracia rng lol
	chance = clamp(chance, 1, 99)
	if randi() % 100 <= chance:
		crit = true
		critical.emit()
		if move.Ailment != "None":
			applyNegativeAilment(move,receiver,user,true)
		elif user.data.miscCalc == "DumbfoundedCrit":
			applyNegativeAilment(move,receiver,user,true,"Dumbfounded")
		else:
			applyXSoft(move,receiver,user,true,determineXSoft(move,user))
	
	return crit

func ailment_calc(move,user,receiver) -> bool:#Ailment chance is like crit chance except it also depends on element matchups
	var sameEle: bool = user.data.sameElement or receiver.data.sameElement
	var ailment: bool = false
	var EleMod: float = Globals.groupEleMod + user.data.soloElementMod + receiver.data.soloElementMod
	var offenseElement = user.data.element
	
	if move.element != "Neutral":
		offenseElement = move.element
	var elementMod = elementModCalc(offenseElement, receiver.data.element, EleMod, sameEle)
	
	var chance = (move.BaseAilment + (elementMod * (1 + user.data.luckBoost) * user.data.luck * sqrt(user.data.luck))
	- (receiver.data.luck * sqrt(receiver.data.luck) * (1 + receiver.data.luckBoost)))
	
	#Not evil for this
	chance = clamp(chance, 0, 100)
	if randi() % 100 <= chance:
		ailment = true
	
	return ailment

func ailmentCategory(receiver) -> String:#Will check if an ailment fits under the boxes: Physical, Mental, Negative and/or Positive
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
				return "Chemical"

func determineXSoft(move,user) -> String:
	if move.name == "Attack" or move.name == "Burst": #XSoft
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
				return user.data.phyElement

func checkXSoft(seeking,receiver) -> float:
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
func checkCondition(seeking,receiver) -> bool:
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

func removeCondition(seeking,receiver) -> void:
	var seekingFlag = HelperFunctions.String_to_Flag(seeking,"Condition")
	#Search every possible flag in condition
	#Make sure to check if the receiver even has a weakness/resistance
	for i in range(10):
		#Flag is the binary version of i
		var flag = 1 << i
		if receiver.data.Condition != null and receiver.data.Condition & flag != 0 and receiver.data.Condition & seekingFlag != 0:
			receiver.data.Condition = receiver.data.Condition & ~seekingFlag
			receiver.currentCondition.text = HelperFunctions.Flag_to_String(receiver.data.Condition, "Condition")

func statBoostHandling() -> void:
	for boost in range(statBoostSlots.size()):
		if statBoostSlots[boost] > 0:
			statBoostSlots[boost] -= .05
			buffStatManager(statBoostSprites[boost],statBoostSlots[boost])
		
		elif statBoostSlots[boost] < 0:
			statBoostSlots[boost] += .05
			buffStatManager(statBoostSprites[boost],statBoostSlots[boost])
		
		if statBoostSlots[boost] == 0:
			statBoostSprites[boost].hide()

func midTurnAilments(Ailment) -> bool:
	var stillAttack = true
	match Ailment:
		"Reckless":
			var chance = 25
			var damage = 0
			if data.AilmentNum >= 2:
				chance *= 2
			
			if randi() % 100 <= chance:
				damage = attack(data.attackData, self, self, "Physical")
				tweenDamage(self, .6, str("Couldn't attack, took ",damage," Self-inflicted Damage"))
				stillAttack = false
			elif data.AilmentNum == 3:
				damage = attack(data.attackData, self, self, "Physical")
				tweenDamage(self, .6, str("Took ",damage," Self-inflicted Damage"))
				
			feedback = ""
		"Stun":
			stillAttack = false
			data.AilmentNum -= 1
			displayQuick("Stunned")
	
	return stillAttack

func reactionaryAilments(Ailment) -> void:
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
	
	if data.miscCalc == "Explode" and randi_range(0,100) < 5:
		explode.emit()

func endPhaseAilments(Ailment) -> void:
	match Ailment:
		"Poison":
			var damage = int(data.MaxHP * data.AilmentNum * .066)
			currentHP -= damage
			
			tweenDamage(self, .4, str("Took ",damage," Poison Damage"))

#-----------------------------------------
#UI CHANGES
#-----------------------------------------
func hideDesc() -> void:
	InfoBox.hide()
	Info.clear()

func displayQuick(quick) -> void:
	Info.text = quick
	InfoBox.show()
	$Timer.start()

func tweenDamage(targetting,tweenTiming,infomation) -> void:
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

func buffStatManager(type,ammount) -> void:#Called whenever a buffed stat is changed
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

func buffConditionDisplay() -> void:
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

func XSoftDisplay() -> void:
	for soft in range(data.XSoft.size()): #Show any XSofts that are on the entity
		var oneTrue = false
		for i in range(6):
			if data.XSoft[soft] == XSoftSlots[soft][i].name:
				$BackUI/XSoftDisplay.show()
				XSoftTabs[soft].current_tab = i
				XSoftTabs[soft].show()
				oneTrue = true
		
		if not oneTrue:
			XSoftTabs[soft].hide()

func reset() -> void:
	for boost in range(statBoostSlots.size()): #Reset Stat boosts to 0
		statBoostSlots[boost] = 0
		buffStatManager(statBoostSprites[boost],statBoostSlots[boost])
	
	for i in range(10): #Reset conditions to nothing
		var flag = 1 << i
		if data.Condition != null and data.Condition & flag != 0:
			data.Condition = data.Condition & ~flag
			currentCondition.text = HelperFunctions.Flag_to_String(data.Condition, "Condition")
	
	data.Ailment = "Healthy" #Reset Ailment
	data.AilmentNum = 0
	targetCount = 0 #Reset target count

func _on_timer_timeout() -> void:
	hideDesc()
