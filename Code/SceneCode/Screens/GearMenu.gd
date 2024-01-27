extends Control

@export var gearPanel: PackedScene
@export var inputButtonThreshold: float = 1.0
@export var scrollAmmount: int = 55
@export var scrollDeadzone: Vector2 = Vector2(280,420) #x is top value, y is bottom value

#Menu
@onready var gearInv: GridContainer = $VBoxContainer/MainDock/CurrentCharGear/VBoxContainer/CurrentGear
#Descriptions
@onready var oldGearTitle: RichTextLabel = $VBoxContainer/MainDock/Info/PanelContainer/QuickInfo/HBoxContainer/MarginContainer2/OldGear/RichTextLabel
@onready var oldGearDisc: RichTextLabel = $VBoxContainer/MainDock/Info/PanelContainer/QuickInfo/HBoxContainer/MarginContainer/OldDesc/RichTextLabel
@onready var newGearTitle: RichTextLabel =$VBoxContainer/MainDock/Info/PanelContainer/QuickInfo/HBoxContainer/MarginContainer3/NewGear/RichTextLabel
@onready var newGearDisc: RichTextLabel = $VBoxContainer/MainDock/Info/PanelContainer/QuickInfo/HBoxContainer/MarginContainer4/NewDesc/RichTextLabel
#Current Player Info
@onready var playerResource: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharGear/VBoxContainer/CharacterInfo/Character/RichTextLabel
@onready var playerElement: TabContainer = $VBoxContainer/MainDock/CurrentCharGear/VBoxContainer/CharacterInfo/Elements/Player1Element
@onready var playerPhyEle: TabContainer = $VBoxContainer/MainDock/CurrentCharGear/VBoxContainer/CharacterInfo/Elements/PlayerPhyElement1
@onready var playerBattleStats: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharGear/VBoxContainer/CharacterInfo/Stats/RichTextLabel
@onready var CPUText: RichTextLabel = $VBoxContainer/HBoxContainer/CurrentCharGear/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/RichTextLabel
@onready var CPUBar: TextureProgressBar = $VBoxContainer/HBoxContainer/CurrentCharGear/VBoxContainer/CharacterInfo/CPUBox/HBoxContainer/EnemyTP
@onready var itemPanel: RichTextLabel = $VBoxContainer/MainDock/CurrentCharGear/VBoxContainer/CharacterInfo/ItemBox/HBoxContainer/RichTextLabel

signal chipMenu
signal gearMenu
signal itemMenu
signal exitMenu
signal makeNoise(num)

var currentInv: Array = []
var inputHoldTime: float = 0.0

func _ready():
	pass # Replace with function body.


func _process(_delta):
	if Input.is_action_just_pressed("Accept"):
		makeNoise.emit(0)
		get_viewport().gui_get_focus_owner()
	
	if Input.is_action_just_pressed("Cancel"):
		makeNoise.emit(1)
		exitMenu.emit()
	
	if Input.is_action_just_pressed("Y"):
		makeNoise.emit(0)
	
	#[chip,gear,item]
	if Input.is_action_just_pressed("ZL"):
		chipMenu.emit()
		
	if Input.is_action_just_pressed("ZR"):
		itemMenu.emit()
