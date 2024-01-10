extends PanelContainer

@export var charColor: Color

@onready var focus: Button = $Button
@onready var icon: TextureRect = $Button/MarginContainer/Chip1/GearIcon
@onready var gearText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var equippedStatus: TextureRect = $Button/MarginContainer/Chip1/Equipped

signal getDesc(data)
signal startSelect

var gearData: Gear
var equipped: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	icon.modulate = charColor
	equippedStatus.modulate = charColor
	
	gearText.clear()
	gearText.append_text(gearData.name)
	
	updateEquip()
	
	pass # Replace with function body.

func updateEquip():
	if equipped:
		equippedStatus.show()
	else:
		equippedStatus.hide()
