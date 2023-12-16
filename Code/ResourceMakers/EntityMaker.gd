extends Resource
class_name entityData

@export_category("names")
@export_range(1,60) var level: int
@export var name: String
@export var species: String
@export var specificData: Resource

@export_group("Resource Stats")
@export var MaxHP: int = 1
@export_range(80,300) var MaxTP: int = 80

@export_group("Battle Stats")
@export_range(0,60) var strength: int
@export_range(0,60) var toughness: int
@export_range(0,60) var ballistics: int
@export_range(0,60) var resistance: int
@export_range(0,60) var speed: int
@export_range(0,60) var luck: int

@export_group("Properties")
@export_enum("Fire","Water","Elec","Neutral") var element: String = "Fire"
@export_flags("Fire","Water","Elec","Slash","Crush","Pierce","All") var Weakness
@export_flags("Fire","Water","Elec","Slash","Crush","Pierce","All") var Resist

@export_group("Attack Properties")
@export_enum("Slash","Crush","Pierce","Neutral") var phyElement: String = "Neutral"
@export var attackData: Move = load("res://BasicAttack.tres")
@export var skillData: Array = [Move]
@export var itemData: Dictionary

@export_group("Temp Property")
@export var XSoft: Array[String] = ["","",""]
@export_flags("Charge","Amp","Targetted","Endure","Peace","Lucky","Reflect","Absorb","Devoid","AnotherTurn") var Condition: int = 0
@export_enum("Fire","Water","Elec","Neutral") var TempElement = element
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive","Healthy") var Ailment: String = "Healthy"
@export_range(0,3) var AilmentNum: int
@export_range(0,3) var XSoftNum: int
@export_range(-.6,.6,.05) var attackBoost: float = 0
@export_range(-.6,.6,.05) var defenseBoost: float = 0
@export_range(-.6,.6,.05) var speedBoost: float = 0
@export_range(-.6,.6,.05) var luckBoost: float = 0
