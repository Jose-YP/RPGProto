extends PanelContainer

@onready var focus: Button = $Button
@onready var inBetween: Marker2D = $Marker2D
@onready var final: Marker2D = $Marker2D2
@onready var iconColor: TextureRect = $Button/MarginContainer/Chip1/TextureRect
@onready var chipText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var characterStatus: Array[TabContainer] = [%DreamerStatus, %LonnaStatus, %DamirStatus, %PepperStatus]

signal getDesc(data)
signal startSelect(data)

var ChipData: Chip
var currentPlayers: String
var maxNum: int
var currentNum: int
var inChar: bool = false

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

func update() -> void:
	currentNum = 3
	currentPlayers = ""
	
	if ChipData.equippedOn != null:
		if ChipData.equippedOn & 1:
			characterStatus[0].current_tab = 1
			updatePlayers("DREAMER")
			currentNum -= 1
		else:
			characterStatus[0].current_tab = 0
		
		if ChipData.equippedOn & 2:
			characterStatus[1].current_tab = 1
			updatePlayers("Lonna")
			currentNum -= 1
		else:
			characterStatus[1].current_tab = 0
		
		if ChipData.equippedOn & 4:
			characterStatus[2].current_tab = 1
			updatePlayers("Damir")
			currentNum -= 1
		else:
			characterStatus[2].current_tab = 0
		
		if ChipData.equippedOn & 8:
			characterStatus[3].current_tab = 1
			updatePlayers("Pepper")
			currentNum -= 1
		else:
			characterStatus[3].current_tab = 0
	
	if currentPlayers == "":
		currentPlayers = "None"
	
	chipText.clear()
	var cost = ChipData.CpuCost
	if cost < 0:
		cost = str("+", ChipData.CpuCost * -1)
	
	chipText.append_text(str(ChipData.name," Chip | [color=yellow]CPU: ",cost,"[/color] | ",currentNum,"/",maxNum))

func updatePlayers(player) -> void:
	if currentPlayers == "":
		currentPlayers = str(player)
	else:
		currentPlayers = str(currentPlayers,", ",player)

func _on_button_focus_entered() -> void:
	getDesc.emit(self)
