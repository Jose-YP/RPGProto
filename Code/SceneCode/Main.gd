extends Node2D

#Main Scene is a battle so this is where initial order is decided and managed
@export var playerTurn: bool = true #Starting Bool
@export var tweenTiming: float = .2 #Make the timing with the hits editable
@onready var cursor: Sprite2D = $Cursor
@onready var PlayerTPDisplay = $PlayerTP
@onready var PlayerTPText = $PlayerTP/Label
@onready var EnemyTPDisplay = $EnemyTP
@onready var EnemyTPText = $EnemyTP/Label
@onready var AuraFog = $Aura
@onready var AuraLabel = $Label
@onready var enemyOrder: Array = []
@onready var playerOrder: Array = []

#Make every player's menu
var currentMenu
var groups = ["Attack","Skills","Items","Tactics"]
#Hold current enemy's action
var actionNum = 0
var enemyAction
#Holds current team and temmate's turn
var i: int = 0
var j: int = 0
var index: int = 0
var groupIndex: int = 0
var overdriveI: int = 0
var team: Array = []
var opposing: Array = []
var everyone: Array = []
var overdriveHold: Array = []
var targetArray: Array = []
var targetArrayGroup: Array = []
var waiting: bool = false
var overdriveTurn: bool = false
var finished: bool = false
var targetDied: bool = false
var scanning: bool = false
#Battle Stats
var playerTP: int = 0
var playerMaxTP: int = 0
var enemyTP: int = 0
var enemyMaxTP: int = 0
var currentAura = ""
#Determines which targetting system to use
var target
var which
enum targetTypes {
	SINGLE,
	GROUP,
	SELF,
	ALL,
	RANDOM,
	TARGETTED,
	NONE
}
enum whichTypes {
	ENEMY,
	ALLY,
	BOTH
}

#-----------------------------------------
#INTIALIZATION & PROCESS
#-----------------------------------------
func _ready(): #Assign current team according to starting bool
#	get_node("Node2D").process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for player in get_tree().get_nodes_in_group("Players"):
		player.currentHP = player.data.MaxHP
		playerMaxTP += player.data.MaxTP
		playerOrder.append(player)
		movesetDisplay(player)
		
		player.connect("startSelect", _on_start_select)
		player.connect("moveSelected", _on_move_selected)
		player.connect("cancel", _on_cancel_selected)
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.currentHP = enemy.data.MaxHP
		enemyMaxTP += enemy.data.MaxTP
		enemyOrder.append(enemy)
	
	actionNum = 3
	playerTP = playerMaxTP
	enemyTP = enemyMaxTP
	
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		checkCosts(playerOrder[0])
		team[i].menu.show()
	else:
		team = enemyOrder
		opposing = playerOrder
		enemyAction = team[i].chooseMove(enemyTP)
	
	everyone = playerOrder + enemyOrder
	$Timer.set_paused(false) #Should've done this to avoid so much ;-; It took so long to figure out I DESERVE TO USE THIS
	$PostPhaseTimer.set_paused(false)

func movesetDisplay(player): #Format every player's menu to include the name of their moveset
	#get the player's complete moveset
	player.moveset = [player.attacks,player.skills,player.items,player.tactics]
	#Get the tab
	var tabs = player.get_node("CanvasLayer/TabContainer").get_children()
	
	for tab in range(tabs.size()):
		#Get the buttons in the specific tab
		var tabDescriptions = []
		var tabTPs = []
		currentMenu = tabs[tab].get_node("MarginContainer/GridContainer").get_children()
		#Only fill in as much as the moveset has
		for n in range(player.moveset[tab].size()):
			currentMenu[n].text = player.moveset[tab][n].name
			tabDescriptions.append(movesetDescription(player.moveset[tab][n],player,tab))
			tabTPs.append(SaveTPCosts(player.moveset[tab][n]))
		player.descriptions.append(tabDescriptions)
		player.TPArray.append(tabTPs)

func movesetDescription(moveset,player,n):
	var fullDesc
	var move = moveset
	var desc: String = ""
	var Elements: String = ""
	var PhyElement: String = ""
	var Power: String = ""
	if move is Item:
		move = moveset.attackData
	
	#Determine if element should be displayed
	if move.element != "Neutral":
		Elements = str("[",move.element,"]")
		Elements = HelperFunctions.colorElements(move.element, Elements)
		
	if move.phyElement != "Neutral":
		PhyElement = str("[",move.phyElement,"]")
		PhyElement = HelperFunctions.colorElements(move.phyElement, PhyElement)
	
	if move.property & 1 or move.property & 2 or move.property & 4:
			Power = str("Pow: ",move.Power," ")
	
	match n:
		0:
			if move.name == "Attack" or move.name == "Crash" or move.name == "Burst":
				PhyElement = str("[",player.data.phyElement,"]")
				PhyElement = HelperFunctions.colorElements(move.phyElement, PhyElement)
			
			fullDesc = str(move.description, Elements, PhyElement, Power)
			
		1: #Skills should show the specific cost and their ammount
			desc = str(move.description)
			var costText
			if move.CostType == "HP" or move.CostType == "MaxHP":
				costText = str("[color=red]"+ "HP: ",int(move.cost * player.data.MaxHP), "[/color]")
			if move.CostType == "LP":
				costText = str("[color=aqua]"+"LP: ",int(move.cost), "[/color]")
			
			fullDesc = str(costText, desc, Elements, PhyElement, Power,)
			
		2: #Item Descriptions need to show #ofItems/MaxItems
			var itemMax = moveset.maxItems #Moveset has Item Specifics, move has thier attack data
			desc = str("/",itemMax,"]"+"[/i]",move.description)
			
			fullDesc = str(desc, Elements, PhyElement, Power)
		_:
			fullDesc = str(move.description)
			if move.name == "Boost":
				fullDesc = str(fullDesc, HelperFunctions.Flag_to_String(player.playerData.boostStat, "Boost"))
	
	return fullDesc

func SaveTPCosts(moveset):
	var move = moveset
	if move is Item:
		move = moveset.attackData
	var TPCost = move.TPCost
	return TPCost

func _process(_delta):#If player turn ever changes change current team to match the bool
	if overdriveTurn:
		if Globals.attacking or not waiting:
			nextTarget(overdriveHold)
	
	elif playerTurn:
		team = playerOrder
		opposing = enemyOrder
		if Globals.attacking:
			nextTarget()
	else:
		team = enemyOrder
		opposing = playerOrder
		if not waiting:
			which = findWhich(enemyAction)
			target = findTarget(enemyAction)
			nextTarget()
	
	if scanning:
		stopScanning()
	
	#Keep cursor on current active turn
	cursor.position = team[i].position + Vector2(-30,-30)	#Keep cursor on current active turn
	#TP Displays
	if playerMaxTP < playerTP:
		playerTP = playerMaxTP
	if enemyMaxTP < enemyTP:
		enemyTP = enemyMaxTP
	
	everyone = playerOrder + enemyOrder
	PlayerTPText.text = str("TP: ",playerTP,"/",playerMaxTP)
	EnemyTPText.text = str("TP: ",enemyTP, "/", enemyMaxTP)

func initializeTP(players=false): #Make and remake max TPs when an entiy is gone or enters
	if players:
		playerMaxTP = 0
		for player in playerOrder:
			playerMaxTP += player.data.MaxTP
		if playerTP > playerMaxTP:
			playerTP = playerMaxTP
	else:
		enemyMaxTP = 0
		for enemy in enemyOrder:
			enemyMaxTP += enemy.data.MaxTP
		if enemyTP > enemyMaxTP:
			enemyTP = enemyMaxTP
#-----------------------------------------
#TARGETTING MANAGERS
#-----------------------------------------
func findTarget(useMove):
	var returnTarget
	match useMove.Target:
		"Single":
			returnTarget = targetTypes.SINGLE
		"Group":
			returnTarget = targetTypes.GROUP
		"Self":
			returnTarget = targetTypes.SELF
		"All":
			returnTarget = targetTypes.ALL
		"Random":
			returnTarget = targetTypes.RANDOM
		"None":
			returnTarget = targetTypes.NONE
	
	return returnTarget

func findWhich(useMove):
	var returnWhich
	match useMove.Which:
		"Enemy":
			returnWhich = whichTypes.ENEMY
		"Ally":
			returnWhich = whichTypes.ALLY
		"Both":
			returnWhich = whichTypes.BOTH
	
	return returnWhich

func checkForTargetted(targetting):
	var trueTargetArray = []
	
	for entity in targetting:
		if entity.checkCondition("Targetted", entity):
			trueTargetArray.append(entity)
			target = targetTypes.TARGETTED
	
	if trueTargetArray.size() == 0:
		return targetArray
	else:
		return trueTargetArray

func nextTarget(TeamSide = team,OpposingSide = opposing):
	match which:
		whichTypes.ENEMY:
			targetArray = OpposingSide
		whichTypes.ALLY:
			targetArray = TeamSide
		whichTypes.BOTH:
			targetArray = TeamSide + OpposingSide
			
	targetArray = checkForTargetted(targetArray)
	match target:
		targetTypes.SINGLE:
			if playerTurn:
				if Globals.attacking:
					PSingleSelect(targetArray)
			else:
				waiting = true
				index = team[i].SingleSelect(targetArray,enemyAction)
				EfinishSelecting(enemyAction)
		
		targetTypes.GROUP:
			targetArrayGroup = []
			establishGroups(targetArray)
			if playerTurn:
				if Globals.attacking:
					for k in targetArrayGroup[groupIndex]:
						k.show()
					PGroupSelect(targetArrayGroup)
			else:
				waiting = true
				targetArrayGroup = []
				establishGroups(targetArray)
				groupIndex = team[i].GroupSelect(targetArrayGroup,enemyAction)
				
				EfinishSelecting(enemyAction)
		
		targetTypes.SELF:
			targetArray = team
			index = i
			if playerTurn:
				if Globals.attacking:
					PConfirmSelect(targetArray[index])
			else:
				waiting = true
				EfinishSelecting(enemyAction)
		
		targetTypes.ALL:
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)
		
		targetTypes.RANDOM:
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)
		
		targetTypes.TARGETTED:
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)

func establishGroups(targetting):
	for element in Globals.elementGroups:
		var tempChecking: Array = []
		for k in range(targetting.size()):
			if targetting[k].data.TempElement == element:
				tempChecking.append(targetting[k])
		if tempChecking.size() != 0:
			targetArrayGroup.append(tempChecking)
	finished = true

#-----------------------------------------
#PLAYERSELECTING // UI CONTROLS
#-----------------------------------------
func PSingleSelect(targetting):
	if not whichTypes.BOTH:#Simple line movement
		if Input.is_action_just_pressed("Left"):
			targetArray[index].selected.hide()
			index -= 1
			if index < 0:
				index = targetting.size() - 1
		if Input.is_action_just_pressed("Right"):
			targetArray[index].selected.hide()
			index += 1
			if index > (targetting.size() - 1):
				index = 0
	
	if whichTypes.BOTH: #Moves like a Grid
		if Input.is_action_just_pressed("Left"):
			targetArray[index].selected.hide()
			index -= 1
			if index < 0:
				index = 2
			elif index == 2:
				index = targetting.size() - 1
		if Input.is_action_just_pressed("Right"):
			targetArray[index].selected.hide()
			index += 1
			if index > (targetting.size() - 1):
				index = 3
			elif  index == 3:
				index = 0
			
		if Input.is_action_just_pressed("Up"):
			targetArray[index].selected.hide()
			index += 3
			if index > (targetting.size() - 1):
				index -= 6
		if Input.is_action_just_pressed("Down"):
			targetArray[index].selected.hide()
			index -= 3
			if index < 0:
				index += 6
	
	PConfirmSelect(targetArray[index])

func PGroupSelect(targetting):
	if Input.is_action_just_pressed("Left"):
		for k in targetArrayGroup[groupIndex]:
			k.selected.hide()
		groupIndex -= 1
		
		if groupIndex < 0:
			groupIndex = targetting.size() - 1
		print(targetArrayGroup[groupIndex])
	if Input.is_action_just_pressed("Right"):
		for k in targetArrayGroup[groupIndex]:
			k.selected.hide()
		groupIndex += 1
		if groupIndex > (targetting.size() - 1):
			groupIndex = 0
	
	for k in targetArrayGroup[groupIndex]:
		PConfirmSelect(k)

func PConfirmSelect(targetting):
	targetting.selected.show()

func PAllSelect(targetting):
	for k in targetting:
		k.selected.show()

func stopScanning():
	if Input.is_action_just_pressed("Accept"):
		var removeScanFrom
		var scanBoxTween
		scanning = false
		
		for enemy in enemyOrder:
			if enemy.gettingScanned == true:
				scanBoxTween = enemy.create_tween()
				print("Modulating",enemy)
				scanBoxTween.tween_property(enemy.ScanBox, "modulate", Color.TRANSPARENT,1)
		next_entity()

func _on_cancel_selected():
	Globals.attacking = false
	for k in range(everyone.size()):
		everyone[k].selected.hide()

#-----------------------------------------
#ENEMY SELCTING
#-----------------------------------------
func EfinishSelecting(useMove):
	enemyTP -= team[i].payCost(useMove)
	TPChange(false)
	waiting = true
	
	team[i].displayMove(useMove)
	await action(useMove)
	$Timer.start()

#-----------------------------------------
#UI BUTTONS
#-----------------------------------------
func _on_start_select(useMove):
	Globals.attacking = true
	target = findTarget(useMove)
	which = findWhich(useMove)

func _on_move_selected(useMove):
	playerTP -= team[i].payCost(useMove) #The function handles the player's other costs on it's own
	TPChange()
	
	team[i].menu.hide() #Don't let the player mash buttons until attack is over
	await action(useMove)
	Globals.attacking = false
	if not scanning:
		next_entity()

#-----------------------------------------
#USING MOVES
#-----------------------------------------
func action(useMove):
	var hits = useMove.HitNum
	
	match target:
		targetTypes.GROUP:
			var groupSize = targetArrayGroup[groupIndex].size()
			var offset = 0
			if groupSize == 1:
				hits *= 2
			
			for k in range(groupSize):
				if targetDied: #Array goes 1by1 so lower k and size by 1 to get back on track
					targetArrayGroup = [] #Resestablish Groups
					establishGroups(targetArray)
					offset += 1
					targetDied = false
				print(targetArrayGroup)
				print("Group Index: ",groupIndex,"Group Size: ", groupSize, "k:", k, "Offset: ", offset)
				print(targetArrayGroup[groupIndex][k - offset].name)
				
				await useAction(useMove,targetArrayGroup[groupIndex][k - offset],team[i],hits)
			groupIndex = 0
		
		targetTypes.ALL:
			var groupSize = targetArray.size()
			var offset = 0
			for k in range(groupSize):
				if targetDied: #Array goes 1by1 so raise the offset by 1
					offset += 1
					targetDied = false
				await useAction(useMove,targetArray[k - offset],team[i],hits)
		
		targetTypes.RANDOM:
			for k in range(hits):
				await useAction(useMove,targetArray[randi()%targetArray.size()],team[i],1)
		
		_:
			await useAction(useMove,targetArray[index],team[i],hits)
	
	#Remove Charge and Amp only if they were used
	#Do them here so multihits don't lose charge/amp instantly
	if team[i].checkCondition("Charge",team[i]) and team[i].chargeUsed:
		team[i].removeCondition("Charge",team[i])
		team[i].chargeUsed = false
	
	if team[i].checkCondition("Amp",team[i]) and team[i].ampUsed:
		team[i].removeCondition("Amp",team[i])
		team[i].ampUsed = false

func useAction(useMove, targetting, user, hits):
	var times = 0
	while times < hits:
		if targetDied:
			targetDied = false
			break
		
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		
		if user.midTurnAilments(user.data.Ailment, currentAura):
			checkProperties(useMove,targetting,user)
		
		times += 1
		await get_tree().create_timer(.5).timeout

func useActionRandom(useMove, targetting, user, hits):
	var times = 0
	while times < hits:
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove,targetting,user)
		times += 1
		await get_tree().create_timer(1).timeout

func checkProperties(move,targetting,user):
	if move.property & 256: #Misc first allows cetain changes before attacks
		determineFunction(move.name,targetting,user)
	if move.property & 1:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		await get_tree().create_timer(.4).timeout #Damage deserves a little more time to be seen
	if move.property & 2:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		await get_tree().create_timer(.4).timeout
	if move.property & 4:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		await get_tree().create_timer(.4).timeout
	if move.property & 8:
		buffing(move,targetting,user)
	if move.property & 16:
		healing(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
	if move.property & 32:
		aura(move)
	if move.property & 64:
		summon(move,user)
	if move.property & 128:
		ailment(move,targetting,user)
	
	checkHP()

func TPChange(player = true):
	var TPtween
	if player:
		TPtween = $PlayerTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(playerTP) / float(playerMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
	else:
		TPtween = $EnemyTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
		TPtween.tween_property(EnemyTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)

#-----------------------------------------
#CHECKPROPERTY FUNCTIONS
#-----------------------------------------
func offense(move,targetting,user):
	targetting.selected.hide()
	if move.property & 1:
		targetting.currentHP -= user.attack(move, targetting, user,"Physical",currentAura)
	if move.property & 2:
		targetting.currentHP -= user.attack(move, targetting, user,"Ballistic",currentAura)
	elif move.property & 4:
		targetting.currentHP -= user.BOMB(move, targetting)
	
	if targetting.currentHP <= 0:
		targetting.currentHP = 0

func healing(move,targetting,user):
	targetting.selected.hide()
	if move.healing != 0:
		targetting.currentHP += user.healHP(move, targetting)
		if targetting.currentHP >= targetting.data.MaxHP:
			targetting.currentHP = targetting.data.MaxHP
		targetting.HPtext.text = str("HP: ",targetting.currentHP)
	
	if move.HealedAilment != "None":
		user.healAilment(move, targetting)

func buffing(move,targetting,user):
	if move.BoostType != 0 and move.BoostType != null:
		user.buffStat(targetting,move.BoostType,move.BoostAmmount)
	elif user.has_node("CanvasLayer"):
		if user.playerData.boostStat != null:
			user.buffStat(targetting,user.playerData.boostStat,move.BoostAmmount)
	
	if move.Condition != 0 and move.Condition != null:
		user.buffCondition(move,targetting)
	
	if move.ElementChange != "None" and move.ElementChange != null and move.ElementChange != "":
		user.buffElementChange(move,targetting,user)
	
	Globals.attacking = false
	targetting.selected.hide()

func aura(move):
	if move.Aura != "None":
		AuraFog.show()
		AuraLabel.show()
	
	match move.Aura:
		"None":
			AuraFog.hide()
			AuraLabel.hide()
		"BodyBroken":
			AuraFog.modulate = Color("#ffa5ff21")
			AuraLabel.text = "BodyBreak!"
		"WillWrecked":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "WillWreck!"
		"LowTicks":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "LowTick!"
		"CritDouble":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "CritsChanceDoubled!"

func summon(_move,_user):
	pass

func ailment(move,targetting,user):
	if move.Ailment == "Overdrive" or move.Ailment == "Protected":
		user.applyPositiveAilment(move,targetting)
	elif move.Ailment != "PhySoft" and move.Ailment != "EleSoft":
		user.applyNegativeAilment(move,targetting,user)
	else:
		user.applyXSoft(move,targetting,user)

func determineFunction(moveName,reciever,_user):
	match moveName:
		"Crash":
			if playerTurn:
				enemyTP = MiscFunctions.miscFunCrash(reciever,enemyMaxTP,enemyTP)
				TPChange(false)
			else:
				playerTP = MiscFunctions.miscFunCrash(reciever,playerMaxTP,playerTP)
				TPChange()
		"Scan":
			scanning = true
			reciever.gettingScanned = true
			reciever.ScanBox.show()

#-----------------------------------------
#TURN END FUNCTIONS
#-----------------------------------------

func next_entity():
	if overdriveTurn: #Return things to normal
		if team[i].has_node("CanvasLayer"):
			team[i].menu.hide()
		
#		print("Try to make it normal again")
#		print("OverdriveHolds:",overdriveHold,overdriveI)
		overdriveTurn = false
		team = overdriveHold
		i = overdriveI
	
	for k in range(everyone.size()):
		everyone[k].selected.hide()
	
	#If it's the player, their menu should be hidden
	if team[i].has_node("CanvasLayer"):
		team[i].menu.hide()
	
	overdriveTurnManager()
	
	if not overdriveTurn:
		#Get to the next entity
		#If the current team's index is higher than the size, reset both indexes and switch teams
		actionNum -= 1
		i += 1
		if i > (team.size() - 1):
			i = 0
			j = 0
			index = 0
		
		else:
			if team[i].has_node("CanvasLayer"):
				checkCosts(team[i])
				team[i].menu.show()
				team[i].firstButton.grab_focus()
			else:
				enemyAction = team[i].chooseMove(enemyTP)
				target = findTarget(enemyAction)
				which = findWhich(enemyAction)
		
		startSwitchPhase()
		targetDied = false

func overdriveTurnManager():
	for k in range(everyone.size()):
		if everyone[k].checkCondition("AnotherTurn",everyone[k]):
			overdriveTurn = true
			everyone[k].removeCondition("AnotherTurn",everyone[k])
			
			#Hold the regular team order in here
			if overdriveHold.size() == 0:
				overdriveHold = team
				overdriveI = i
			
			i = 0
			team = []
			team.append(everyone[k])
			
			if team[i].has_node("CanvasLayer"):
				checkCosts(team[i])
				team[i].menu.show()
				playerOrder[0].firstButton.grab_focus()
			else:
				enemyAction = team[i].chooseMove(enemyTP)
				target = findTarget(enemyAction)
				which = findWhich(enemyAction)

func startSwitchPhase():
	if actionNum <= 0:
		waiting = true
		$PostPhaseTimer.start()
		playerTurn = not playerTurn
		endPhaseCheck()

func switchPhase():
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		
		playerTP += int(float(playerMaxTP) *.5)
		checkCosts(playerOrder[0])
		playerOrder[0].menu.show()
		playerOrder[0].firstButton.grab_focus()
		
		var TPtween = $PlayerTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(playerTP) / float(playerMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
	else:
		team = enemyOrder
		opposing = playerOrder
		enemyAction = enemyOrder[0].chooseMove(enemyTP)
		
		enemyTP += int(float(enemyMaxTP) *.5)
		var TPtween = $EnemyTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
		Globals.attacking = false
	actionNum = 3

func checkCosts(player): #Check if the player can afford certain moves, if they can't disable those buttons
	for category in player.moveset:
		var menuIndex = player.moveset.find(category)
		for move in category:
			match menuIndex:
				0:
					if move.CostType == "Overdrive": #Check if it has Overdrive first, if not TP Count doesn't matter
						if not checkCostsMini(player, player.data.AilmentNum, "Overdrive", move, menuIndex):
							continue
					checkCostsMini(player, playerTP, "TP", move, menuIndex)
					
				1: #All the others check TP first then the thing they're missing 
					if not checkCostsMini(player, playerTP, "TP", move, menuIndex):
						continue#Continue so a having the right ammount of one cost isn't enough
					if move.CostType == "LP":
						checkCostsMini(player, player.currentLP, "LP", move, menuIndex)
					elif move.CostType == "HP":
						checkCostsMini(player, player.currentHP, "HP", move, menuIndex)
				2:
					if not checkCostsMini(player, playerTP, "TP", move, menuIndex, true):
						continue
					var ammount
					for item in player.data.itemData:
						if item.name == move.name:
							ammount = player.data.itemData[item]
					checkCostsMini(player, ammount, "Item", move, menuIndex, true)
				3:
					checkCostsMini(player, playerTP, "TP", move, menuIndex)

func checkCostsMini(player, pay, cost, move, menuIndex, searchingItem = false):
	var buttonIndex = player.moveset[menuIndex].find(move)
	var use
	var canpay = true
	match cost:
		"TP":
			if searchingItem:
				use = int(move.attackData.TPCost - (player.data.speed*(1 + player.data.speedBoost)))
			else:
				use = int(move.TPCost - (player.data.speed*(1 + player.data.speedBoost)))
		"Overdrive":
			use = 1
		"HP":
			use = int(player.data.MaxHP * move.cost)
		"LP":
			use = int(move.cost)
		"Item":
			use = int(move.attackData.cost)
		
	if pay < use:
		canpay = false
	if not canpay:
		print(cost,"|", pay,"vs",use,"Can't pay for", move.name)
		player.emit_signal("canPayFor",menuIndex,buttonIndex,false)
	else:
		player.emit_signal("canPayFor",menuIndex,buttonIndex,true)
	
	return canpay

func endPhaseCheck():
	for k in range(opposing.size()):
		opposing[k].statBoostHandling()
		var holdAilment = opposing[k].ailmentCategory(opposing[k])
		if holdAilment != "Mental" or holdAilment != "Nonmental":
			opposing[k].endPhaseAilments(opposing[k].data.Ailment)
		
	if playerTurn:
		for player in playerOrder:
			if player.checkCondition("Targetted", player):
				if player.targetCount != 0:
					target -= 1
				else:
					player.removeCondition("Targetted",player)
		
	else:
		for enemy in enemyOrder:
			if enemy.checkCondition("Targetted", enemy):
				if enemy.targetCount != 0:
					target -= 1
				else:
					enemy.removeCondition("Targetted",enemy)

func checkHP(): #Delete enemies, disable players and resize arrays as necessary also handles win and lose condition
	var defeatedPlayers = []
	var defeatedEnemies = []
	var InitialPsize = playerOrder.size()
	var InitialESize = enemyOrder.size()
	var lowerP = 0
	var lowerE = 0
	
	#Check which players and enemies are dead
	for player in playerOrder:
		player.selected.hide()
		if player.currentHP <= 0:
			targetDied = true
			defeatedPlayers.append(player)
			lowerP += 1
	for enemy in enemyOrder:
		enemy.selected.hide()
		if enemy.currentHP <= 0:
			targetDied = true
			defeatedEnemies.append(enemy)
			lowerE += 1
	
	#Deal with them and their side's array accordingly
	for defeatedPlayer in defeatedPlayers:
		playerOrder.erase(defeatedPlayer)
		defeatedPlayer.modulate = Color(454545)
	for defeatedEnemy in defeatedEnemies:
		enemyOrder.erase(defeatedEnemy)
		if defeatedEnemy.enemyData.Boss:
			defeatedEnemy.modulate = Color(454545)
		else:
			defeatedEnemy.queue_free()
	#Win condition
	if enemyOrder.size() == 0:
		team[i].menu.hide()
		get_tree().paused = true
	
	if playerOrder.size() == 0:
		print("You lose")
		get_tree().paused = true
	
	#Resize 
	playerOrder.resize(InitialPsize - lowerP)
	enemyOrder.resize(InitialESize - lowerE)
	#Reset values
	index = 0
	target = null
	finished = false
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
	else:
		team = enemyOrder
		opposing = playerOrder
	
	#Only Reset values if somone died
	#This lets the player mash a to attack the same guy a bunch until they die
	if InitialPsize != playerOrder.size() or InitialESize != enemyOrder.size():
		j = 0
		index = 0

func _on_timer_timeout():
	waiting = false
	team[i].hideDesc()
	next_entity()

func _on_post_phase_timer_timeout():
	waiting = false
	switchPhase()