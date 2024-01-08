extends Resource
class_name Gear

@export_category("Information")
@export var name: String = "Basic Gear"
@export_multiline var description: String = "Does something"
@export_enum("DREAMER","Lonna","Damir","Pepper") var Char = "DREAMER"

@export_group("Stat Bonuses")
@export var Strength: int = 0
@export var Toughness: int = 0
@export var Ballistics: int = 0
@export var Resistance: int = 0
@export var Speed: int = 0
@export var Luck: int = 0

@export_group("Calcs")
@export_enum("None","Drain","ElementAdv","AilmentHit","LPCost") var calcBonus = "None"
@export_range(0,1,.01) var calcAmmount: float
@export_enum("None","Explode","LPDrain","DumbfoundedCrit") var miscCalc = "None"
