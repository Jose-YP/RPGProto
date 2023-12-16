extends Resource
class_name Enemy

@export_category("Drops")
@export var xp: int
@export var cents: int

@export_category("Properties")
@export var Boss: bool
@export var Revivable: bool
@export_enum("Random","Single Strike", "Pick off","Support", "Debuff") var AIType: String = "Random"
