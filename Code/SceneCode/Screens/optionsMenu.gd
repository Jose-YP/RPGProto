extends Control

@onready var VolumeValues: Array[HSlider] = [$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/HSlider,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/HSlider2,
$PanelContainer/VBoxContainer/Audio/IndvOptions/AudioOptions/GridContainer/HSlider3]
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
@onready var MasterBus = AudioServer.get_bus_index("Master")
@onready var MusicBus = AudioServer.get_bus_index("Music")
@onready var SFXBus = AudioServer.get_bus_index("SFX")

signal main
signal makeNoise
signal testMusic(toggled_on)

var inputs: Array[Array] = [[],[]]
var Buses: Array = []
var inputType: int = 0
var currentToggle: Button
var toggleOn: bool = false

#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	Buses = [MasterBus, MusicBus, SFXBus]
	
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
	print(AudioServer.get_bus_index("Music"))
	VolumeValues[index].value = value
	VolumeTexts[index].text = str("		",VolumeValues[index].value,"%")
	AudioServer.set_bus_volume_db(Buses[index], linear_to_db(value * 0.01))

func _on_music_toggled(toggled_on):
	testMusic.emit(toggled_on)

func _on_sfx_pressed():
	makeNoise.emit()

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

