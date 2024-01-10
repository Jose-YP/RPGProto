extends PanelContainer

@onready var focus: Button = $Button
@onready var iconColor: TextureRect = $Button/MarginContainer/Chip1/TextureRect
@onready var chipText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var characterStatus: Array[TabContainer] = [$Button/MarginContainer/Chip1/Characters/DreamerStatus,
$Button/MarginContainer/Chip1/Characters/LonnaStatus,$Button/MarginContainer/Chip1/Characters/DamirStatus,
$Button/MarginContainer/Chip1/Characters/PepperStatus]

signal getDesc(data)
signal startSelect

var itemData: Chip
var currentPlayers: String
var maxNum: int
var currentNum: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
