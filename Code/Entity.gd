extends Node2D

@export var data: entityData

@onready var info: TextEdit = $TextEdit
@onready var quickInfo: TextEdit = $CurrentInfo
@onready var selected: Sprite2D = $Arrow
@onready var HPBar: TextureProgressBar = $HPBar
@onready var HPtext: RichTextLabel = $HPBar/RichTextLabel
@onready var basicAttack = data.attackData
@onready var attacks: Array = [basicAttack]

var currentHP: int
var feedback: String
#Determines which targetting system to use
enum target {SINGLE,
	GROUP,
	RANDOM,
	SELF,
	ALL,
	NONE}

#-----------------------------------------
#INITIALIZATION & PROCESSING
#-----------------------------------------
#Make a function so it'll work on parent and child nodes
func _ready():
	moreReady()

func moreReady():
	currentHP = data.MaxHP
	HPtext.text = str("HP: ", currentHP)
	attacks.append(data.attackData)
	
	#debug code
	if data == null:
		print("entityData file not set")

#--------------------------------
#MOVE PROPERTYS
#-----------------------------------------
func attack(move, defender, user, property):
	var attackStat: int
	var defenseStat: int
	var offenseElement = user.data.element
	var critMod = 0
	var phyMod = 0
	feedback = ""
	
	#If a move has Neutral Element it will copy the user's element instead
	if move.element == "neutral":
		offenseElement = user.data.element
	var elementMod = element_matchup(offenseElement, defender.data.element)
	
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
		"Ballistic":
			attackStat = user.data.ballistics
			defenseStat = defender.data.resistance
	
	if crit_chance(move,user,defender):
		critMod = .25
		feedback = str("[Crit]", feedback)
	
	#Get total attack power, subtract it by total defense then multiply by element mod
	var damage = ((move.Power + attackStat) * (1 + user.data.attackBoost + phyMod + critMod))
	damage =  damage - ((1.25 * defenseStat) * (1 + defender.data.defsenseBoost))
	damage = int((elementMod)*(damage))
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func BOMB(move,defender):
	var phyMod = 0
	feedback = ""
	var elementMod = element_matchup(move.element, defender.data.element)
	
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
	
	feedback = str(damage, " Damage!", feedback)
	return damage

func healHP(move,defender):
	var healAmmount = move.healing
	if move.percentage:
		healAmmount = int((float(move.healing)/100) * float(defender.data.MaxHP))
	
	return healAmmount

func healAilment():
	
	pass

func applyNegativeAilment(move,defender,user):
	#If the ailment calc returns true then apply ailment to defender
	if ailment_calc(move,defender,user):
		#Raise number first so Ailment doesn't instantly become Healthy from process
		if defender.AilmentNum <= 3:
			defender.AilmentNum += 1
		
		if move.Ailment != defender.Ailment:
			defender.Ailment = move.Ailment

func applyPositiveAilment(move,defender):
	
	if move.Ailment != defender.Ailment:
		pass

func buffStat(move,defender):#For actively buffing and debuffing moves
	if move.boostType & 1:
		defender.attackBoost += (move.boostAmmount * .3)
		buffStatManager($Buffs/Attack,defender.attackBoost)
	if move.boostType & 2:
		defender.defenseBoost += (move.boostAmmount * .3)
		buffStatManager($Buffs/Defense,defender.defenseBoost)
	if move.boostType & 4:
		defender.speedBoost += (move.boostAmmount * .3)
		buffStatManager($Buffs/Speed,defender.speedBoost)
	if move.boostType & 8:
		defender.luckBoost += (move.boostAmmount * .3)
		buffStatManager($Buffs/Luck,defender.luckBoost)

func buffCondition(move,defender):
	defender.Condition |= move.Condition

#-----------------------------------------
#MOVE HELPERS
#-----------------------------------------
func element_matchup(userElement,defenderElement,PreMod = 0):
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
	var elementMod = element_matchup(offenseElement, defender.data.element)
	
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

#func checkAilment(defender):#Will check if an ailment fits under the boxes: Physical, Mental, Negative and/or Positive
#	pass

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
func displayQuick(quick):
	quickInfo.text = quick
	quickInfo.show()
	$Timer.start()

func buffStatManager(type,ammount):#Called whenever a buffed stat is changed
	var label = type.get_child("RichTextLabel")
	label.text = str(100 * ammount,"%")
	
	if ammount > 0:
		type.modulate = Color(1, 0.278, 0.357, 0.671)
	elif ammount < 0:
		type.modulate = Color(0.58, 0.592, 0.541, 0.671)
	
	type.show()

func _on_timer_timeout():
	quickInfo.hide()
	quickInfo.text = ""
