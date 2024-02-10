extends Resource
class_name Player

@export_category("Stats")
@export_range(0,200) var MaxLP: int = 10
@export_range(1,200) var MaxCPU: int = 10
@export_range(1,8) var Skills: int = 1
@export_range(.5,2,.05) var RechargeRate: float = 1

@export_category("Equipment")
@export var GearData: Gear
@export var ChipData: Array[Chip]
@export var currentCPU: int = 0

@export_group("Basic Moves")
@export_enum("Single","Group","Self","All","Random","KO","None") var attackTarget: String = "Single"
@export var Basics: Array[Move] = []
@export_subgroup("3rdMove Flags")
@export_flags("Fire","Water","Elec") var ThirdMoveElement: int = 0

@export_group("Tactics")
@export_enum("Single","Group","Self","All","Random","KO","None") var boostTarget: String = "Single"
@export_flags("Attack","Defense","Speed","Luck") var boostStat: int = 8
@export var Tactics2: Move#For some reason it breaks when I make Tactics an Array[Move]
@export var Tactics3: Move
@export var Tactics4: Move

@export_group("Defaults")
@export_enum("Fire","Water","Elec","Neutral") var permanentElement: String = "Fire"
@export_enum("Slash","Crush","Pierce") var permanentPhyEle: String = "Slash"
@export_flags("Fire","Water","Elec","Slash","Crush","Pierce","All") var permanentWeakness: int = 0
@export_flags("Fire","Water","Elec","Slash","Crush","Pierce","All") var permanentResist: int = 0
@export_flags("Attack","Defense","Speed","Luck") var defaultBoostStat: int = 8

func setUp(element, phy, weak, res, name):
	Basics = [load("res://Resources/Move Data/Player Moves/AllPlayers/Crash.tres"),
	load("res://Resources/Move Data/Player Moves/AllPlayers/MiscPlaceHolder.tres"),
	load("res://Resources/Move Data/Entity Moves/MostPlayer/Burst.tres")]
	Tactics2 = load("res://Resources/Move Data/Player Moves/AllPlayers/Boost.tres")
	Tactics3 = load("res://Resources/Move Data/Player Moves/AllPlayers/Scan.tres")
	Tactics4 = load("res://Resources/Move Data/Player Moves/AllPlayers/SummonPlaceholder.tres")
	
	permanentElement = element
	permanentPhyEle = phy
	permanentWeakness = weak
	permanentResist = res
	match name:
		"DREAMER":
			defaultBoostStat = 8
		"Lonna":
			defaultBoostStat = 1
		"Damir":
			defaultBoostStat = 2
		"Pepper":
			defaultBoostStat = 8
