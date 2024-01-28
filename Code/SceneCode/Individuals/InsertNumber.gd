extends Control

@onready var ammount: SpinBox = $PanelContainer/VBoxContainer/SpinBox

signal makeNoise()

var maxNum: int = 50
var holding: float = 0.0
var using: bool = false

# Called when the node enters the scene tree for the first time.
func _ready(): ammount.max_value = maxNum

func _process(_delta):
	if (Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Down")) and ammount.value != 0:
		ammount.value -= 1
		makeNoise.emit()
	if (Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("Up")) and ammount.value != maxNum:
		ammount.value += 1
		makeNoise.emit()
	
	if (holding == 0.0 or holding > 0.5) and using:
		if (Input.is_action_pressed("Left") or Input.is_action_pressed("Down")) and ammount.value != 0:
			ammount.value -= 1
			makeNoise.emit()
		if (Input.is_action_pressed("Right") or Input.is_action_pressed("Up")) and ammount.value != maxNum:
			ammount.value += 1
			makeNoise.emit()
