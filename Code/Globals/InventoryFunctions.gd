extends Node

var effectiveChipInven
var effectiveGearInven
var effectiveItemInven

func itemHandler():
	pass

func chipHandler():
	for player in Globals.every_player_entity:
		for chip in player.specificData.ChipData:
			for viewingChip in Globals.ChipInventory.inventory:
				if viewingChip == chip:
					chipHandlerResult(chip,player.name,true)

func miniChipHandler(chara,playerChips):
	for chip in playerChips:
		for viewingChip in Globals.ChipInventory.inventory:
			if viewingChip == chip:
				chipHandlerResult(chip,chara,true)

func chipHandlerResult(chip,chara,result):
	if chip.equippedOn == null: #Make sure the chip being operated on isn't null
		chip.equippedOn = 0
	
	match chara:
		"DREAMER":
			if result:
				chip.equippedOn |= 1
			else:
				chip.equippedOn &= ~1
		"Lonna":
			if result:
				chip.equippedOn |= 2
			else:
				chip.equippedOn &= ~2
		"Damir":
			if result:
				chip.equippedOn |= 4
			else:
				chip.equippedOn &= ~4
		"Pepper":
			if result:
				chip.equippedOn |= 8
			else:
				chip.equippedOn &= ~8

func redChipFun():
	pass

func blueChipFun():
	pass

func yellowChipFun():
	pass

func gearApply():
	pass
