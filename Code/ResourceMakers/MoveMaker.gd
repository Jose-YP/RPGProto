extends Resource
class_name Move

@export_category("Information")
@export var name: String = "Attack"
@export var description: String = "Basic Attack"
@export var TPCost: int = 60
@export_enum("Enemy","Ally","Both") var Which = "Enemy"
@export_enum("Single","Group","Self","All","Random","None") var Target = "Single"
@export_enum("Fire","Water","Elec","Light","Aurora","Comet","Neutral","Aether") var element = "Neutral"
@export_enum("Slash","Crush","Pierce","Neutral") var phyElement = "Neutral"
@export_flags("Physical","Ballistic","Bomb","Buff","Heal","Aura","Summon","Ailment","Misc") var property = 1

@export_subgroup("Player Exclusive")
@export_enum("Free","HP","LP","Ammo","MaxHP") var CostType = "Free"
@export var cost: float

@export_group("Offense")
@export var Power: int = 60
@export var HitNum: int = 1
@export var BaseCrit: int = 0
@export var BaseAilment: int = -200
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","None",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive") var Ailment: String = "None"
@export_range(-3,3) var AilmentAmmount: int

@export_group("Healing")
@export var percentage: bool
@export var revive: bool
@export var reset: bool
@export var healing: int
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","None",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive", "Negative","Physical",
"Mental","Positive","All") var HealedAilment = "None"
@export_range(0,3) var HealAilAmmount: int

@export_group("Other")
@export_flags("Attack","Defense","Speed","Luck") var BoostType
@export var BoostAmmount: int = 0
@export_flags("Charge","Amp","Targetted","Endure","Peace","Lucky","Reflect","Absorb","Devoid") var Condition
@export_enum("BodyBroken","WillWrecked","LowTicks","FireAug","WaterAug","ElecAug","SlashAug","CrushAug",
"PierceAug","FireDamp","WaterDamp","ElecDamp","SlashDamp","CrushDamp","PierceDamp",) var Aura
@export_enum("Fire","Water","Elec","Neutral","TWin","TLose","UWin","ULose") var ElementChange
@export var Summon: Array
@export var Misc: String
