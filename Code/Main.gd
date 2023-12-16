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
var team: Array = []
var opposing: Array = []
var targetArray: Array = []
var targetArrayGroup: Array = []
var waiting: bool = false
var finished: bool = false
var targetDied: bool = false
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
	
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		team[i].menu.show()
	else:
		team = enemyOrder
		opposing = playerOrder
		print(team[i].chooseMove())
		enemyAction = team[i].chooseMove()
	
	
	$".".add_child($Timer)
	$Timer.set_paused(false)
	actionNum = 3
	playerTP = playerMaxTP
	enemyTP = enemyMaxTP

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
			tabTPs.append(SaveTPCosts(player.moveset[tab][n],tab))
		player.descriptions.append(tabDescriptions)
		player.TPArray.append(tabTPs)

func movesetDescription(moveset,player,n):
	var fullDesc
	var move = moveset
	var desc: String = ""
	var Elements: String = ""
	var Power: String = ""
	if n == 2:
		move = moveset.attackData
	
	#Determine if element should be displayed
	if move.element != "Neutral":
		Elements = str("[",move.element,"]")
		match move.element:
			"Fire":
				Elements = str("[color=red]",Elements,"[/color]")
			"Water":
				Elements = str("[color=aqua]",Elements,"[/color]")
			"Elec":
				Elements = str("[color=gold]",Elements,"[/color]")
		
	if move.phyElement != "Neutral":
		Elements = str("[",move.phyElement,"]",Elements)
		match move.phyElement:
			"Slash":
				Elements = str("[color=forest_green]",Elements,"[/color]")
			"Crush":
				Elements = str("[color=olive]",Elements,"[/color]")
			"Pierce":
				Elements = str("[color=orange]",Elements,"[/color]")
	
	if move.property & 1 or move.property & 2 or move.property & 4:
			Power = str("Pow: ",move.Power," ")
	
	match n:
		0:
			if move.name == "Attack" or move.name == "Crash" or move.name == "Burst":
				Elements = str("[",player.data.phyElement,"]")
				match player.data.phyElement:
					"Slash":
						Elements = str("[color=forest_green]",Elements,"[/color]")
					"Crush":
						Elements = str("[color=olive]",Elements,"[/color]")
					"Pierce":
						Elements = str("[color=orange]",Elements,"[/color]")
			fullDesc = str(move.description, Elements, Power)
		1: #Skills should show the specific cost and their ammount
			desc = str(move.description)
			var costText
			if move.CostType == "HP" or move.CostType == "MaxHP":
				costText = str("[color=red]"+ "HP: ",int(move.cost * player.data.MaxHP), "[/color]")
			if move.CostType == "LP":
				costText = str("[color=aqua]"+"LP: ",int(move.cost), "[/color]")
			
			fullDesc = str(costText, desc, Elements, Power,)
			
		2: #Item Descriptions need to show #ofItems/MaxItems
			var itemMax = moveset.maxItems #Moveset has Item Specifics, move has thier attack data
			desc = str("/",itemMax,"]"+"[/i]",move.description)
			
			fullDesc = str(desc, Elements, Power)
		_:
			fullDesc = str(move.description)
			if move.name == "Boost":
				fullDesc = str(fullDesc, HelperFunctions.Flag_to_String(player.playerData.boostStat, "Boost"))
	
	return fullDesc

func SaveTPCosts(moveset,n):
	var move = moveset
	if n == 2:
		move = moveset.attackData
	var TPCost = move.TPCost
	return TPCost

func _process(_delta):#If player turn ever changes change current team to match the bool
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		if Globals.attacking:
			nextTarget()
	else:
		team = enemyOrder
		opposing = playerOrder
		which = findWhich(enemyAction)
		target = findTarget(enemyAction)
		if not waiting:
			print(waiting,"WAITING")
			nextTarget()
	if $Timer.is_stopped():
		print("a")
	
	
	#Keep cursor on current active turn
	cursor.position = team[i].position + Vector2(-30,-30)	#Keep cursor on current active turn
	#TP Displays
	if playerMaxTP < playerTP:
		playerTP = playerMaxTP
	if enemyMaxTP < enemyTP:
		enemyTP = enemyMaxTP
	
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

func nextTarget():
	match which:
		whichTypes.ENEMY:
			targetArray = opposing
		whichTypes.ALLY:
			targetArray = team
		whichTypes.BOTH:
			targetArray = team + opposing
	match target:
		targetTypes.SINGLE:
			if playerTurn:
				PSingleSelect(targetArray)
			else:
				print("Single")
				waiting = true
				index = team[i].SingleSelect(targetArray,enemyAction)
				EfinishSelectiong(enemyAction)
		
		targetTypes.GROUP:
			targetArrayGroup = []
			establishGroups(targetArray)
			if playerTurn:
				for k in targetArrayGroup[groupIndex]:
					k.show()
				PGroupSelect(targetArrayGroup)
			else:
				print("Group")
				waiting = true
				targetArrayGroup = []
				establishGroups(targetArray)
				groupIndex = team[i].GroupSelect(targetArrayGroup,enemyAction)
				
				EfinishSelectiong(enemyAction)
		
		targetTypes.SELF:
			targetArray = team
			index = i
			if playerTurn:
				PConfirmSelect(targetArray[index])
			else:
				waiting = true
				EfinishSelectiong(enemyAction)
		
		targetTypes.ALL:
			if playerTurn:
				PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelectiong(enemyAction)
		
		targetTypes.RANDOM:
			if playerTurn:
				PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelectiong(enemyAction)

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

func _on_cancel_selected():
	Globals.attacking = false
	var everyone = team + opposing
	for k in range(everyone.size()):
		everyone[k].selected.hide()

#-----------------------------------------
#ENEMY SELCTING
#-----------------------------------------
func EfinishSelectiong(useMove):
	enemyTP -= team[i].payCost(useMove)
	TPChange(false)
	waiting = true
	
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

func useAction(useMove, targetting, user, hits):
	var times = 0
	while times < hits:
		if targetDied:
			targetDied = false
			break
		
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove,targetting,user)
		times += 1
		await get_tree().create_timer(1).timeout

func useActionRandom(useMove, targetting, user, hits):
	var times = 0
	while times < hits:
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove,targetting,user)
		times += 1
		await get_tree().create_timer(1).timeout

func checkProperties(move,targetting,user):
	if move.property & 1:
		offense(move,targetting,user)
		await tweenDamage(targetting,user)
	if move.property & 2:
		offense(move,targetting,user)
		await tweenDamage(targetting,user)
	if move.property & 4:
		offense(move,targetting,user)
		await tweenDamage(targetting,user)
	if move.property & 8:
		buffing(move,targetting,user)
	if move.property & 16:
		healing(move,targetting,user)
		tweenDamage(targetting,user)
	if move.property & 32:
		aura(move)
	if move.property & 64:
		summon(move,user)
	if move.property & 128:
		ailment(move,targetting,user)
	if move.property & 256:
		pass
	
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
	var halfMoonCheck = 0
	if move.property & 1:
		targetting.currentHP -= user.attack(move, targetting, user,"Physical",currentAura)
		halfMoonCheck += 1
	if move.property & 2:
		targetting.currentHP -= user.attack(move, targetting, user,"Ballistic",currentAura)
		halfMoonCheck += 1
	elif move.property & 4:
		targetting.currentHP -= user.BOMB(move, targetting)
	
	print(halfMoonCheck)
	
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

#-----------------------------------------
#TURN END FUNCTIONS
#-----------------------------------------
func tweenDamage(targetting,user):
	var tween = targetting.HPBar.create_tween()
	tween.connect("finished", _on_tween_completed)
	
	targetting.displayQuick(user.feedback)
	targetting.HPtext.text = str("HP: ",targetting.currentHP)
	await tween.tween_property(targetting.HPBar, "value",
	int(100 * float(targetting.currentHP) / float(targetting.data.MaxHP)),tweenTiming).set_trans(Tween.TRANS_CIRC)
	
	print(user.feedback,"to",targetting.data.name)
	user.feedback = ""

func _on_tween_completed(): #For Enemy Turns and multihits, makes individual hits more visible
	print("A")

func next_entity():
	var everyone = team + opposing
	for k in range(everyone.size()):
		everyone[k].selected.hide()
	
	#If it's the player, their menu should be hidden
	if team[i].has_node("CanvasLayer"):
		team[i].menu.hide()
	
	#Get to the next entity
	#If the current team's index is higher than the size, reset both indexes and switch teams
	i += 1
	if i > (team.size() - 1):
		i = 0
		j = 0
		index = 0
	
	
	else:
		if team[i].has_node("CanvasLayer"):
			checkCosts(team[i])
			team[i].menu.show()
		else:
			enemyAction = team[i].chooseMove()
			pass
	actionNum -= 1
	switchPhase()
	print("I: ",i,"J:",j,"Action Num: ", actionNum, "PLayerTurn:",playerTurn)
	targetDied = false

func checkCosts(player): #Check if the player can afford certain moves, if they can't disable those buttons
	for category in player.moveset:
		var menuIndex = player.moveset.find(category)
		for move in category:
			match menuIndex:
				0:
					if not checkCostsMini(player, playerTP, "TP", move, menuIndex):
						continue
					if move.CostType == "Overdrive":
						checkCostsMini(player, player.data.AilmentNum, "Overdrive", move, menuIndex)
				1:
					if not checkCostsMini(player, playerTP, "TP", move, menuIndex):
						continue
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
	var cantpay = false
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
		cantpay = true
	if cantpay:
		print(cost,"|", pay,"vs",use,"Can't pay for", move.name)
		player.emit_signal("canPayFor",menuIndex,buttonIndex,false)
		cantpay = false
	else:
		player.emit_signal("canPayFor",menuIndex,buttonIndex,true)
	
	return cantpay

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

func switchPhase():
	if actionNum <= 0:
		playerTurn = not playerTurn
		
		if playerTurn:
			team = playerOrder
			opposing = enemyOrder
			
			playerTP += int(float(playerMaxTP) *.5)
			checkCosts(playerOrder[0])
			playerOrder[0].menu.show()
			var TPtween = $PlayerTP.create_tween()#TP management must be handled here
			var newValue = int(100*(float(playerTP) / float(playerMaxTP)))
			TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
		else:
			team = enemyOrder
			opposing = playerOrder
			
			enemyTP += int(float(enemyMaxTP) *.5)
			var TPtween = $EnemyTP.create_tween()#TP management must be handled here
			var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
			TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
			Globals.attacking = false
		actionNum = 3
		print("Switch")

func _on_timer_timeout():
	print("efeoufononisonivoni")
	waiting = false
	next_entity()
