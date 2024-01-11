extends PanelContainer

@onready var focus: Button = $Button
@onready var inBetween: Marker2D = $Marker2D
@onready var iconColor: TextureRect = $Button/MarginContainer/Chip1/TextureRect
@onready var chipText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var characterStatus: Array[TabContainer] = [$Button/MarginContainer/Chip1/Characters/DreamerStatus,
$Button/MarginContainer/Chip1/Characters/LonnaStatus,$Button/MarginContainer/Chip1/Characters/DamirStatus,
$Button/MarginContainer/Chip1/Characters/PepperStatus]

signal getDesc(data)
signal startSelect

var ChipData: Chip
var currentPlayers: String
var maxNum: int
var currentNum: int

# Called when the node enters the scene tree for the first time.
func _ready():
	match ChipData.ChipType:
		"Red":
			iconColor.modulate = Color.RED
		"Blue":
			iconColor.modulate = Color.BLUE
		"Yellow":
			iconColor.modulate = Color.YELLOW
	
	update()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func update():
	currentNum = 3
	currentPlayers = ""
	
	if ChipData.equippedOn != null:
		if ChipData.equippedOn & 1:
			characterStatus[0].show()
			updatePlayers("DREAMER")
			currentNum -= 1
		else:
			characterStatus[0].hide()
		
		if ChipData.equippedOn & 2:
			characterStatus[1].show()
			updatePlayers("Lonna")
			currentNum -= 1
		else:
			characterStatus[1].hide()
		
		if ChipData.equippedOn & 4:
			characterStatus[2].show()
			updatePlayers("Damir")
			currentNum -= 1
		else:
			characterStatus[2].hide()
		
		if ChipData.equippedOn & 8:
			characterStatus[3].show()
			updatePlayers("Pepper")
			currentNum -= 1
		else:
			characterStatus[3].hide()
	
	if currentPlayers == "":
		currentPlayers = "None"
	
	chipText.clear()
	var cost = ChipData.CpuCost
	if cost < 0:
		cost = str("+", ChipData.CpuCost * -1)
	
	chipText.append_text(str(ChipData.name," Chip | [color=yellow]CPU: ",cost,"[/color] | ",currentNum,"/",maxNum))

func updatePlayers(player):
	if currentPlayers == "":
		currentPlayers = str(player)
	else:
		currentPlayers = str(currentPlayers,", ",player)
	
func _on_button_focus_entered():
	getDesc.emit(self)

func _on_button_pressed():
	startSelect.emit()
