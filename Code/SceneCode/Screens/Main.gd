extends Node2D

@export var tweenTiming: float = .2 #Make the timing with the hits editable

#UI ELEMENTS
@onready var PlayerTPDisplay = $PlayerTP
@onready var PlayerTPText = $PlayerTP/Label
@onready var EnemyTPDisplay = $EnemyTP
@onready var EnemyTPText = $EnemyTP/Label
@onready var AuraFog = $Aura
@onready var AuraLabel = $Label
#AUDIO DESIGN
@onready var ElementSFX: Array[AudioStreamPlayer] = [%Fire, %Water, %Elec, %Slash, %Crush, %Pierce,
%Comet, %Light, %Aurora, %Aether]
@onready var NeutralSFX: Array[AudioStreamPlayer] = [%NeutralPhy, %NeutralBal, %NeutralBOMB]
@onready var BuffSFX: Array[AudioStreamPlayer] = [%BuffStat, %DebuffStat, %Condition, %EleChange]
@onready var AilmentSFX: Array[AudioStreamPlayer] = [%Overdrive, %Poison, %Reckless, %Exhausted, %Rust, %Dumbfounded]
@onready var ETCSFX: Array[AudioStreamPlayer] = [%Heal, %Aura, %Summon]
@onready var XSoftSFX: AudioStreamPlayer = %XSoft
@onready var DieSFX: AudioStreamPlayer = %Die
@onready var critSFXEffect = AudioServer.get_bus_effect(3,0)
#TURN MANAGERS
@onready var playerPositions = [$Players/Position1,$Players/Position2,$Players/Position3]
@onready var enemyPosition = [$Enemies/Position1,$Enemies/Position2,$Enemies/Position3]
@onready var enemyOrder: Array = []
@onready var playerOrder: Array = []

signal mainMenu
signal makeNoise(num)
signal playMusic(song)

#Make every player's menu
var playerScene: PackedScene = preload("res://Scene/Entities/Player.tscn")
var enemyScene: PackedScene = preload("res://Scene/Entities/enemy.tscn")
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
	RANDOMGROUP,
	TARGETTED,
	REVIVE,
	KO,
	NONE}
enum whichTypes {
	ENEMY,
	ALLY,
	BOTH}

#-----------------------------------------
#INTIALIZATION & PROCESS
#-----------------------------------------
func _ready(): #Assign current team according to starting bool
	Globals.currentAura = ""
	if Globals.currentSong != "":
		playMusic.emit(Globals.currentSong)
	
	for k in range(Globals.current_player_entities.size()): #Add player scenes as necessary
		var pNew = playerScene.instantiate()
		pNew.data = Globals.current_player_entities[k].duplicate()
		pNew.global_position = playerPositions[k].global_position
		pNew.playerNum = k
		$Players.add_child(pNew)
	
	for k in range(Globals.current_enemy_entities.size()): #Add enemy scenes as necessary
		var eNew = enemyScene.instantiate()
		eNew.data = Globals.current_enemy_entities[k].duplicate()
		eNew.global_position = enemyPosition[k].global_position
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
		entity.connect("xsoftSound", playXSoft)
		entity.connect("critical", setCrit)
		entity.connect("explode", blowUp)
	
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
		
		team[i].opposingCurrentTP = playerTP
		team[i].allyMaxTP = playerMaxTP
		team[i].opposingMaxTP = enemyMaxTP
		enemyAction = team[i].chooseMove(enemyTP, enemyOrder, playerOrder)
	
	everyone = playerOrder + enemyOrder
	setGroupEleMod()
	
	$Timers/Timer.set_paused(false) 
	$Timers/PostPhaseTimer.set_paused(false)

func movesetDisplay(player) -> void: #Format every player's menu to include the name of their moveset
	#get the player's complete moveset
	player.moveset = [player.attacks,player.skills,player.items,player.tactics]
	#Get the tab
	var tabs = player.get_node("CanvasLayer/TabContainer").get_children()
	var tpMod: float = 0.0
	
	if player.data.costBonus & 4: tpMod = player.data.TpCostMod
	
	for tab in range(tabs.size()):
		#Get the buttons in the specific tab
		var tabDescriptions = []
		var tabTPs = []
		currentMenu = tabs[tab].get_node("MarginContainer/GridContainer").get_children()
		#Only fill in as much as the moveset has
		for n in range(player.moveset[tab].size()):
			currentMenu[n].text = player.moveset[tab][n].name
			tabDescriptions.append(movesetDescription(player.moveset[tab][n],player,tab))
			tabTPs.append(SaveTPCosts(player.moveset[tab][n],tpMod))
		
		player.descriptions.append(tabDescriptions)
		player.TPArray.append(tabTPs)

func movesetDescription(moveset,player,n) -> String:
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
			var costText: String
			var modifier: float = 0.0
			var baseCost: int = 0
			if move.CostType == "HP" or move.CostType == "MaxHP":
				if player.data.costBonus & 1:
					modifier += player.data.HpCostMod
				baseCost = int(move.cost * player.data.MaxHP)
				costText = str("[color=red]"+ "HP: ",int(baseCost + baseCost*modifier), "[/color]")
			
			if move.CostType == "LP":
				if player.data.costBonus & 2:
					modifier += player.data.LpCostMod
				costText = str("[color=aqua]"+"LP: ",int(move.cost + move.cost*modifier), "[/color]")
			
			fullDesc = str(costText, desc, Elements, PhyElement, Power,)
			
		2: #Item Descriptions need to show #ofItems/MaxItems
			var itemMax = moveset.maxItems #Moveset has Item Specifics, move has thier attack data
			desc = str("/",itemMax,"]"+"[/i]",move.description)
			
			fullDesc = str(desc, Elements, PhyElement, Power)
		_:
			fullDesc = str(move.description)
			if move.name == "Boost":
				fullDesc = str(fullDesc, HelperFunctions.BoostTranslation(player.playerData.boostStat))
	
	return fullDesc

func SaveTPCosts(moveset, preMod) -> int:
	var move = moveset
	if move is Item:
		move = moveset.attackData
	var TPCost = move.TPCost + (preMod * move.TPCost)
	return TPCost

func initializeTP(players=false) -> void: #Make and remake max TPs when an entiy is gone or enters
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

func setGroupEleMod() -> void:
	Globals.groupEleMod = 0.0
	for entity in everyone:
		Globals.groupEleMod += entity.data.groupElementMod

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

#-----------------------------------------
#TARGETTING MANAGERS
#-----------------------------------------
func findTarget(useMove) -> targetTypes:
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
		"RandomGroup":
			returnTarget = targetTypes.RANDOMGROUP
		"KO":
			returnTarget = targetTypes.KO
		"None":
			returnTarget = targetTypes.NONE
	
	return returnTarget

func findWhich(useMove) -> whichTypes:
	var returnWhich
	match useMove.Which:
		"Enemy":
			returnWhich = whichTypes.ENEMY
		"Ally":
			returnWhich = whichTypes.ALLY
		"Both":
			returnWhich = whichTypes.BOTH
	
	return returnWhich

func checkForTargetted(targetting) -> Array:
	var trueTargetArray = []
	
	for entity in targetting:
		if entity.checkCondition("Targetted", entity):
			trueTargetArray.append(entity)
			target = targetTypes.TARGETTED
	
	if trueTargetArray.size() == 0:
		return targetArray
	else:
		return trueTargetArray

func nextTarget(TeamSide = team,OpposingSide = opposing) -> void:
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
		
		targetTypes.KO:
			if playerTurn:
				if Globals.attacking:
					targetArray = deadPlayers
					PSingleSelect(targetArray)
			else:
				waiting = true
				targetArray = deadEnemies
				EfinishSelecting(enemyAction)
		
		(targetTypes.ALL or targetTypes.RANDOM or targetTypes.TARGETTED):
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)
		
		targetTypes.RANDOMGROUP:
			targetArrayGroup = []
			if which == whichTypes.BOTH:
				targetArrayGroup = establishGroups(TeamSide) + establishGroups(OpposingSide)
			else:
				targetArrayGroup = establishGroups(targetArray)
			if playerTurn:
				if Globals.attacking:
					PAllSelect(targetArray)
			else:
				waiting = true
				EfinishSelecting(enemyAction)

func establishGroups(targetting) -> Array:
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
func PSingleSelect(targetting) -> void:
	var playerSize = playerOrder.size()
	var enemySize = enemyOrder.size()
	if which != whichTypes.BOTH:#Simple line movement
		if Input.is_action_just_pressed("Left"):
			makeNoise.emit(2)
			targetArray[index].selected.hide()
			index -= 1
			if index < 0:
				index = targetting.size() - 1
		if Input.is_action_just_pressed("Right"):
			makeNoise.emit(2)
			targetArray[index].selected.hide()
			index += 1
			if index > (targetting.size() - 1):
				index = 0
	
	if which == whichTypes.BOTH: #Moves like a Grid
		if Input.is_action_just_pressed("Left"):
			makeNoise.emit(2)
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
			makeNoise.emit(2)
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
			makeNoise.emit(2)
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

func PGroupSelect(targetting) -> void:
	#print(targetArrayGroup[groupIndex])
	if Input.is_action_just_pressed("Left"):
		makeNoise.emit(2)
		for k in targetArrayGroup[groupIndex]:
			k.selected.hide()
		groupIndex -= 1
		
		if groupIndex < 0:
			groupIndex = targetting.size() - 1
		print(targetArrayGroup[groupIndex])
	
	if Input.is_action_just_pressed("Right"):
		makeNoise.emit(2)
		for k in targetArrayGroup[groupIndex]:
			k.selected.hide()
		groupIndex += 1
		
		if groupIndex > (targetting.size() - 1):
			groupIndex = 0

	for k in targetArrayGroup[groupIndex]:
		PConfirmSelect(k)

func PConfirmSelect(targetting) -> void:
	targetting.selected.show()

func PAllSelect(targetting) -> void:
	for k in targetting:
		k.selected.show()

func stopScanning() -> void:
	if Input.is_action_just_pressed("Accept"):
		makeNoise.emit(1)
		var scanBoxTween
		scanning = false
		
		for enemy in enemyOrder:
			if enemy.gettingScanned == true:
				scanBoxTween = enemy.create_tween()
				scanBoxTween.tween_property(enemy.ScanBox, "modulate", Color.TRANSPARENT,1)
		next_entity()

func _on_cancel_selected() -> void:
	makeNoise.emit(1)
	Globals.attacking = false
	index = 0
	for k in range(everyone.size()):
		everyone[k].selected.hide()

#-----------------------------------------
#ENEMY SELCTING
#-----------------------------------------
func EfinishSelecting(useMove) -> void:
	enemyTP -= team[i].payCost(useMove)
	TPChange(false)
	waiting = true
	
	team[i].displayMove(useMove)
	await action(useMove)
	$Timers/Timer.start()

#-----------------------------------------
#UI BUTTONS
#-----------------------------------------
func _on_start_select(useMove) -> void:
	Globals.attacking = true
	target = findTarget(useMove)
	which = findWhich(useMove)

func _on_move_selected(useMove) -> void:
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
func action(useMove) -> void:
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
		
		targetTypes.RANDOMGROUP:
			for m in range(hits):
				print(targetArray)
				print(targetArrayGroup)
				var randomIndex = randi()%targetArrayGroup.size()
				var groupSize = targetArrayGroup[randomIndex].size()
				var offset = 0
				var groupHit = 1
				
				if groupSize == 1 and useMove.name != "Switch Gear":
					print("RANDOM TARGET GROUP ON 1",targetArrayGroup[randomIndex])
					groupHit = 2
				
				for k in range(groupSize):
					if targetDied: #Array goes 1by1 so lower k and size by 1 to get back on track
						targetArrayGroup = establishGroups(targetArray) #Resestablish Groups
						offset += 1
						print(targetArray)
						print(k - offset)
						print(targetArrayGroup[randomIndex][k - offset])
						targetDied = false
					
					await useAction(useMove,targetArrayGroup[randomIndex][k - offset],team[i],groupHit)
		
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

func useAction(useMove, targetting, user, hits) -> void:
	var times = 0
	while times < hits:
		if targetDied:
			targetDied = false
			break
		
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		
		if user.midTurnAilments(user.data.Ailment):
			checkProperties(useMove,targetting,user,times)
		
		times += 1
		await get_tree().create_timer(.5).timeout

func checkProperties(move,targetting,user,hitNum) -> void:
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

func TPChange(player = true) -> void:
	var TPtween
	if player:
		TPtween = $PlayerTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(playerTP) / float(playerMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
	else:
		TPtween = $EnemyTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
		TPtween.tween_property(EnemyTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)

func blowUp(user) -> void:
	user.currentHP -= user.data.MaxHP * .5
	user.HPtext.text = str("HP: ",user.currentHP)
	user.tweenDamage(user,tweenTiming,str(user.name,"'s weapon blew up?!"))

#-----------------------------------------
#CHECK PROPERTY FUNCTIONS
#-----------------------------------------
func offense(move,targetting,user) -> void:
	targetting.selected.hide()
	var damage
	if move.property & 1:
		damage = user.attack(move, targetting, user,"Physical")
	if move.property & 2:
		damage = user.attack(move, targetting, user,"Ballistic")
	elif move.property & 4:
		damage = user.BOMB(move, targetting, user)
	targetting.currentHP -= damage
	
	if user.data.calcBonus & 1:
		var drain = user.drain(damage, user.data.drainCalcAmmount)
		user.currentHP += drain
		user.currentHP = clamp(user.currentHP, 0, user.data.MaxHP)
		user.HPtext.text = str("HP: ",user.currentHP)
		user.tweenDamage(user,tweenTiming,str("Drained ", drain,"HP"))
	if user.data.miscCalc == "LPDrain":
		var drain = user.drain(damage, .15)
		user.currentLP += drain
		user.currentLP = clamp(user.currentLP, 0, user.data.specificData.MaxLP)
		user.LPtext.text = str("LP: ",user.currentLP)
		user.tweenDamage(user,tweenTiming,str("Drained ", drain,"LP"))
	
	
	if targetting.currentHP <= 0:
		targetting.currentHP = 0

func healing(move,targetting,user) -> void:
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
	
	if move.healing != 0:
		targetting.currentHP += user.healHP(move, targetting)
		targetting.currentHP = clamp(targetting.currentHP, 0, targetting.data.MaxHP)
		targetting.HPtext.text = str("HP: ",targetting.currentHP)
	
	if move.HealedAilment != "None":
		user.healAilment(move, targetting)

func buffing(move,targetting,user) -> void:
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

func aura(move) -> void:
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

func summon(_move,_user) -> void:
	pass

func ailment(move,targetting,user) -> void:
	if move.Ailment == "Overdrive" or move.Ailment == "Protected":
		user.applyPositiveAilment(move,targetting)
	elif move.Ailment != "PhySoft" and move.Ailment != "EleSoft":
		user.applyNegativeAilment(move,targetting,user)
	else:
		user.applyXSoft(move,targetting,user)

func determineFunction(move,reciever,user,hitNum) -> void:
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
func next_entity() -> void:
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
				team[i].opposingCurrentTP = playerTP
				team[i].allyMaxTP = playerMaxTP
				team[i].opposingMaxTP = enemyMaxTP
				enemyAction = team[i].chooseMove(enemyTP,enemyOrder, playerOrder)
				target = findTarget(enemyAction)
				print(target)
				which = findWhich(enemyAction)
		
		startSwitchPhase()
		targetDied = false

func overdriveTurnManager() -> void:
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
				enemyAction = team[i].chooseMove(enemyTP,enemyOrder, playerOrder)
				target = findTarget(enemyAction)
				which = findWhich(enemyAction)

func startSwitchPhase() -> void:
	if actionNum <= 0:
		waiting = true
		$Timers/PostPhaseTimer.start()
		playerTurn = not playerTurn
		endPhaseCheck()

func switchPhase() -> void:
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
		enemyAction = enemyOrder[0].chooseMove(enemyTP,enemyOrder, playerOrder)
		
		enemyTP += int(float(enemyMaxTP) *.5)
		var TPtween = $EnemyTP.create_tween()#TP management must be handled here
		var newValue = int(100*(float(enemyTP) / float(enemyMaxTP)))
		TPtween.tween_property(PlayerTPDisplay, "value", newValue,.2).set_trans(Tween.TRANS_CIRC)
		Globals.attacking = false
		actionNum = enemyOrder.size()

func checkCosts(player) -> void: #Check if the player can afford certain moves, if they can't disable those buttons
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

func checkCostsMini(player, pay, cost, move, menuIndex, searchingItem = false) -> bool:
	var buttonIndex = player.moveset[menuIndex].find(move)
	var use
	var canpay = true
	match cost:
		"TP":
			if searchingItem:
				use = Globals.getTPCost(move.attackData,player)
			else:
				use = Globals.getTPCost(move,player)
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

func endPhaseCheck() -> void:
	for k in range(opposing.size()):
		opposing[k].statBoostHandling()
		var holdAilment = opposing[k].ailmentCategory(opposing[k])
		if holdAilment != "Mental" or holdAilment != "Chemical":
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

#Delete enemies, disable players and resize arrays as necessary also handles win and lose condition
func checkHP() -> void:
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

func endScreen(playerWin) -> void:
	var endScreenTween = $".".create_tween()
	endScreenTween.set_parallel(true)
	
	if playerWin:
		endScreenTween.tween_property($EndScreen, "modulate", Color("0000afae"),1.5)
	else:
		endScreenTween.tween_property($EndScreen, "modulate", Color("ce000030"),1.5)
		$EndScreen/RichTextLabel.text = "You Lose"
	
	endScreenTween.tween_property($EndScreen/RichTextLabel, "modulate", Color("000000"),1.5)
	endScreenTween.tween_property($EndScreen/Button, "modulate", Color("ffffff"),1.5)
	playMusic.emit("stop")
	$EndScreen/Button.show()

func _on_timer_timeout() -> void:
	waiting = false
	team[i].hideDesc()
	if not fightOver:
		next_entity()

func _on_post_phase_timer_timeout() -> void:
	waiting = false
	switchPhase()

func _on_button_pressed() -> void:
	mainMenu.emit()

#-----------------------------------------
#AUDIO
#-----------------------------------------
func playButton(value) -> void:
	if value:
		makeNoise.emit(0)
	else:
		makeNoise.emit(1)

func playMenu() -> void:
	makeNoise.emit(2)

func playAttackMove(move,property) -> void:
	var playEffect = null
	var usePhy = move.phyElement
	if move.name == "Attack":
		usePhy = team[i].data.phyElement
	
	#PRIORITY: Special Element, Phy Element, Regular Element, Property
	for k in range(6,10):
		if Globals.elementTypes[k] == usePhy:
			playEffect = ElementSFX[k]
	for k in range(3,6):
		if Globals.elementTypes[k] == usePhy:
			playEffect = ElementSFX[k]
	if playEffect == null:
		for k in range(0,3):
			if Globals.elementTypes[k] == move.element:
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

func playBuffStat(move) -> void:
	if move.BoostAmmount > 0:
		BuffSFX[0].play()
	elif move.BoostAmmount < 0:
		BuffSFX[1].play()

func playAilment(type) -> void:
	for k in range(Globals.AilmentTypes.size()):
		if type == Globals.AilmentTypes[i]:
			AilmentSFX[i].play()
			break

func playXSoft() -> void:
	XSoftSFX.play()

func setCrit() -> void:
	critSFXEffect = true
