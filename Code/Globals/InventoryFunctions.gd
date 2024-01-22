extends Node

var effectiveChipInven
var effectiveGearInven
var effectiveItemInven

func itemHandler(inventory) -> void:
	for player in Globals.every_player_entity:
		for chip in player.ItemData:
			for viewingChip in inventory:
				if viewingChip == chip:
					chipHandlerResult(chip,player.name,true)

func chipHandler(inventory) -> void:
	for player in Globals.every_player_entity:
		for chip in player.specificData.ChipData:
			for viewingChip in inventory:
				if viewingChip == chip:
					chipHandlerResult(chip,player.name,true)

func miniChipHandler(chara,playerChips,inventory) -> void:
	for chip in playerChips:
		for viewingChip in inventory:
			if viewingChip == chip:
				chipHandlerResult(viewingChip,chara,true)
			else:
				chipHandlerResult(viewingChip,chara,false)

func chipHandlerResult(chip,chara,result) -> void:
	if chip.equippedOn == null: #Make sure the chip being operated on isn't null
		chip.equippedOn = 0
	
	match chara:
		"DREAMER":
			if result:
				print("Equipped", chip.name)
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

func redChipFun(entity, chip) -> void:
	if chip.NewMove != null:
		entity.specificData.Basics[1] = chip.NewMove
	if chip.newPhyElement != "None" and chip.newPhyElement != "":
		entity.phyElement = chip.newPhyElement
	if chip.AffectedMove == "Boost":
		entity.specificData.boostTarget = chip.NewTarget
	elif chip.AffectedMove == "Basic":
		entity.specificData.basicTarget = chip.NewTarget
	if chip.ItemChange != null:
		entity.ItemChange = chip.ItemChange
	if chip.calcBonus != "None":
		entity.calcBonus = chip.calcBonus
		entity.calcAmmount = chip.calcAmmount
	if chip.costBonus != null:
		entity.costBonus = chip.costBonus
		entity.costMod = chip.costMod

func blueChipFun(entity, chip) -> void:
	if chip.NewElement != "None" and chip.NewElement != "":
		entity.element = chip.NewElement
	if chip.Condition != null:
		entity.Condition |= chip.Condition
	if chip.Immunity != "None":
		entity.Immunity |= chip.Immunity
	if chip.Resist != null:
		entity.Resist |= chip.Resist
	if chip.SameElement:
		entity.sameElement = true
	
	entity.elementMod += chip.ElementModBoost

func yellowChipFun(entity,chip) -> void:
	entity.MaxHP += chip.HP
	entity.specificData.MaxLP += chip.LP
	entity.MaxTP += chip.TP
	if chip.CpuCost < 0:
		entity.specificData.MaxCPU += (chip.CpuCost * -1)
	
	entity.strength += chip.Strength
	entity.toughness += chip.Toughness
	entity.ballistics += chip.Ballistics
	entity.resistance += chip.Resistance
	entity.speed += chip.Speed
	entity.luck += chip.Luck
	
	if chip.StatSwap:
		yellowStatSwap(entity, chip.FirstSwap, chip.SecondSwap)

func yellowStatSwap(entity, firstStatType, secondStatType) -> void:
	var firstStat
	
	match firstStatType:
		"Strength":
			firstStat = entity.strength
			match secondStatType:
				"Toughness":
					entity.strength = entity.toughness
					entity.toughness = firstStat
				"Ballistics":
					entity.strength = entity.ballistics
					entity.ballistics = firstStat
				"Resistance":
					entity.strength = entity.resistance
					entity.resistance = firstStat
				"Speed":
					entity.strength = entity.speed
					entity.speed = firstStat
				"Luck":
					entity.strength = entity.luck
					entity.luck = firstStat
				_:
					print("Ah")
		"Toughness":
			firstStat = entity.toughness
			match secondStatType:
				"Strength":
					entity.toughness = entity.strength
					entity.strength = firstStat
				"Ballistics":
					entity.toughness = entity.ballistics
					entity.ballistics = firstStat
				"Resistance":
					entity.toughness = entity.resistance
					entity.resistance = firstStat
				"Speed":
					entity.toughness = entity.speed
					entity.speed = firstStat
				"Luck":
					entity.toughness = entity.luck
					entity.luck = firstStat
				_:
					print("Ah")
		"Ballistics":
			firstStat = entity.ballistics
			match secondStatType:
				"Strength":
					entity.ballistics = entity.strength
					entity.strength = firstStat
				"Toughness":
					entity.ballistics = entity.toughness
					entity.toughness = firstStat
				"Resistance":
					entity.ballistics = entity.resistance
					entity.resistance = firstStat
				"Speed":
					entity.ballistics = entity.speed
					entity.speed = firstStat
				"Luck":
					entity.ballistics = entity.luck
					entity.luck = firstStat
				_:
					print("Ah")
		"Resistance":
			firstStat = entity.resistance
			match secondStatType:
				"Strength":
					entity.resistance = entity.strength
					entity.strength = firstStat
				"Toughness":
					entity.resistance = entity.toughness
					entity.toughness = firstStat
				"Ballistics":
					entity.resistance = entity.ballistics
					entity.ballistics = firstStat
				"Speed":
					entity.resistance = entity.speed
					entity.speed = firstStat
				"Luck":
					entity.resistance = entity.luck
					entity.luck = firstStat
				_:
					print("Ah")
		"Speed":
			firstStat = entity.speed
			match secondStatType:
				"Strength":
					entity.speed = entity.strength
					entity.strength = firstStat
				"Toughness":
					entity.speed = entity.toughness
					entity.toughness = firstStat
				"Ballistics":
					entity.speed = entity.ballistics
					entity.ballistics = firstStat
				"Resistance":
					entity.speed = entity.resistance
					entity.resistance = firstStat
				"Luck":
					entity.speed = entity.luck
					entity.luck = firstStat
				_:
					print("Ah")
		"Luck":
			firstStat = entity.luck
			match secondStatType:
				"Strength":
					entity.luck = entity.strength
					entity.strength = firstStat
				"Toughness":
					entity.luck = entity.toughness
					entity.toughness = firstStat
				"Ballistics":
					entity.luck = entity.ballistics
					entity.ballistics = firstStat
				"Resistance":
					entity.luck = entity.resistance
					entity.resistance = firstStat
				"Speed":
					entity.luck = entity.speed
					entity.speed = firstStat
				_:
					print("Ah")
		_:
			print("Ah")

func gearApply() -> void:
	pass
