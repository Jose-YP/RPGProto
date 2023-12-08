extends Resource
class_name Entity

@export_category("names")
@export var name: String
@export var species: String

@export_category("Resource Stats")
@export var MaxHP: int
@export var MaxTP: int

@export_category("Battle Stats")
@export_range(0,60) var strength: int
@export_range(0,60) var toughness: int
@export_range(0,60) var ballistics: int
@export_range(0,60) var resistance: int
@export_range(0,60) var speed: int
@export_range(0,60) var luck: int

@export_category("Properties")
@export_enum("Fire","Water","Elec","Neutral") var element: String
@export_enum("Slash","Crush","Pierce","Neutral") var phyElement: String
