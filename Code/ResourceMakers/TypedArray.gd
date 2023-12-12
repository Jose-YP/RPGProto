extends Resource
class_name TypedArray

@export_category("Necessary")
@export var list: Array
@export var size: int

func _init(size: int, initialValue: int):
	list.resize(size)
