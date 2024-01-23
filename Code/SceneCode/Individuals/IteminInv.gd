extends PanelContainer

@onready var focus: Button = $Button
@onready var inBetween: Marker2D = $Marker2D
@onready var final: Marker2D = $Marker2D2
@onready var icon: TextureRect = $Button/MarginContainer/Item/TextureRect
@onready var itemText: RichTextLabel = $Button/MarginContainer/Item/MarginContainer/RichTextLabel
@onready var characterStatus: Array[TabContainer] = [$Button/MarginContainer/Item/Characters/DreamerStatus,
$Button/MarginContainer/Item/Characters/LonnaStatus,$Button/MarginContainer/Item/Characters/DamirStatus,
$Button/MarginContainer/Item/Characters/PepperStatus]

signal getDesc(data)
signal startSelect(data)

var itemData: Item
var currentPlayers: String
var maxNum: int
var currentNum: int
var inChar: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	icon.texture = itemData.icon
	update()

func update():
	currentNum = 3
	currentPlayers = ""
	
	if itemData.equippedOn != null:
		if itemData.equippedOn & 1:
			characterStatus[0].show()
			updatePlayers("DREAMER")
			currentNum -= 1
		else:
			characterStatus[0].hide()
		
		if itemData.equippedOn & 2:
			characterStatus[1].show()
			updatePlayers("Lonna")
			currentNum -= 1
		else:
			characterStatus[1].hide()
		
		if itemData.equippedOn & 4:
			characterStatus[2].show()
			updatePlayers("Damir")
			currentNum -= 1
		else:
			characterStatus[2].hide()
		
		if itemData.equippedOn & 8:
			characterStatus[3].show()
			updatePlayers("Pepper")
			currentNum -= 1
		else:
			characterStatus[3].hide()
	
	if currentPlayers == "":
		currentPlayers = "None"
	
	itemText.clear()

func updatePlayers(player):
	if currentPlayers == "":
		currentPlayers = str(player)
	else:
		currentPlayers = str(currentPlayers,", ",player)

func _on_button_focus_entered():
	getDesc.emit(self)
