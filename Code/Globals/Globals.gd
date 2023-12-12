extends Node

var file = "res://Other/PepperNMecha.json"
var json_as_text = FileAccess.get_file_as_string(file)
var json_as_dict = JSON.parse_string(json_as_text)
