extends "res://Code/SceneCode/Entities/enemy.gd"

var eData: Enemy
var canBuff: bool = false
var allies: Array = []
var opp: Array = []
var buffedNum: Array[int] = []
var buffedFlags: Array[int] = []

func basicSelect(allowed):
	var canAilm: bool = false
	
	for entity in groupAilments("Opposing", true):
		if (entity != "Mental" or entity != "Chemical"):
			canAilm = true
	
	if canAilm:
		for entity in opp:
			if entity.data.AilmentNum < eData.oppAilmentPreference:
				focusIndex = entity.ID
				return getEnumMoves(allowed, "Ailment").pick_random()
	
	var index = randi()%allowed.size()
	return allowed[index]

#-----------------------------------------
#TARGETTING
#-----------------------------------------
func Single(targetting, _move):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex

func Group(targetting, _move):
	var defenderIndex = randi() % targetting.size()
	return defenderIndex
