extends Node2D

#Main Scene is a battle so this is where initial order is decided and managed
@export var tweenTiming: float = .2 #Make the timing with the hits editable

#UI ELEMENTS
@onready var PlayerTPDisplay = $PlayerTP
@onready var PlayerTPText = $PlayerTP/Label
@onready var EnemyTPDisplay = $EnemyTP
@onready var EnemyTPText = $EnemyTP/Label
@onready var AuraFog = $Aura
@onready var AuraLabel = $Label
#AUDIO DESIGN
@onready var music: AudioStreamPlayer = $Music
@onready var SFX: Array[AudioStreamPlayer] = [$SFX/Confirm,$SFX/Back,$SFX/Menu]
@onready var ElementSFX: Array[AudioStreamPlayer] = [$MoveSFX/Elements/Fire,$MoveSFX/Elements/Water,$MoveSFX/Elements/Elec,$MoveSFX/Elements/Slash,$MoveSFX/Elements/Crush,$MoveSFX/Elements/Pierce]
@onready var NeutralSFX: Array[AudioStreamPlayer] = [$MoveSFX/Elements/NeutralPhy,$MoveSFX/Elements/NeutralBal,$MoveSFX/Elements/NeutralBOMB]
@onready var BuffSFX: Array[AudioStreamPlayer] = [$MoveSFX/Buff/BuffStat,$MoveSFX/Buff/DebuffStat,$MoveSFX/Buff/Condition,$MoveSFX/Buff/EleChange]
@onready var AilmentSFX: Array[AudioStreamPlayer] = [$MoveSFX/Ailment/Overdrive,$MoveSFX/Ailment/Poison,$MoveSFX/Ailment/Reckless,$MoveSFX/Ailment/Exhausted,$MoveSFX/Ailment/Rust]
@onready var ETCSFX: Array[AudioStreamPlayer] = [$MoveSFX/ETC/Heal,$MoveSFX/ETC/Aura,$MoveSFX/ETC/Summon]
@onready var DieSFX: AudioStreamPlayer = $SFX/Die
@onready var critSFXEffect = AudioServer.get_bus_effect(3,0)
#TURN MANAGERS
@onready var playerPositions = [$Players/Position1,$Players/Position2,$Players/Position3]
@onready var enemyPosition = [$Enemies/Position1,$Enemies/Position2,$Enemies/Position3]
@onready var enemyOrder: Array = []
@onready var playerOrder: Array = []

#Make every player's menu
var mainMenuScene: PackedScene = preload("res://Scene/MainMenu.tscn")
var playerScene: PackedScene = preload("res://Scene/Player.tscn")
var enemyScene: PackedScene = preload("res://Scene/enemy.tscn")
var groups = ["Attack","Skills","Items","Tactics"]
var currentMenu
#Hold current enemy's action
var enemyAction
var actionNum: int = 0
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
var deadPlayers: Array = []
var deadEnemies: Array = []
var playerTurn: bool = Globals.playerFirst #Starting Bool
var waiting: bool = false
var overdriveTurn: bool = false
var finished: bool = false
var targetDied: bool = false
var scanning: bool = false
var fightOver: bool = false
#Battle Stats
var playerTP: int = 0
var playerMaxTP: int = 0
var enemyTP: int = 0
var enemyMaxTP: int = 0
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
	REVIVE,
	KO,
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
	Globals.currentAura = ""
	if Globals.currentSong != "":
		music.set_stream(load(Globals.currentSong))
		music.play()
	
	for k in range(Globals.current_player_entities.size()): #Add player scenes as necessary
		var pNew = playerScene.instantiate()
		pNew.data = Globals.current_player_entities[k].duplicate()
		pNew.position = playerPositions[k].position
		pNew.playerNum = k
		$Players.add_child(pNew)
	
	for k in range(Globals.current_enemy_entities.size()): #Add enemy scenes as necessary
		var eNew = enemyScene.instantiate()
		eNew.data = Globals.current_enemy_entities[k].duplicate()
		eNew.position = enemyPosition[k].position
		$Enemies.add_child(eNew)
	
	for player in get_tree().get_nodes_in_group("Players"):
		player.currentHP = player.data.MaxHP
		playerMaxTP += player.data.MaxTP
		playerOrder.append(player)
		movesetDisplay(player)
		
		player.connect("startSelect", _on_start_select)
		player.connect("moveSelected", _on_move_selected)
		player.connect("cancel", _on_cancel_selected)
		player.menu.connect("confirm",playButton)
		player.menu.connect("move",playMenu)
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.currentHP = enemy.data.MaxHP
		enemyMaxTP += enemy.data.MaxTP
		enemyOrder.append(enemy)
	
	everyone = playerOrder + enemyOrder
	
	for entity in everyone:
		entity.connect("ailmentSound",playAilment)
		entity.connect("critical", setCrit)
	
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
		enemyAction = team[i].chooseMove(enemyTP,playerOrder,enemyOrder)
	
	everyone = playerOrder + enemyOrder
	$Timers/Timer.set_paused(false) #Should've done this to avoid so much ;-; It took so long to figure out I DESERVE TO USE THIS
	$Timers/PostPhaseTimer.set_paused(false)

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
	if not fightOver:
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
		"KO":
			returnTarget = targetTypes.KO
		"None":
			returnTarget = targetTypes.NONE
	
	print(returnTarget)
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
			if which == whichTypes.BOTH:
				targetArrayGroup = establishGroups(TeamSide) + establishGroups(OpposingSide)
			else:
				targetArrayGroup = establishGroups(targetArray)
			
			if playerTurn:
				if Globals.attacking:
					for k in targetArrayGroup[groupIndex]:
						k.show()
					PGroupSelect(targetArrayGroup)
			else:
				waiting = true
				targetArrayGroup = []
				targetArrayGroup = establishGroups(targetArray)
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
		
		targetTypes.KO:
			if playerTurn:
				if Globals.attacking:
					targetArray = deadPlayers
					PSingleSelect(targetArray)
			else:
				waiting = true
				targetArray = deadEnemies
				EfinishSelecting(enemyAction)
		
		targetTypes.TARGETTED:
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)

func establishGroups(targetting):
	var returnGroup: Array = []
	
	for element in Globals.elementGroups:
		var tempChecking: Array = []
		for k in range(targetting.size()):
			
			if targetting[k].data.TempElement == element:
				tempChecking.append(targetting[k])
		
		if tempChecking.size() != 0:
			returnGroup.append(tempChecking)
	
	finished = true
	return returnGroup

#-----------------------------------------
#PLAYERSELECTING // UI CONTROLS
#-----------------------------------------
func PSingleSelect(targetting):
	var playerSize = playerOrder.size()
	var enemySize = enemyOrder.size()
	if which != whichTypes.BOTH:#Simple line movement
		if Input.is_action_just_pressed("Left"):
			SFX[2].play()
			targetArray[index].selected.hide()
			index -= 1
			if index < 0:
				index = targetting.size() - 1
		if Input.is_action_just_pressed("Right"):
			SFX[2].play()
			targetArray[index].selected.hide()
			index += 1
			if index > (targetting.size() - 1):
				index = 0
	
	if which == whichTypes.BOTH: #Moves like a Grid
		if Input.is_action_just_pressed("Left"):
			SFX[2].play()
			targetArray[index].selected.hide()
			index -= 1
			if index < 0:
				index = playerSize - 1
			elif index == playerSize - 1:
				index = targetArray.size() - 1
				#If there is one enemy pressing left will return to the player
				if enemySize == 1:
					index = 0
		
		if Input.is_action_just_pressed("Right"):
			SFX[2].play()
			targetArray[index].selected.hide()
			index += 1
			if index > (targetArray.size() - 1) and enemySize != 1:
				index = playerSize
			elif targetArray[index - 1].has_node("CanvasLayer"):
				if (index == playerSize):
					index = 0
			elif (enemySize == 1): #If there is one enemy pressing right will return to the player
				index = playerSize - 1
			
		if Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("Down"):
			SFX[2].play()
			targetArray[index].selected.hide()
			if targetArray[index].has_node("CanvasLayer"):
				if index > (enemySize - 1):
					index += enemySize
					if targetArray[index].has_node("CanvasLayer"): #just in case
						index += 1
				else:
					index += playerSize
			
			else:
				if (index - 3) < (playerSize - 1):
					index -= playerSize
				else:
					index -= enemySize
	
	PConfirmSelect(targetArray[index])

func PGroupSelect(targetting):
	#print(targetArrayGroup[groupIndex])
	if Input.is_action_just_pressed("Left"):
		SFX[2].play()
		for k in targetArrayGroup[groupIndex]:
			k.selected.hide()
		groupIndex -= 1
		
		if groupIndex < 0:
			groupIndex = targetting.size() - 1
		print(targetArrayGroup[groupIndex])
	
	if Input.is_action_just_pressed("Right"):
		SFX[2].play()
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
		SFX[1].play()
		var scanBoxTween
		scanning = false
		
		for enemy in enemyOrder:
			if enemy.gettingScanned == true:
				scanBoxTween = enemy.create_tween()
				scanBoxTween.tween_property(enemy.ScanBox, "modulate", Color.TRANSPARENT,1)
		next_entity()

func _on_cancel_selected():
	SFX[1].play()
	Globals.attacking = false
	index = 0
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
	$Timers/Timer.start()

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
	if not scanning and not fightOver:
		next_entity()

#-----------------------------------------
#USING MOVES
#-----------------------------------------
func action(useMove):
	var hits = useMove.HitNum
	
	match target:
		targetTypes.GROUP:
			print(targetArray)
			print(targetArrayGroup)
			
			var groupSize = targetArrayGroup[groupIndex].size()
			var offset = 0
			if groupSize == 1 and useMove.name != "Switch Gear":
				hits *= 2
			
			for k in range(groupSize):
				if targetDied: #Array goes 1by1 so lower k and size by 1 to get back on track
					targetArrayGroup = establishGroups(targetArray) #Resestablish Groups
					offset += 1
					print(targetArray)
					print(k - offset)
					print(targetArrayGroup[groupIndex][k - offset])
					targetDied = false
				
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
				if targetArray.size() != 0:
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
		
		if user.midTurnAilments(user.data.Ailment, Globals.currentAura):
			checkProperties(useMove,targetting,user,times)
		
		times += 1
		await get_tree().create_timer(.5).timeout

func useActionRandom(useMove, targetting, user, hits):
	var times = 0
	while times < hits:
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove,targetting,user,times)
		times += 1
		await get_tree().create_timer(1).timeout

func checkProperties(move,targetting,user,hitNum):
	if move.property & 256: #Misc first allows cetain changes before attacks
		determineFunction(move,targetting,user,hitNum)
	if move.property & 1:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		playAttackMove(move,"Physical")
		await get_tree().create_timer(.4).timeout #Damage deserves a little more time to be seen
	if move.property & 2:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		playAttackMove(move,"Ballistic")
		await get_tree().create_timer(.4).timeout
	if move.property & 4:
		offense(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		playAttackMove(move,"BOMB")
		await get_tree().create_timer(.4).timeout
	if move.property & 8:
		buffing(move,targetting,user)
	if move.property & 16:
		healing(move,targetting,user)
		targetting.tweenDamage(targetting,tweenTiming,user.feedback)
		ETCSFX[0].play()
	if move.property & 32:
		aura(move)
		ETCSFX[1].play()
	if move.property & 64:
		summon(move,user)
		ETCSFX[2].play()
	if move.property & 128:
		ailment(move,targetting,user)
	
	checkHP()
	critSFXEffect = false

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
		targetting.currentHP -= user.attack(move, targetting, user,"Physical",Globals.currentAura)
	if move.property & 2:
		targetting.currentHP -= user.attack(move, targetting, user,"Ballistic",Globals.currentAura)
	elif move.property & 4:
		targetting.currentHP -= user.BOMB(move, targetting)
	
	if targetting.currentHP <= 0:
		targetting.currentHP = 0

func healing(move,targetting,user):
	targetting.selected.hide()
	
	if move.revive:
		targetting.healKO(targetting)
		targetting.modulate = Color.WHITE
		if targetting.has_node("CanvasLayer"):
			if playerOrder.size() != 1 or targetting.playerNum == 0:
				playerOrder.insert(targetting.playerNum,targetting)
				print(team)
				actionNum += 1
			else:
				playerOrder.append(targetting)
		else:
			pass
	
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
		playBuffStat(move)
	elif user.has_node("CanvasLayer"):
		if user.playerData.boostStat != null and move.BoostAmmount != 0:
			user.buffStat(targetting,user.playerData.boostStat,move.BoostAmmount)
			playBuffStat(move)
	
	if move.Condition != 0 and move.Condition != null:
		user.buffCondition(move,targetting)
		BuffSFX[2].play()
	
	if move.ElementChange != "None" and move.ElementChange != null and move.ElementChange != "":
		user.buffElementChange(move,targetting,user)
		BuffSFX[3].play()
	
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
			Globals.currentAura = ""
		"BodyBroken":
			AuraFog.modulate = Color("#ffa5ff21")
			AuraLabel.text = "BodyBreak!"
			Globals.currentAura = "BodyBroken"
		"WillWrecked":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "WillWreck!"
			Globals.currentAura = "WillWrecked"
		"LowTicks":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "LowTick!"
			Globals.currentAura = "LowTicks"
		"CritDouble":
			AuraFog.modulate = Color("#2ee8f221")
			AuraLabel.text = "CritsChanceDoubled!"
			Globals.currentAura = "CritDouble"

func summon(_move,_user):
	pass

func ailment(move,targetting,user):
	if move.Ailment == "Overdrive" or move.Ailment == "Protected":
		user.applyPositiveAilment(move,targetting)
	elif move.Ailment != "PhySoft" and move.Ailment != "EleSoft":
		user.applyNegativeAilment(move,targetting,user)
	else:
		user.applyXSoft(move,targetting,user)

func determineFunction(move,reciever,user,hitNum):
	match move.name:
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
			reciever.HPBar.show()
		"Gatling Volley":
			if hitNum == 0:
				user.buffElementChange(move,user,reciever)
				BuffSFX[3].play()
		"Whim Berry":
			MiscFunctions.miscFunWhimBerry(reciever)
			ETCSFX[0].play()

#-----------------------------------------
#TURN END FUNCTIONS
#-----------------------------------------
func next_entity():
	if overdriveTurn: #Return things to normal
		if team[i].has_node("CanvasLayer"):
			team[i].menu.hide()
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
				team[i].selectedAgain.emit()
			else:
				enemyAction = team[i].chooseMove(enemyTP,playerOrder,enemyOrder)
				target = findTarget(enemyAction)
				print(target)
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
				team[i].firstButton.grab_focus()
			else:
				enemyAction = team[i].chooseMove(enemyTP,playerOrder,enemyOrder)
				target = findTarget(enemyAction)
				which = findWhich(enemyAction)

func startSwitchPhase():
	if actionNum <= 0:
		waiting = true
		$Timers/PostPhaseTimer.start()
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
		playerOrder[0].selectedAgain.emit()
		
		var TPtween = $PlayerTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(playerTP) / float(playerMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
		actionNum = playerOrder.size()
		print(actionNum)
	
	else:
		team = enemyOrder
		opposing = playerOrder
		enemyAction = enemyOrder[0].chooseMove(enemyTP,playerOrder,enemyOrder)
		
		enemyTP += int(float(enemyMaxTP) *.5)
		var TPtween = $EnemyTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
		Globals.attacking = false
		actionNum = enemyOrder.size()

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
					if move.name != "Wait": #Wait should always be availible
						checkCostsMini(player, playerTP, "TP", move, menuIndex)

func checkCostsMini(player, pay, cost, move, menuIndex, searchingItem = false):
	var buttonIndex = player.moveset[menuIndex].find(move)
	var use
	var canpay = true
	match cost:
		"TP":
			if searchingItem:
				use = Globals.getTPCost(move.attackData,player,Globals.currentAura)
			else:
				use = Globals.getTPCost(move,player,Globals.currentAura)
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
					player.targetCount -= 1
				else:
					player.removeCondition("Targetted",player)
		
	else:
		for enemy in enemyOrder:
			if enemy.checkCondition("Targetted", enemy):
				if enemy.targetCount != 0:
					enemy.targetCount -= 1
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
		defeatedPlayer.data.KO = true
		deadPlayers.append(defeatedPlayer)
		defeatedPlayer.modulate = Color(454545)
		defeatedPlayer.reset()
		DieSFX.play()
		initializeTP(true)
		TPChange()
	
	for defeatedEnemy in defeatedEnemies:
		enemyOrder.erase(defeatedEnemy)
		if defeatedEnemy.enemyData.Revivable:
			defeatedEnemy.data.KO = true
			deadEnemies.append(defeatedEnemy)
			defeatedEnemy.modulate = Color(454545)
			defeatedEnemy.reset()
		else:
			defeatedEnemy.queue_free()
		DieSFX.play()
		initializeTP()
		TPChange(false)
	
	#Win condition
	if enemyOrder.size() == 0:
		fightOver = true
		team[i].menu.hide()
		endScreen(true)
		return
	
	if playerOrder.size() == 0:
		fightOver = true
		endScreen(false)
		return
	
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

func endScreen(playerWin):
	var endScreenTween = $".".create_tween()
	endScreenTween.set_parallel(true)
	
	if playerWin:
		endScreenTween.tween_property($EndScreen, "modulate", Color("0000afae"),1.5)
	else:
		endScreenTween.tween_property($EndScreen, "modulate", Color("ce000030"),1.5)
		$EndScreen/RichTextLabel.text = "You Lose"
	
	endScreenTween.tween_property($EndScreen/RichTextLabel, "modulate", Color("000000"),1.5)
	endScreenTween.tween_property($EndScreen/Button, "modulate", Color("ffffff"),1.5)
	endScreenTween.tween_property(music,"volume_db",-80,5)
	$EndScreen/Button.show()

func _on_timer_timeout():
	waiting = false
	team[i].hideDesc()
	if not fightOver:
		next_entity()

func _on_post_phase_timer_timeout():
	waiting = false
	switchPhase()

func _on_button_pressed():
	get_tree().change_scene_to_packed(mainMenuScene)

#-----------------------------------------
#AUDIO
#-----------------------------------------
func playButton(value):
	if value:
		SFX[0].play()
	else:
		SFX[1].play()

func playMenu():
	SFX[2].play()

func playAttackMove(move,property):
	var playEffect = null
	var usePhy = move.phyElement
	if move.name == "Attack":
		usePhy = team[i].data.phyElement
	
	for k in range(3,6):
		if Globals.XSoftTypes[k] == usePhy:
			playEffect = ElementSFX[k]
	if playEffect == null:
		for k in range(0,3):
			if Globals.XSoftTypes[k] == move.element:
				playEffect = ElementSFX[k]
	
	if playEffect == null:
		match property:
			"Physical":
				playEffect = NeutralSFX[0]
			"Ballistic":
				playEffect = NeutralSFX[1]
			_:
				playEffect = NeutralSFX[2]
	
	playEffect.play()

func playBuffStat(move):
	if move.BoostAmmount > 0:
		BuffSFX[0].play()
	elif move.BoostAmmount < 0:
		BuffSFX[1].play()

func playAilment(type):
	for k in range(Globals.AilmentTypes.size()):
		if type == Globals.AilmentTypes[i]:
			AilmentSFX[i].play()
			break

func setCrit():
	critSFXEffect = true
