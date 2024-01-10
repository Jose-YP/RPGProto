extends PanelContainer

@onready var focus: Button = $Button
@onready var iconColor: TextureRect = $Button/MarginContainer/Chip1/TextureRect
@onready var chipText: RichTextLabel = $Button/MarginContainer/Chip1/MarginContainer/RichTextLabel
@onready var dreamerStatus: TabContainer = $Button/MarginContainer/Chip1/Characters/DreamerStatus
@onready var lonnaStatus: TabContainer = $Button/MarginContainer/Chip1/Characters/LonnaStatus
@onready var damirStatus: TabContainer = $Button/MarginContainer/Chip1/Characters/DamirStatus
@onready var pepperStatus: TabContainer = $Button/MarginContainer/Chip1/Characters/PepperStatus

signal getDesc(data)
signal startSelect

var chipData: Chip
var maxNum: int
var currentNum: int

# Called when the node enters the scene tree for the first time.
func _ready():
	match chipData.ChipType:
		"Red":
			iconColor.modulate = Color.RED
		"Blue":
			iconColor.modulate = Color.BLUE
		"Yellow":
			iconColor.modulate = Color.YELLOW
	
	
	
	chipText.clear()
	chipText.append_text(str(chipData.name," Chip ",currentNum,"/",maxNum))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_focus_entered():
	getDesc.emit(chipData)

func _on_button_pressed():
	startSelect.emit()
