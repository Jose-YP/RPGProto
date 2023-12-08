extends Node2D

@export var playerTurn: bool = true
@onready var cursor: Sprite2D = $CursorPng100722
@onready var enemyOrder: Array = [$Enemies/Node2D,$Enemies/Node2D2,$Enemies/Node2D3]
@onready var playerOrder: Array = [$Players/Node2D,$Players/Node2D2,$Players/Node2D3]

var i: int = 0
var team: Array = []

func _ready():
	if playerTurn:
		team = playerOrder
	else:
		team = enemyOrder

func _process(delta):
	if playerTurn:
		team = playerOrder
	else:
		team = enemyOrder
	
	team_handler(team)

func team_handler(team):
	cursor.position = team[i].position + Vector2(-30,-30)
	pass

func _on_control_advance():
	i += 1
	if i > (team.size() - 1):
		i = 0
		playerTurn = !playerTurn
