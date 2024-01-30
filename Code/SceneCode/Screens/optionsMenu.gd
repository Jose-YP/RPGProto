extends CanvasLayer

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

var awaitingColor = Color(0.455, 0.455, 0.455)
var inputs: Array[Array] = [[],[]]
var inputTexts: Array[String] = []
var Buses: Array = []
var inputType: int = 0
var currentToggleIndex: int
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
	
	updateInputDisplay()

func _input(event):
	print(event)
	print(event is InputEventKey)
	if toggleOn:
		if inputType == 0:
			if event.is_match(InputEventKey, true):
				print(event)
		else:
			if event.is_match(InputEventJoypadButton, true):
				print(event)
			elif event.is_match(InputEventJoypadMotion, true):
				var eventText = event.as_text()
				if eventText.contains("Axis 4") or eventText.contains("Axis 5"):
					print(event)
		
		toggleOn = false

#-----------------------------------------
#AUDIO
#-----------------------------------------
func audioSet(value, index):
	VolumeValues[index].value = value
	VolumeTexts[index].text = str("		",VolumeValues[index].value,"%")
	AudioServer.set_bus_volume_db(Buses[index], linear_to_db(value * 0.01)) #0.01 so it doesn't get too loud

func _on_music_toggled(toggled_on):
	testMusic.emit(toggled_on)

func _on_sfx_pressed():
	makeNoise.emit()

#-----------------------------------------
#CONTROLLER REMAPPING
#-----------------------------------------
func updateInputDisplay():
	inputTexts.clear()
	
	for event in range(controllerChange.size()):
		var keyText: String
		if inputType == 0:
			keyText = inputs[inputType][event].as_text().trim_suffix(" (Physical)")
		elif inputs[inputType][event].as_text().contains("Button"):
			keyText = inputs[inputType][event].as_text().left(15)
		else:
			keyText = inputs[inputType][event].as_text().left(23)
		
		inputTexts.append(keyText)
		controllerChange[event].text = keyText

func controllerMapStart(toggled,index):
	if currentToggle != null:
		currentToggle.button_pressed = toggled
		currentToggle.text = inputTexts[currentToggleIndex]
	
	currentToggleIndex = index
	currentToggle = controllerChange[index]
	currentToggle.text = str("...Awaiting Input...")

func _on_new_input_type_selected(index):
	inputType = index
	updateInputDisplay()

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed():
	main.emit()

