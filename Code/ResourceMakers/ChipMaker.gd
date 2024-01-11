extends Resource
class_name Chip

@export_category("Information")
@export var name: String = "Basic"
@export_multiline var description: String = "Does something"
@export var CpuCost: int = 4
@export_enum("Red","Blue","Yellow") var ChipType = "Red"
@export_flags("DREAMER","Lonna","Damir","Pepper") var equippedOn = 0
@export var other: String

@export_group("Red Properties")
@export_subgroup("Move Changes")
@export var NewMove: Move
@export_enum("Slash","Crush","Pierce","None") var PhyNeutralChange = "None"
@export_enum("None","Basic","Boost") var AffectedMove
@export_enum("Single","Group","All","Random") var NewTarget
@export_enum("Physical","Ballistic","Freebie") var ItemChange
@export_subgroup("Calc Bonuses")
@export_enum("None","Drain","AilmentHit","CritChance") var calcBonus = "None"
@export_range(0,100,.05) var calcAmmount: float
@export_enum("HP","LP","HP/LP","TP") var costBonus
@export_range(0,2,.01) var costMod

@export_group("Blue Properties")
@export_subgroup("Properties")
@export_enum("Fire","Water","Elec","Neutral") var NewElement
@export_enum("Charge","Amp","Targetted","Endure","Peace","Lucky","Reflect","Absorb") var Condition
@export_range(-1,1,.05) var ElementModBoost: float
@export var SameElement: bool = false
@export_subgroup("Defense")
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","None","Protected",
"Dumbfounded","Miserable","Worn Out", "Explosive","XSoft","Mental","Chemical","Debuff") var immunity = "None"
@export_enum("Fire","Water","Elec","Slash","Crush","Pierce", "Ailment") var resist

@export_group("Yellow Properties")
@export_subgroup("Resource Stat Bonuses")
@export var HP: int = 0
@export var LP: int = 0
@export var TP: int = 0
@export_subgroup("Battle Stat Bonuses")
@export var Strength: int = 0
@export var Toughness: int = 0
@export var Ballistics: int = 0
@export var Resistance: int = 0
@export var Speed: int = 0
@export var Luck: int = 0
@export_subgroup("Battle Stat Manip")
@export var StatSwap: bool = false
@export_enum("Strength","Toughness","Ballistics","Resistance","Speed","Luck") var FirstSwap
@export_enum("Strength","Toughness","Ballistics","Resistance","Speed","Luck") var SecondSwap
