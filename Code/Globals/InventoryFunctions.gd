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
	if chip.NewElement != null:
		entity.element = chip.NewElement
	if chip.Condition != null:
		entity.Condition |= chip.Condition
	if chip.Immunity != "None":
		entity.Immunity |= chip.Immunity
	if chip.Resist != null:
		entity.resist |= chip.resist
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
		var firstStat = yellowStatSwap(entity, chip.FirstSwap)
		var secondStat = yellowStatSwap(entity, chip.SecondSwap)
		var holdStat = firstStat
		
		firstStat = secondStat
		secondStat = firstStat

func yellowStatSwap(entity, StatType):
	match StatType:
		"Strength":
			return entity.strength
		"Toughness":
			return entity.toughness
		"Ballistics":
			return entity.ballistics
		"Resistance":
			return entity.resistance
		"Speed":
			return entity.speed
		"Luck":
			return entity.luck

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
		var firstStat = yellowStatSwap(entity, chip.FirstSwap)
		var secondStat = yellowStatSwap(entity, chip.SecondSwap)
		var holdStat = firstStat
		
		firstStat = secondStat
		secondStat = firstStat

func gearApply():
	pass
