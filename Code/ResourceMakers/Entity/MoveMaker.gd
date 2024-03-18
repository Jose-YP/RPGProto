extends Resource
class_name Move

@export_category("Information")
@export var name: String = "Attack"
@export_multiline var description: String = "Basic Attack"
@export var TPCost: int = 50
@export_enum("Enemy","Ally","Both") var Which = "Enemy"
@export_enum("Single","Group","Self","All","Random","RandomGroup","KO","None") var Target = "Single"
@export_enum("Fire","Water","Elec","Light","Aurora","Comet","Neutral","Aether") var element: String = "Neutral"
@export_enum("Slash","Crush","Pierce","Neutral") var phyElement = "Neutral"
@export_flags("Physical","Ballistic","Bomb","Buff","Heal","Aura","Summon","Ailment","Misc") var property = 1

@export_subgroup("Costs")
@export_enum("Free","HP","LP","Ammo","MaxHP","Overdrive","Item") var CostType: String = "Free"
@export var cost: float = 0.0
@export var refresh: bool = false

@export_group("Offense")
@export var Power: int = 30
@export var HitNum: int = 1
@export var BaseCrit: int = 0
@export var BaseAilment: int = -200
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","None",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive","PhySoft","EleSoft") var Ailment: String = "None"
@export_range(1,3) var AilmentAmmount: int = 1

@export_group("Healing")
@export var percentage: bool
@export var revive: bool
@export var reset: bool
@export var healing: int = 0
@export_enum("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","None",
"Protected","Dumbfounded","Miserable","Worn Out", "Explosive", "Negative","Chemical",
"Mental","Positive","XSoft","All") var HealedAilment: String = "None"
@export_range(0,3) var HealAilAmmount: int

@export_group("Other")
@export var BoostAmmount: int = 0
@export_flags("Attack","Defense","Speed","Luck") var BoostType = 0
@export_flags("Charge","Amp","Targetted","Endure","Peace","Lucky","Reflect","Absorb","Devoid","AnotherTurn") var Condition: int = 0
@export_enum("None","BodyBroken","WillWrecked","LowTicks","CritDouble") var Aura: String = "None"
@export_enum("Fire","Water","Elec","Neutral","TWin","TLose","UWin","ULose","None") var ElementChange: String = "None"
@export var Summon: Array = []
@export var SwapSummon: bool = false
@export var Misc: Script
