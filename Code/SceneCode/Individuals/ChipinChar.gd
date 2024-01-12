extends PanelContainer

@onready var focus: Button = $Button
@onready var inBetween: Marker2D = $Marker2D
@onready var final: Marker2D = $Marker2D2
@onready var iconColor: TextureRect = $Button/MarginContainer/Chip1/TextureRect
@onready var chipText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel

signal getDesc(data)
signal startSelect

var ChipData: Chip
var maxNum: int
var currentNum: int

func _ready():
	print(inBetween.position)
	match ChipData.ChipType:
		"Red":
			iconColor.modulate = Color.RED
		"Blue":
			iconColor.modulate = Color.BLUE
		"Yellow":
			iconColor.modulate = Color.YELLOW
	
	chipText.clear()
	var cost = ChipData.CpuCost
	if cost < 0:
		cost = str("+", ChipData.CpuCost * -1)
	
	chipText.append_text(str(ChipData.name," Chip | [color=yellow]CPU: ",cost,"[/color]"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_button_focus_entered():
	getDesc.emit(self)
