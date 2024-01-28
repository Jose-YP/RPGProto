extends MarginContainer

@export var chara: String
@export var gearData: Gear

@onready var focus: Button = $MenuItem/Button
@onready var icon: TextureRect = $MenuItem/Button/MarginContainer/Gear/GearIcon
@onready var gearText: RichTextLabel = $MenuItem/Button/MarginContainer/Gear/MarginContainer/RichTextLabel
@onready var equippedStatus: TextureRect = $MenuItem/Button/MarginContainer/Gear/Equipped

signal getDesc(data)
signal getEquipped(data)
signal startSelect

var charColor: Color
var baseColor: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	match chara:
		"DREAMER": charColor = Color(0.957, 0.537, 0.169)
		"Lonna": charColor = Color(0.596, 0, 0.863)
		"Damir": charColor = Color(0.161, 0.161, 0.918)
		"Pepper": charColor = Color(0.882, 0.157, 0.157)
	
	icon.modulate = charColor
	icon.texture = gearData.icon
	equippedStatus.modulate = charColor
	
	gearText.clear()
	gearText.append_text(str("[center]",gearData.name,"[/center]"))
	
	if gearData.equipped: 
		equippedStatus.show()
		getEquipped.emit(self)
	else: equippedStatus.hide()

func _on_button_focus_entered():
	getDesc.emit(self)
