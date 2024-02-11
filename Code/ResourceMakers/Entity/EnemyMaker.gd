extends Resource
class_name Enemy

@export_category("Drops")
@export var xp: int
@export var cents: int

@export_category("Properties")
@export var Boss: bool
@export var Revivable: bool

@export_group("AI")
@export var AICodePath: String
@export var Priorities: Array = ["Attack","Buff","Debuff","Element",
"Condition","Heal","Aura","Summon","Ailment","Misc"] #Reordered depending on user
@export var PriorityChance: Array = [50,50,50,50,
50,50,50,50,50,50] #When multiple conditions are met use chances that are before 100

@export_subgroup("Resource Preferences")
@export_range(0,1,.05) var selfHPPreference: float = .9
@export_range(0,1,.05) var allyHPPreference: float = .9
@export_range(0,1,.05) var oppHPPreference: float = .9

@export_subgroup("Ailment Preferences")
@export_range(0,3) var selfAilmentPreference: int = 0
@export_range(0,3) var allyAilmentPreference: int = 0
@export_range(0,3) var oppAilmentPreference: int = 0
@export_flags("Overdrive","Poison","Reckless","Exhausted","Rust","Stun","Curse","Protected","Dumbfounded",
"Miserable","Worn Out", "Explosive","XSoft") var favoredAilments: int = 0
@export_range(0,3) var selfXSoftPreference: int = 0
@export_range(0,3) var allyXSoftPreference: int = 0
@export_range(0,3) var oppXSoftPreference: int = 0
@export_flags("Fire","Water","Elec","Slash","Crush","Pierce") var favoredXSoftTypes: int

@export_subgroup("Stat Buff Preferences")
@export_range(0,4) var selfBuffNumPreference: int = 1
@export_range(-.6,.6,.05) var selfBuffAmmountPreference: float = .5
@export_range(0,4) var allyBuffNumPreference: int = 1
@export_range(-.6,.6,.05) var allyBuffAmmountPreference: float = .5
@export_range(0,4) var oppBuffNumPreference: int = 1
@export_range(-.6,.6,.05) var oppBuffAmmountPreference: float = .5

@export_subgroup("Other Buff Preferences")
@export_flags("Charge","Amp","Targetted","Endure","Peace","Lucky",
"Reflect","Absorb","Devoid","AnotherTurn") var favoredCondition: int = 763
@export_enum("Fire","Water","Elec","Neutral") var selfFavoredElement = "Neutral"
@export_enum("Fire","Water","Elec","Neutral") var allyFavoredElement = "Neutral"
@export_enum("Fire","Water","Elec","Neutral") var oppFavoredElement = "Neutral"

@export_subgroup("Other Preferences")
@export_flags("BodyBroken","WillWrecked","DoubleCrits","LowTP") var favoredAuras: int = 15
@export var favoredAlly: String
@export_enum("DREAMER","Lonna","Damir","Pepper", "None") var hatedOpponent: String = "None"
