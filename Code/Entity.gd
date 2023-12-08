extends Node2D

@export_file("*.tres") var data_file
@export var data: Entity

@onready var info: TextEdit = $TextEdit
#@onready var data: Entity = load("res://Resources/TestEntity.tres")

func show_data():
	var display = str("[",data.species,"] ",data.name, "\nelement:",data.element,"\nstr: ",
	 data.strength, " tgh:",data.toughness, "\nbal: ",data.ballistics, " res: ", data.resistance,
	 "\n spd: ", data.speed," luk: ", data.luck)
	info.text = display
	pass
	
func _ready():
	print(data_file)
	show_data()

