extends CanvasLayer

@onready var VolumeValues: Array[HSlider] = [$Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/HSlider,
$Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/HSlider2, $Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/HSlider3]
@onready var VolumeTexts: Array[RichTextLabel] = [$Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel2,
$Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel4, $Main/VBox/Audio/IndvOptions/AudioOptions/GridContainer/RichTextLabel6]
@onready var controllerChange: Array[Button] = [$Main/VBox/Controls/VBox/Buttons/A/Button, $Main/VBox/Controls/VBox/Buttons/ZL/Button, 
$Main/VBox/Controls/VBox/Buttons/B/Button, $Main/VBox/Controls/VBox/Buttons/L/Button, $Main/VBox/Controls/VBox/Buttons/X/Button,
$Main/VBox/Controls/VBox/Buttons/R/Button, $Main/VBox/Controls/VBox/Buttons/Y/Button, $Main/VBox/Controls/VBox/Buttons/ZR/Button]
@onready var MasterBus = AudioServer.get_bus_index("Master")
@onready var MusicBus = AudioServer.get_bus_index("Music")
@onready var SFXBus = AudioServer.get_bus_index("SFX")

signal main
signal makeNoise
signal testMusic(toggled_on)

var awaitingColor = Color(0.455, 0.455, 0.455)
var inputs: Array[Array] = [[],[]]
var inputTexts: Array[String] = []
var Actions: Array = []
var Buses: Array = []
var inputType: int = 0
var currentToggleIndex: int
var currentToggle: Button
var currentInput: InputEvent
var toggleOn: bool = false
var oldMap
var currentAction


#-----------------------------------------
#INITALIZATION
#-----------------------------------------
func _ready():
	Buses = [MasterBus, MusicBus, SFXBus]
	getNewInputs()

func _input(event):
	if toggleOn:
		if inputType == 0:
			if event is InputEventKey:
				changeInput(event)
		else:
			if event is InputEventJoypadButton:
				changeInput(event)
				
			elif event is InputEventJoypadMotion:
				var eventText = event.as_text()
				if eventText.contains("Axis 4") or eventText.contains("Axis 5"):
					changeInput(event)

#-----------------------------------------
#AUDIO
#-----------------------------------------
func audioSet(value, index) -> void:
	VolumeValues[index].value = value
	VolumeTexts[index].text = str("		",VolumeValues[index].value,"%")
	AudioServer.set_bus_volume_db(Buses[index], linear_to_db(value * 0.01)) #0.01 so it doesn't get too loud

func _on_music_toggled(toggled_on) -> void:
	testMusic.emit(toggled_on)

func _on_sfx_pressed() -> void:
	makeNoise.emit()

#-----------------------------------------
#CONTROLLER REMAPPING
#-----------------------------------------
func getNewInputs() -> void:
	Actions = []
	inputs = [[],[]]
	var loopActions = InputMap.get_actions()
	
	for action in loopActions: #Get every input in InputMap that can be edited
		var check = (action == "Left" or action == "Right" 
		or action == "Up" or action == "Down" 
		or action == "Start" or action == "Select")
		
		if not action.contains("ui_") and not check:
			var events = InputMap.action_get_events(action)
			Actions.append(action)
			for event in events:
				if event is InputEventKey:
					inputs[0].append(event)
				elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
					inputs[1].append(event)
	
	updateInputDisplay()

func updateInputDisplay() -> void:
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

func controllerMapStart(toggled,index) -> void:
	if currentToggle != null:
		currentToggle.button_pressed = toggled
		currentToggle.text = inputTexts[currentToggleIndex]
	
	currentAction = Actions[index]
	currentInput = inputs[inputType][index]
	currentToggleIndex = index
	currentToggle = controllerChange[index]
	currentToggle.text = str("...Awaiting Input...")
	toggleOn = true

func _on_new_input_type_selected(index) -> void:
	inputType = index
	updateInputDisplay()

func _on_reset_pressed():
	InputMap.load_from_project_settings()
	getNewInputs()

func changeInput(event) -> void:
	currentToggle.button_pressed = false
	InputMap.action_erase_event(currentAction, currentInput)
	InputMap.action_add_event(currentAction, event)
	toggleOn = false
	getNewInputs()

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed() -> void:
	main.emit()
