extends Control

@onready var Tab: TabContainer = $TabContainer
@onready var TabSecond: Array = Tab.get_children()
@onready var RegularMenu: PanelContainer = $Regularmenu
@onready var currentlyFocused: Button = $Regularmenu/MarginContainer/GridContainer/Basic

signal Attack(i)
signal Skill(i)
signal Item(i)
signal Tactic(i)
signal Focusing(focus,menuI,buttonI)
signal confirm(bool)
signal cancel
signal move

#Determines if up/down inputs should be taken 
var selectingMenu: bool = true
var confirmed: bool = true
var changed: bool = false
var menuIndex: int = 0
var buttonIndex: int = 0
var menuDictionary: Dictionary = {}
var fullMenu: Array = []

func _ready():
	$TextEdit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TextEdit.focus_mode = Control.FOCUS_NONE
	currentlyFocused.grab_focus()
	var i = 0
	fullMenu.append(RegularMenu.get_node("MarginContainer/GridContainer").get_children())
	for Menu in TabSecond:
		i += 1
		fullMenu.append(Menu.get_node("MarginContainer/GridContainer").get_children())
		menuDictionary[Menu.name] = i

func _process(_delta):
	if $".".visible:
		if menuIndex == 0 or selectingMenu:
			menuMove()
		
		menuConfirm()
		Focusing.emit(fullMenu[menuIndex][buttonIndex],menuIndex,buttonIndex,changed)
		changed = false

func menuMove():
	if Input.is_action_just_pressed("Left"):
		confirm.emit(false)
		menuIndex = 0
		Tab.visible = false
	if Input.is_action_just_pressed("Right"):
		confirm.emit(true)
		Tab.visible = true
		if menuIndex == 0:
			menuIndex = menuDictionary.get(fullMenu[menuIndex][buttonIndex].name)
			Tab.current_tab = menuIndex - 1
			fullMenu[menuIndex][buttonIndex].grab_focus()
	#Don't accept up/down if they already pressed a move button
	if selectingMenu:
		if Input.is_action_just_pressed("Down"):
			move.emit()
			if buttonIndex >= 3:
				buttonIndex = 0
			else:
				buttonIndex += 1
			changed = true
			
		if Input.is_action_just_pressed("Up"):
			move.emit()
			if buttonIndex <= 0:
				buttonIndex = 3
			else:
				buttonIndex -= 1
			changed = true

func menuConfirm():
	if Input.is_action_just_pressed("Accept"):
		if menuIndex == 0: #get to the next item in the menu
			Tab.visible = true
			menuIndex = menuDictionary.get(fullMenu[menuIndex][buttonIndex].name)
			Tab.current_tab = menuIndex - 1
			fullMenu[menuIndex][buttonIndex].grab_focus()
		elif fullMenu[menuIndex][buttonIndex].disabled == false: #Either select the move to be used or confirm it
			if selectingMenu:
				fullMenu[menuIndex][buttonIndex].emit_signal("pressed")
				selectingMenu = false
			else:
				fullMenu[menuIndex][buttonIndex].emit_signal("pressed")
				Tab.visible = false
				menuIndex = 0
				fullMenu[menuIndex][buttonIndex].grab_focus()
		
		confirm.emit(true)
		
	if Input.is_action_just_pressed("Cancel"):
		if menuIndex == 0: #Cancel selection out of the menu
			if Globals.attacking:
				selectingMenu = true
				confirmed = false
				cancel.emit()
		
		if menuIndex != 0: #Cancel aselection in the menu
			buttonIndex = menuIndex - 1
			menuIndex = 0
			Tab.visible = false
			selectingMenu = true
			confirmed = false
			cancel.emit()
		
		confirm.emit(false)

#Regular menu's buttons all have arguments to the index they should send to
func _on_first_pressed(index):
	Tab.visible = true
	Tab.current_tab = index

func _on_attack_pressed(index):
	Attack.emit(index)

func _on_skill_pressed(index):
	Skill.emit(index)

func _on_item_pressed(index):
	Item.emit(index)

func _on_tactic_pressed(index):
	Tactic.emit(index)

func _on_player_can_pay_for(menuI, buttonI, allowed):
	if allowed:
		fullMenu[menuI+1][buttonI].disabled = false
	else:
		print(fullMenu[menuI+1][buttonI].name)
		fullMenu[menuI+1][buttonI].disabled = true

func _on_player_selected_again():
	selectingMenu = true
