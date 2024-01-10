extends PanelContainer

@export var char: String
@export var gearData: Gear

@onready var focus: Button = $Button
@onready var icon: TextureRect = $Button/MarginContainer/Chip1/GearIcon
@onready var gearText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var equippedStatus: TextureRect = $Button/MarginContainer/Chip1/Equipped

signal getDesc(data)
signal startSelect

var equipped: bool = false
var charColor: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	match char:
		"Dreamer":
			charColor = Color(0.957, 0.537, 0.169)
		"Lonna":
			charColor = Color(0.596, 0, 0.863)
		"Damir":
			charColor = Color(0.161, 0.161, 0.918)
		"Pepper":
			charColor = Color(0.882, 0.157, 0.157)
	
	icon.modulate = charColor
	icon.texture = gearData.icon
	equippedStatus.modulate = charColor
	
	gearText.clear()
	gearText.append_text(str("[center]",gearData.name,"[/center]"))
	
	updateEquip(equipped)

func updateEquip(value):
	equipped = value
	
	if equipped:
		equippedStatus.show()
	else:
		equippedStatus.hide()
