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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
