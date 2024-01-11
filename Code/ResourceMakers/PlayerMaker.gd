extends Resource
class_name Player

@export_category("Stats")
@export_range(0,200) var MaxLP: int = 10
@export_range(1,200) var MaxCPU: int = 10
@export_enum("Fire","Water","Elec","Neutral") var permanentElement: String = "Fire"
@export_range(1,8) var Skills: int = 1
@export_range(.5,2,.05) var RechargeRate: float = 1

@export_category("Equipment")
@export var GearData: Gear
@export var ChipData: Array[Chip]
@export var currentCPU: int = 0

@export_group("Basic Moves")
@export var Basics: Array[Move]

@export_group("Tactics")
@export_flags("Attack","Defense","Speed","Luck") var boostStat
@export var Tactics2: Move#For some reason it breaks when I make Tactics an Array[Move]
@export var Tactics3: Move
@export var Tactics4: Move
