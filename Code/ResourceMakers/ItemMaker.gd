extends Resource
class_name Item

@export_category("Information")
@export var name: String
@export var maxItems: int = 20
@export var centCost: int = 20
@export var attackData: Move = load("res://BasicAttack.tres")
