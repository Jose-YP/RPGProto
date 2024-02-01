extends Resource
class_name UserPreferences

#AUDIO OPTIONS
@export_range(0,100,.05) var masterAudioLeve: float = 100.0
@export_range(0,100,.05) var musicAudioLeve: float = 100.0
@export_range(0,100,.05) var sfxAudioLeve: float = 100.0

#INPUT MAP
@export_enum("KEYBOARD","GAMEPAD") var input_type: int = 0
@export var keyboard_action_events: Dictionary = {}
@export var joy_action_events: Dictionary ={}

#FUNCTIONS
func save() -> void:
	ResourceSaver.save(self, "res://JSONS&Saves/Saves/user_prefs.tres")

static func load_or_create() -> UserPreferences:
	var res: UserPreferences = load("res://JSONS&Saves/Saves/user_prefs.tres") as UserPreferences
	if !res:
		res = UserPreferences.new()
	return res
