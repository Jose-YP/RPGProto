extends Node2D

@onready var playerChoices: Array = [$PlayerMenu/Player1/MenuButton,$PlayerMenu/Player2/MenuButton,$PlayerMenu/Player3/MenuButton]
@onready var playerLevels: Array = [$PlayerMenu/Player1Level,$PlayerMenu/Player2Level,$PlayerMenu/Player3Level]
@onready var playerStats: Array = [$PlayerStats/Player1Stats/RichTextLabel,$PlayerStats/Player2Stats/RichTextLabel,$PlayerStats/Player3Stats/RichTextLabel2]
@onready var playerElements: Array = [$PlayerElements/Player1Element,$PlayerElements/Player2Element,$PlayerElements/Player3Element]
@onready var enemyChoices: Array = [$EnemyMenu/EnemyMenu1/Enemy1/MenuButton,$EnemyMenu/EnemyMenu1/Enemy2/MenuButton,$EnemyMenu/EnemyMenu1/Enemy3/MenuButton,$EnemyMenu/EnemyMenu2/Enemy4/MenuButton,$EnemyMenu/EnemyMenu2/Enemy5/MenuButton]
@onready var enemyLineup: RichTextLabel = $EnemyLineup/RichTextLabel

var Battle: PackedScene = load("res://NewMain.tscn")
var players: Array = ["DREAMER","Lonna","Damir","Pepper"]
var enemies: Array

func _ready():
	pass

func _process(_delta):
	pass

func playerChoiceChanged(index):
	print(playerChoices[index])

func levelChange(index):
	print(playerChoices[index],playerLevels[index].value)

func enemyChoiceChanged(index):
	print(enemyChoices[index])

func _on_help_button_pressed():
	pass # Replace with function body.

func _on_fight_button_pressed():
	pass # Replace with function body.
