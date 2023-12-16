extends Node

var file = "res://Other/PepperNMecha.json"
var json_as_text = FileAccess.get_file_as_string(file)
var json_as_dict = JSON.parse_string(json_as_text)
var elementGroups: Array = ["Fire","Water","Elec","Neutral"]
var XSoftTypes: Array = ["Fire","Water","Elec","Slash","Crush","Pierce"]
var AilmentTypes: Array = ["Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive",]
var attacking: bool
