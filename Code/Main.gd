extends Node2D

#Main Scene is a battle so this is where initial order is decided and managed
@export var playerTurn: bool = true #Starting Bool
@export var tweenTiming: float = .2 #Make the timing with the hits editable
@onready var cursor: Sprite2D = $Cursor
@onready var enemyOrder: Array = []
@onready var playerOrder: Array = []

#Make every player's menu
var currentMenu
var groups = ["Attack","Skills","Items","Tactics"]
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
var playerTP
var playerMaxTP
var enemyTP
var enemyMaxTP
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
#Important for battle
enum auraTypes{
	NONE,
	BODYBREAK,
	WILLWRECK,
	LOWTICKS,
	CRITDOUBLE,
	FIREAUG,WATERAUG,ELECAUG,SLASHAUG,CRUSGAUG,PIERCEAUG,
	FIREDAMP,WATERDAMP,ELECDAMP,SLASHDAMP,CRUSHDAMP,PIERCEDAMP
}
#-----------------------------------------
#INTIALIZATION & PROCESS
#-----------------------------------------
func _ready(): #Assign current team according to starting bool
#	get_node("Node2D").process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for player in get_tree().get_nodes_in_group("Players"):
		player.currentHP = player.data.MaxHP
		playerOrder.append(player)
		movesetDisplay(player)
		
		player.connect("wait", _on_wait_selected)
		player.connect("boost", _on_boost_selected)
		player.connect("scan", _on_scan_selected)
		player.connect("startSelect", _on_start_select)
		player.connect("moveSelected", _on_move_selected)
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.currentHP = enemy.data.MaxHP
		enemyOrder.append(enemy)
	
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		team[i].menu.show()
	else:
		team = enemyOrder
		opposing = playerOrder

func movesetDisplay(player): #Format every player's menu to include the name of their moveset
	#get the player's complete moveset
	var moveset = [player.attacks,player.skills,player.items]
	#Get the tab
	var tabs = player.get_node("CanvasLayer/TabContainer").get_children()
	#Tactics is hard coded so it won't be included
	for tab in range(tabs.size() - 1):
		#Get the buttons in the specific tab
		currentMenu = tabs[tab].get_node("MarginContainer/GridContainer").get_children()
		#Only fill in as much as the moveset has
		for n in range(moveset[tab].size()):
			currentMenu[n].text = moveset[tab][n].name

func _process(_delta):#If player turn ever changes change current team to match the bool
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		team[i].menu.show()
		if Globals.attacking:
			nextTarget()
	else:
		team = enemyOrder
		opposing = playerOrder
		which = whichTypes.ENEMY
		target = targetTypes.SINGLE
		if not waiting:
			nextTarget()
	
	#Keep cursor on current active turn
	cursor.position = team[i].position + Vector2(-30,-30)	#Keep cursor on current active turn

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
	
	print(str(useMove.name))
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
				ESingleSelect(targetArray,team[i].data.attackData)
		
		targetTypes.GROUP:
			if not finished:
				targetArrayGroup = []
				establishGroups(targetArray)
			if playerTurn:
				for k in targetArrayGroup[groupIndex]:
					k.show()
				PGroupSelect(targetArrayGroup)
			else:
				pass
		
		targetTypes.SELF:
			targetArray = team
			index = i
			if playerTurn:
				targetArray[index].selected.show()
				PConfirmSelect()
				targetArray[index].selected.hide()
			else:
				pass
		
		_:
			if playerTurn:
				for k in targetArray:
					k.selected.show()
				PConfirmSelect()
				for k in targetArray:
					k.selected.hide() 
			else:
				pass

func establishGroups(targetting):
	for element in Globals.elementGroups:
		var tempChecking: Array = []
		for k in range(targetting.size()):
			if targetting[k].data.TempElement == element:
				tempChecking.append(targetting[k])
		if tempChecking.size() != 0:
			targetArrayGroup.append(tempChecking)
	print(targetArrayGroup)
	finished = true

#-----------------------------------------
#UI CONTROLS
#-----------------------------------------
func PSingleSelect(targetting):
	PConfirmSelect()
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
	targetArray[index].selected.show()

func PGroupSelect(targetting):
	PConfirmSelect()
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
			k.selected.show()

func PConfirmSelect():
	if Input.is_action_just_pressed("Accept"):
		pass
	if Input.is_action_just_pressed("Cancel"):
		pass

#-----------------------------------------
#ENEMY AI
#-----------------------------------------
func ESingleSelect(targetting,useMove):
	index = team[i].ERandomSingle(targetting)
	for times in useMove.HitNum:
		checkProperties(useMove,targetArray[index],team[i])
	waiting = true
	next_entity()

func EGroupSelect(_useMove):
	pass

func ESelfSelect(useMove):
	for times in useMove.HitNum:
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove,targetArray,index)

func EAllSelect(targetting,useMove):
	for k in range(targetting.size()):
		for times in useMove.HitNum:
			if useMove.property & 1 and useMove.property & 2:
				times += 1
			checkProperties(useMove,targetArray,k)

func ERandomSelect(targetting,useMove):
	for times in useMove.HitNum:
		index = team[i].ERandomSingle(targetting)
		checkProperties(useMove,targetArray,index)
		waiting = true
		$WaitTimer.start()

#-----------------------------------------
#UI BUTTONS
#-----------------------------------------
func _on_start_select(useMove):
	print(useMove.name)
	Globals.attacking = true
	target = findTarget(useMove)
	which = findWhich(useMove)

func _on_move_selected(useMove):
	await action(useMove)
	
	Globals.attacking = false
	team[i].secondaryTabs.hide()
	next_entity()

func _on_wait_selected():
	next_entity()

func _on_boost_selected():
	if Globals.attacking:
		targetArray[index].selected.hide()
		team[i].buffStat(targetArray[index],team[i].playerData.boostStat)
		Globals.attacking = false
		next_entity()
	else:
		Globals.attacking = true
		target = findTarget(team[i].playerData.boostMove)
		which = findWhich(team[i].playerData.boostMove)

func _on_scan_selected():
	pass
#-----------------------------------------
#USING MOVES
#-----------------------------------------
func action(useMove):
	var hits = useMove.HitNum
	
	match target:
		targetTypes.GROUP:
			var groupSize = targetArrayGroup[groupIndex].size()
			if groupSize == 1:
				hits *= 2
			
			for k in range(groupSize):
				if targetDied: #Array goes 1by1 so lower k and size by 1 to get back on track
					groupSize -= 1
					k -= 1
					targetDied = false
				await useAction(useMove,targetArrayGroup[groupIndex][k],team[i],hits)
		
		targetTypes.ALL:
			var groupSize = targetArray.size()
			for k in range(groupSize):
				if targetDied: #Array goes 1by1 so lower k and size by 1 to get back on track
					groupSize -= 1
					k -= 1
					targetDied = false
				await useAction(useMove,targetArray[k],team[i],hits)
		
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
	if move.property & 2:
		offense(move,targetting,user)
	if move.property & 4:
		offense(move,targetting,user)
	if move.property & 8:
		buffing(move,targetting,user)
	if move.property & 16:
		healing(move,targetting,user)
	if move.property & 32:
		aura(move)
	if move.property & 64:
		summon(move,user)
	if move.property & 128:
		user.applyNegativeAilment(move,targetting,user)
	if move.property & 256:
		pass
	
	var tween = targetting.HPBar.create_tween()
	tween.connect("finished", _on_tween_completed)
	
	targetting.displayQuick(user.feedback)
	targetting.HPtext.text = str("HP: ",targetting.currentHP)
	tween.tween_property(targetting.HPBar, "value",
	int(100 * float(targetting.currentHP) / float(targetting.data.MaxHP)),tweenTiming).set_trans(Tween.TRANS_BOUNCE)
	
	print(user.feedback)
	user.feedback = ""
	checkHP()

func offense(move,targetting,user):
	targetting.selected.hide()
	if move.property & 1:
		targetting.currentHP -= user.attack(move, targetting, user,"Physical")
	if move.property & 2:
		targetting.currentHP -= user.attack(move, targetting, user,"Ballistic")
	elif move.property & 4:
		targetting.currentHP -= user.BOMB(move, targetting)
	
	if targetting.currentHP <= 0:
		targetting.currentHP = 0

func healing(move,targetting,user):
	targetting.selected.hide()
	print(user.healHP(move, targetting))
	if move.Healing != 0:
		targetting.currentHP += user.healHP(move, targetting)
		if targetting.currentHP >= targetting.data.MaxHP:
			targetting.currentHP = targetting.data.MaxHP
		targetting.HPtext.text = str("HP: ",targetting.currentHP)
		targetting.HPBar.value = int(100 * float(targetting.currentHP) / float(targetting.data.MaxHP))
	
	if move.HealedAilment != "None":
		user.healAilment(move, targetting)

func buffing(move,targetting,user):
	if move.BoostType == 0:
		user.buffStat(targetting,move.boostType)
	
	if move.Condition == 0:
		user.buffCondition(move,targetting)
	
	if move.ElementChange != null:
		user.buffElementChange(move,targetting,user)
	
	Globals.attacking = false
	targetting.selected.hide()

func aura(move):
	currentAura = move.Aura

func summon(_move,_user):
	pass

#-----------------------------------------
#MISC
#-----------------------------------------

#-----------------------------------------
#TURN END FUNCTIONS
#-----------------------------------------
func _on_tween_completed(): #For Enemy Turns and multihits, makes individual hits more visible
	print("stop")
	waiting = false

func next_entity():
	#If it's the player, their menu should be hidden
	if team[i].has_node("CanvasLayer"):
		team[i].menu.hide()
		team[i].firstButton.grab_focus()
	
	#Get to the next entity
	#If the current team's index is higher than the size, reset both indexes and switch teams
	i += 1
	if i > (team.size() - 1):
		i = 0
		j = 0
		index = 0
		playerTurn = !playerTurn
		
	else:
		if team[i].has_node("CanvasLayer"):
			team[i].menu.show()
	
	targetDied = false

func checkHP(): #Delete enemies, disable players and resize arrays as necessary also handles win and lose condition
	var defeatedPlayers = []
	var defeatedEnemies = []
	var InitialPsize = playerOrder.size()
	var InitialESize = enemyOrder.size()
	var lowerP = 0
	var lowerE = 0
	
	#Check which players and enemies are dead
	for player in playerOrder:
		if player.currentHP <= 0:
			targetDied = true
			defeatedPlayers.append(player)
			lowerP += 1
	for enemy in enemyOrder:
		if enemy.currentHP <= 0:
			print("Die")
			targetDied = true
			defeatedEnemies.append(enemy)
			lowerE += 1
	
	#Deal with them and their side's array accordingly
	for defeatedPlayer in defeatedPlayers:
		playerOrder.erase(defeatedPlayer)
		defeatedPlayer.modulate = Color(454545)
	for defeatedEnemy in defeatedEnemies:
		enemyOrder.erase(defeatedEnemy)
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
	groupIndex = 0
	target = null
	finished = false
	#Only Reset values if somone died
	#This lets the player mash a to attack the same guy a bunch until they die
	if InitialPsize != playerOrder.size() or InitialESize != enemyOrder.size():
		j = 0
		index = 0

func _on_timer_timeout():
	print("print")
