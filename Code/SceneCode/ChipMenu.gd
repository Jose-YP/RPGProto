extends Control

@export var InvChipPanel: PackedScene
@export var playerChipPanel: PackedScene

#Menus
@onready var chipInv: GridContainer = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/ChipSelection/GridContainer
@onready var playerChips: GridContainer = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CurrentChips/PanelContainer
#Descriptions
@onready var invChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var invChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var invChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/ChipSelection/VBoxContainer/Info/Description/RichTextLabel
@onready var playerChipTitle: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/QuickInfo/HBoxContainer/Title/RichTextLabel
@onready var playerChipDetails: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/QuickInfo/HBoxContainer/Details/RichTextLabel
@onready var playerChipDisc: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/Info/Description/RichTextLabel
#Current Player Info
@onready var CPUBar: TextureProgressBar = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/EnemyTP
@onready var CPUText: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharChips/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/RichTextLabel

var ChipIcon = preload("res://Icons/MenuIcons/icons-set-2_0000s_0029__Group_.png")
var InvMenu: Array[Array] = [[],[]]
var side: int = 0
var num: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for chip in Globals.ChipInventory.inventory:
		var chipPanel = InvChipPanel.instantiate()
		chipPanel.chipData = chip
		chipPanel.maxNum = Globals.ChipInventory.inventory[chip]
		chipPanel.connect("getDesc",on_inv_focused)
		chipInv.add_child(chipPanel)
		
		InvMenu[side].append(chipPanel)
		if side == 0:
			side += 1
		else:
			side -= 1
	
	side = 0
	InvMenu[side][num].focus.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func getElements(entity,ElementTab,PhyEleTab):
	for k in range(4):
		if Globals.elementGroups[k] == entity.element:
			ElementTab.current_tab = k
	for k in range(3):
		if Globals.XSoftTypes[k+3] == entity.phyElement:
			PhyEleTab.current_tab = k

func on_inv_focused(data):
	invChipTitle.clear()
	invChipTitle.append_text(data.name)
	
	invChipDisc.clear()
	invChipDisc.append_text(data.description)
