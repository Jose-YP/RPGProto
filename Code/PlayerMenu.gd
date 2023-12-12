extends Control

@onready var Tab: TabContainer = $TabContainer
@onready var TabSecond: Array = Tab.get_children()

signal Attack(i)
signal Skill(i)
signal Item(i)
signal Tactic(i)

#Determines if up/down inputs should be taken 
var selectingMenu: bool = true

func _process(_delta):
	if selectingMenu:
		if Input.is_action_just_pressed("Down"):
			pass
		if Input.is_action_just_pressed("Up"):
			pass
	if Input.is_action_just_pressed("Accept"):
		Tab.visible = not Tab.visible
		selectingMenu = not selectingMenu
	if Input.is_action_just_pressed("Cancel"):
		Tab.visible = false
		selectingMenu = true

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

#Every back node is connected to this
func _on_back_pressed():
	Tab.visible = false
	selectingMenu = true
