extends Control

@onready var VolumeValues: Array[HSlider] = [$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/PanelContainer/HSlider,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/PanelContainer2/HSlider,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/PanelContainer3/HSlider]
@onready var VolumeTexts: Array[RichTextLabel] = [$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel2,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel4,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel6]
@onready var controllerChange: Array[Button] = [$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/A/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/ZL/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/B/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/L/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/X/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/R/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/Y/Button,
$PanelContainer/VBoxContainer/Controls/VBoxContainer/GridContainer/ZR/Button]
@onready var controllerType: OptionButton = $PanelContainer/VBoxContainer/Controls/VBoxContainer/InputType/OptionButton

signal main

var audioLevels: Array[int] = [100,100,100]
var inputs: Array[Array] = [[],[]]
var inputType: int = 0
var currentToggle: Button
var toggleOn: bool = false

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	for action in InputMap.get_actions(): #Get every input in InputMap that can be edited
		var check = (action == "Left" or action == "Right" 
		or action == "Up" or action == "Down" 
		or action == "Start" or action == "Select")
		
		if not action.contains("ui_") and not check:
			var events = InputMap.action_get_events(action)
			inputs[0].append(events[0])
			inputs[1].append(events[-1])
			print(action,events[0], events[-1])
	
	for type in inputs:
		for event in type:
			print(event.as_text())
	
	updateInputDisplay(inputType)

#-----------------------------------------
#AUDIO
#-----------------------------------------
func audioSet(value, index):
	VolumeTexts[index].text = str("		",VolumeValues[index].int(value),"%")
	audioLevels[index] = VolumeValues[index].int(value)

#-----------------------------------------
#CONTROLLER REMAPPING
#-----------------------------------------
func updateInputDisplay(num):
	pass

func controllerMapStart(_toggled,index):
	if currentToggle != null:
		currentToggle.button_pressed = false
		
	currentToggle = controllerChange[index]
	currentToggle.text = str("...Awaiting Input...")

func _on_new_input_type_selected(index):
	pass

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed():
	main.emit()
