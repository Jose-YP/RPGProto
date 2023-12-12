extends Node2D

#Main Scene is a battle so this is where initial order is decided and managed
@export var playerTurn: bool = true #Starting Bool
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
var team: Array = []
var opposing: Array = []
var targetArray: Array = []
var attacking: bool = false
var waiting: bool = false
#Determines which targetting system to use
var target
var which
enum targetTypes {SINGLE,
	GROUP,
	SELF,
	ALL,
	RANDOM,
	NONE}
enum whichTypes {ENEMY,
	ALLY,
	BOTH
}

#-----------------------------------------
#INTIALIZATION & PROCESS
#-----------------------------------------
func _ready(): #Assign current team according to starting bool
	for player in get_tree().get_nodes_in_group("Players"):
		player.currentHP = player.data.MaxHP
		playerOrder.append(player)
		movesetDisplay(player)
		
		player.connect("wait", _on_wait_selected)
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

func _process(_delta):
	#If player turn ever changes change current team to match the bool
	#Keep cursor on current active turn
	if playerTurn:
		team = playerOrder
		opposing = enemyOrder
		team[i].menu.show()
		if attacking:
			nextTarget()
	else:
		team = enemyOrder
		opposing = playerOrder
		which = whichTypes.ENEMY
		target = targetTypes.SINGLE
		if not waiting:
			nextTarget()
	
	#Keep cursor on current active turn
	cursor.position = team[i].position + Vector2(-30,-30)

#-----------------------------------------
#TARGETTING MANAGERS
#-----------------------------------------
func nextTarget():
	match which:
		whichTypes.ENEMY:
			targetArray = opposing
		whichTypes.ALLY:
			print("Ally")
			targetArray = team
		whichTypes.BOTH:
			targetArray = team + opposing
	match target:
		targetTypes.SINGLE:
			if playerTurn:
				targetArray[index].selected.show()
				PSingleSelect(targetArray)
			else:
				ESingleSelect(targetArray,team[i].data.attackData)
		targetTypes.RANDOM:
			pass
		targetTypes.GROUP:
			pass
		targetTypes.SELF:
			pass
		targetTypes.ALL:
			pass

#-----------------------------------------
#UI CONTROLS
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
	targetArray[index].selected.show()

#-----------------------------------------
#ENEMY AI
#-----------------------------------------
func ESingleSelect(targetting,useMove):
	index = team[i].ERandomSingle(targetting)
	for times in useMove.HitNum:
		checkProperties(useMove)
	waiting = true
	$WaitTimer.start()

#-----------------------------------------
#UI BUTTONS
#-----------------------------------------
func _on_start_select(useMove):
	print(useMove)
	attacking = true
	team[i].attacking = true
	target = findTarget(useMove)
	which = findWhich(useMove)

func _on_move_selected(useMove):
	for times in useMove.HitNum:
		if useMove.property & 1 and useMove.property & 2:
			times += 1
		checkProperties(useMove)
	attacking = false
	team[i].attacking  = false
	next_entity()

func _on_wait_selected():
	next_entity()

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
	
	print(str(useMove.Target))
	print(str("Target: ",returnTarget))
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
	
	print(str(useMove.Which))
	print(str("which: ",returnWhich))
	return returnWhich
#-----------------------------------------
#USING MOVES
#-----------------------------------------
func offense(move):
	targetArray[index].selected.hide()
	if move.property & 1:
		targetArray[index].currentHP -= team[i].attack(move, targetArray[index], team[i],"Physical")
	if move.property & 2:
		targetArray[index].currentHP -= team[i].attack(move, targetArray[index], team[i],"Ballistic")
	elif move.property & 4:
		targetArray[index].currentHP -= team[i].BOMB(move, targetArray[index])
	targetArray[index].displayQuick(team[i].feedback)
	
	if targetArray[index].currentHP <= 0:
		targetArray[index].currentHP = 0
	
	targetArray[index].HPtext.text = str("HP: ",targetArray[index].currentHP)
	targetArray[index].HPBar.value = int(100 * float(targetArray[index].currentHP) / float(targetArray[index].data.MaxHP))
	
	team[i].feedback = ""
	checkHP()

func healing(move):
	targetArray[index].selected.hide()
	print(team[i].healHP(move, targetArray[index]))
	targetArray[index].currentHP += team[i].healHP(move, targetArray[index])
	
	if targetArray[index].currentHP >= targetArray[index].data.MaxHP:
		targetArray[index].currentHP = targetArray[index].data.MaxHP
	targetArray[index].HPtext.text = str("HP: ",targetArray[index].currentHP)
	targetArray[index].HPBar.value = int(100 * float(targetArray[index].currentHP) / float(targetArray[index].data.MaxHP))
	
	team[i].feedback = ""
	checkHP()

func checkProperties(move):
	if move.property & 1:
		offense(move)
	if move.property & 2:
		offense(move)
	if move.property & 4:
		pass
	if move.property & 8:
		pass
	if move.property & 16:
		healing(move)
	if move.property & 32:
		pass
	if move.property & 64:
		pass
	if move.property & 128:
		pass
	if move.property & 256:
		pass
#-----------------------------------------
#TURN END FUNCTIONS
#-----------------------------------------
func _on_wait_timer_timeout(): #For enemy turns it'll wait until the timer ends for the player to see the effect
	next_entity()
	waiting = false

func next_entity():
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
		playerTurn = !playerTurn
		
	else:
		if team[i].has_node("CanvasLayer"):
			team[i].menu.show()

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
			defeatedPlayers.append(player)
			lowerP += 1
	for enemy in enemyOrder:
		if enemy.currentHP <= 0:
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
	
	if playerOrder.size() == 0:
		print("You lose")
	
	#Resize 
	playerOrder.resize(InitialPsize - lowerP)
	enemyOrder.resize(InitialESize - lowerE)
	#Reset values
	index = 0
	target = null
	#Only Reset values if somone died
	#This lets the player mash a to attack the same guy a bunch until they die
	if InitialPsize != playerOrder.size() or InitialESize != enemyOrder.size():
		j = 0
		index = 0
