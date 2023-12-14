extends Resource
class_name Player

@export_category("Stats")
@export_range(0,200) var MaxLP: int = 10
@export_range(1,200) var MaxCPU: int = 10
@export_range(1,8) var skills: int = 1
@export_range(.5,2,.05) var rechargeRate: float = 1

@export_category("Basic Moves")
@export var slot2: Move
@export var slot3: Move 

@export_category("Boost")
@export_flags("Attack","Defense","Speed","Luck") var boostStat
@export var boostMove: Move
