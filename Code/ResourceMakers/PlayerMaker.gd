extends Resource
class_name Player

@export_category("Stats")
@export_range(0,200) var MaxLP: int = 10
@export_range(1,200) var MaxCPU: int = 10
@export_range(1,8) var skills: int = 1
@export_range(.5,2,.05) var rechargeRate: float = 1

@export_category("Sheets")
@export var statGrowth: Dictionary = {}

@export_category("Properties")
@export_enum("Attack","Defense","Luck") var Boost = "Attack"

