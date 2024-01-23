extends PanelContainer

@onready var focus: Button = $Button
@onready var inBetween: Marker2D = $Marker2D
@onready var final: Marker2D = $Marker2D2
@onready var icon: TextureRect = $Button/MarginContainer/Item1/TextureRect
@onready var itemText: RichTextLabel = $Button/MarginContainer/Item1/MarginContainer/RichTextLabel

signal getDesc(data)
signal startSelect(data)

var ItemData: Item
var maxNum: int
var currentNum: int
var inChar: bool = true

func _ready():
	

func _on_button_focus_entered() -> void:
	getDesc.emit(self)
