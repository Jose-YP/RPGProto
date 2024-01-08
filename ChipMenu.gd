extends Control

@export var type: String

@onready var chipList: ItemList = $ItemList

var ChipIcon = preload("res://Icons/MenuIcons/icons-set-2_0000s_0029__Group_.png")



# Called when the node enters the scene tree for the first time.
func _ready():
	list_files_in_directory(type)

func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	
	print(files)
	return files

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
