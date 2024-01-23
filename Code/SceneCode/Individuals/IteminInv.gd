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

func update() -> void:
	currentNum = maxNum
	currentPlayers = ""
	
	if itemData.equippedOn != null:
		if itemData.equippedOn & 1:
			characterStatus[0].current_tab = 1
			updatePlayers("DREAMER",0)
			currentNum -= itemData.ownerArray[0]
		else:
			characterStatus[0].current_tab = 0
		
		if itemData.equippedOn & 2:
			characterStatus[1].current_tab = 1
			updatePlayers("Lonna",1)
			currentNum -= itemData.ownerArray[1]
		else:
			characterStatus[1].current_tab = 0
		
		if itemData.equippedOn & 4:
			characterStatus[2].current_tab = 1
			updatePlayers("Damir",2)
			currentNum -= itemData.ownerArray[2]
		else:
			characterStatus[2].current_tab = 0
		
		if itemData.equippedOn & 8:
			characterStatus[3].current_tab = 1
			updatePlayers("Pepper",3)
			currentNum -= itemData.ownerArray[3]
		else:
			characterStatus[3].current_tab = 0
		
	if itemData.autoFill != null:
		if itemData.autoFill & 1:
			characterStatus[0].current_tab = 2
		if itemData.autoFill & 2:
			characterStatus[1].current_tab = 2
		if itemData.autoFill & 4:
			characterStatus[2].current_tab = 2
		if itemData.autoFill & 8:
			characterStatus[3].current_tab = 2
	
	if currentPlayers == "":
		currentPlayers = "None"
	
	itemText.clear()
	itemText.append_text(str(itemData.name," | [right][color=gray]",currentNum,"/",itemData.maxCarry,"[/color]"))

func updatePlayers(player,num) -> void:
	if currentPlayers == "":
		currentPlayers = str(player," ",itemData.ownerArray[num],"/",itemData.maxItems)
	else:
		currentPlayers = str(currentPlayers," | ",player," ",itemData.ownerArray[num],"/",itemData.maxItems)

func _on_button_focus_entered() -> void:
	getDesc.emit(self)
