extends Control

@onready var ammount: SpinBox = $PanelContainer/VBoxContainer/SpinBox
var maxNum: int = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	ammount.max_value = maxNum

func _process(delta):
	if Input.is_action_pressed("Left") or Input.is_action_pressed("Down"):
		ammount.value -= 1
	if Input.is_action_pressed("Right") or Input.is_action_pressed("Up"):
		ammount.value += 1
