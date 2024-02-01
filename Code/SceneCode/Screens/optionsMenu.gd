extends CanvasLayer

@onready var VolumeValues: Array[HSlider] = [%MasterSlider, %MusicSlider, %SFXSlider]
@onready var VolumeTexts: Array[RichTextLabel] = [%MasterText, %MusicText, %SFXText]
@onready var controllerChange: Array[Button] = [%Up/Button, %Accept/Button, %ZL/Button, %Left/Button,
%Cancel/Button, %L/Button, %Down/Button, %X/Button, %R/Button, %Right/Button, %Y/Button, %ZR/Button]
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
var userAudios: Array = []
var inputType: int = 0
var currentToggleIndex: int
var currentAction: String
var currentToggle: Button
var toggleOn: bool = false
var currentInput: InputEvent
var userPrefs: UserPreferences

#-----------------------------------------
#INITALIZATION & PROCESSING
#-----------------------------------------
func _ready():
	userPrefs = UserPreferences.load_or_create()
	Buses = [MasterBus, MusicBus, SFXBus]
	userAudios = [userPrefs.masterAudioLeve, userPrefs.musicAudioLeve, userPrefs.sfxAudioLeve]
	
	for i in range(VolumeValues.size()):
		audioSet(userAudios[i], i)
	
	inputType = userPrefs.input_type
	for action in userPrefs.keyboard_action_events:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, userPrefs.keyboard_action_events[action])
	
	for action in userPrefs.joy_action_events:
		InputMap.action_add_event(action, userPrefs.keyboard_action_events[action])
	
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
	
	userAudios[index] = value * 0.01
	match index: #Has to be saved directly
		0:
			userPrefs.masterAudioLeve = value
		1:
			userPrefs.musicAudioLeve = value
		2:
			userPrefs.sfxAudioLeve = value
	userPrefs.save()

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
	var sortedLoop: Array = []
	
	match inputType:
		0:
			loopActions = userPrefs.keyboard_action_events.keys()
		1:
			loopActions = userPrefs.joy_action_events.keys()
	
	for i in range(controllerChange.size()):#Controller change's parents have the right names
		for j in range(loopActions.size()):
			if controllerChange[i].get_parent().name == loopActions[j]:
				sortedLoop.append(loopActions[j])
				break
	
	loopActions = sortedLoop
	
	for action in loopActions: #Get every input in InputMap that can be edited
		var events = InputMap.action_get_events(action)
		Actions.append(action)
		for event in events:
			if event is InputEventKey:
				inputs[0].append(event)
				userPrefs.keyboard_action_events[action] = event
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				inputs[1].append(event)
				userPrefs.joy_action_events[action] = event
	
	userPrefs.save()
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
	userPrefs.input_type = index
	userPrefs.save()
	updateInputDisplay()

func _on_reset_pressed() -> void:
	InputMap.load_from_project_settings()
	getNewInputs()

func changeInput(event) -> void:
	currentToggle.button_pressed = false
	InputMap.action_erase_event(currentAction, currentInput)
	InputMap.action_add_event(currentAction, event)
	toggleOn = false
	checkRepeats(currentInput, event)
	getNewInputs()

func checkRepeats(oldEvent, event) -> void:
	var found: bool = false
	var repeat: String
	
	for action in Actions:
		if action == currentAction: continue
		
		if InputMap.event_is_action(event, action, true):
			found = true
			repeat = action
	
	if found:
		InputMap.action_erase_event(repeat, event)
		InputMap.action_add_event(repeat, oldEvent)

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed() -> void:
	main.emit()
