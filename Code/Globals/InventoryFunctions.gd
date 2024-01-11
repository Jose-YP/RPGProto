extends Node

var effectiveChipInven
var effectiveGearInven
var effectiveItemInven

func itemHandler():
	pass

func chipHandler():
	for player in Globals.current_player_entities:
		for chip in player.specificData.ChipData:
			for viewingChip in Globals.ChipInventory.inventory:
				if viewingChip == chip:
					chipHandlerResult(player.name,true)

func miniChipHandler(chara,playerChips):
	for chip in playerChips:
		for viewingChip in Globals.ChipInventory.inventory:
			if viewingChip == chip:
				chipHandlerResult(chara,true)

func chipHandlerResult(chara,result):
	pass

func redChipFun():
	pass

func blueChipFun():
	pass

func yellowChipFun():
	pass

func gearApply():
	pass
