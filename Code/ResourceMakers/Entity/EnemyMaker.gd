extends Resource
class_name Enemy

@export_category("Drops")
@export var xp: int
@export var cents: int

@export_category("Properties")
@export var Boss: bool
@export var Revivable: bool

@export_category("AI")
@export var AICode: Script #Code that determines what the user will perceive, when and what after
@export var AICodePath: String
@export var Priorities: Array = ["Attack","Buff","Debuff","Element",
"Condition","Heal","Aura","Summon","Ailment","Misc"] #Reordered depending on user
@export var PriorityChance: Array = [50,50,50,50,
50,50,50,50,50,50] #When multiple conditions are met use chances that are before 100
@export_flags("BodyBroken","WillWrecked","DoubleCrits","LowTP") var favoredAuras: int = 15
#If they're present they'll be prioritized
@export var favoredAlly: String
@export_enum("DREAMER","Lonna","Damir","Pepper", "None") var hatedOpponent: String = "None"
#Placeholder
@export_enum("Random","Single Strike", "Pick off","Support", "Debuff") var AIType: String = "Random"
