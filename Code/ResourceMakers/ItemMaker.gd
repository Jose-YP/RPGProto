extends Resource
class_name Item

@export_category("Information")
@export var name: String
@export var maxCarry: int = 1 #Maximum possible number of items that can be carried by the inventory
@export var maxItems: int = 20 #Maximum possible number of items that can be carried by a player
@export var currentItems: int = 1 #Total items currenly in inventory and players
@export var currentInInv: int = 1 #Items leftover in the inventory
@export var centCost: int = 20
@export var icon: Texture2D
@export var attackData: Move = load("res://BasicAttack.tres")

@export_category("Owners")
@export var ownerArray: Array[int] = [0,0,0,0]
@export_flags("DREAMER","Lonna","Damir","Pepper") var equippedOn: int = 0
@export_flags("DREAMER","Lonna","Damir","Pepper") var autoFill: int = 0
