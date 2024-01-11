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

func redChipFun(entity, chip):
	if chip.NewMove != null:
		entity.specificData.Basics[1] = chip.NewMove
	if chip.PhyNeutralChange != "None":
		pass
	if chip.AffectedMove != "None":
		pass
	if chip.ItemChange != null:
		pass
	if chip.CalcBonus != "None":
		pass
	if chip.CostBonus != null:
		pass

func blueChipFun(entity, chip):
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

func yellowChipFun(entity,chip):
	entity.MaxHP += chip.HP
	entity.specificData.MaxLP += chip.LP
	entity.MaxTP += chip.TP
	
	entity.strength += chip.Strength
	entity.toughness += chip.Toughness
	entity.ballistics += chip.Ballistics
	entity.resistance += chip.Resistance
	entity.speed += chip.Speed
	entity.luck += chip.Luck
	
	if chip.StatSwap:
		yellowStatSwap(entity, chip.FirstSwap, chip.SecondSwap)

func yellowStatSwap(entity, firstStatType, secondStatType):
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

func reverseRed(entity,chip):
	pass

func reverseBlue(entity,chip):
	if chip.NewElement != null:
		entity.element = entity.specificData.permanentElement
	if chip.Condition != null:
		entity.Condition &= ~chip.Condition
	if chip.Immunity != "None":
		entity.Immunity &= ~chip.Immunity
	if chip.Resist != null:
		entity.resist &= ~chip.resist
	if chip.SameElement:
		entity.sameElement = false
	entity.elementMod -= chip.ElementModBoost

func reverseYellow(entity,chip):
	entity.MaxHP -= chip.HP
	entity.specificData.MaxLP -= chip.LP
	entity.MaxTP -= chip.TP
	
	entity.strength -= chip.Strength
	entity.toughness -= chip.Toughness
	entity.ballistics -= chip.Ballistics
	entity.resistance -= chip.Resistance
	entity.speed -= chip.Speed
	entity.luck -= chip.Luck
	
	if chip.StatSwap:
		yellowStatSwap(entity, chip.FirstSwap, chip.SceondSwap)

func gearApply():
	pass
