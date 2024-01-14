extends Resource
class_name Item

@export_category("Information")
@export var name: String
@export var maxCarry: int = 1
@export var maxItems: int = 20
@export var currentItems: int = 1
@export var centCost: int = 20
@export var icon: Texture2D
@export var attackData: Move = load("res://BasicAttack.tres")
@export var ownerNum: int = 0
@export_flags("DREAMER","Lonna","Damir","Pepper") var equippedOn = 0
