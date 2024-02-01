extends Resource
class_name Options

#AUDIO OPTIONS
@export_range(0,1,.05) var masterAudioLeve: float = 1.0
@export_range(0,1,.05) var musicAudioLeve: float = 1.0
@export_range(0,1,.05) var sfxAudioLeve: float = 1.0

#INPUT MAP



#FUNCTIONS
func save() -> void:
	ResourceSaver.save(self, "res://JSONS&Saves/Saves/user_prefs.tres")

static func load_or_create() -> Options:
	var res: Options = load("res://JSONS&Saves/Saves/user_prefs.tres") as Options
	if !res:
		res = Options.new()
	return res
