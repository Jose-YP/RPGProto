extends Node

var HariqMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/PlayerHariq.tres")
var BahrMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/PlayerBahr.tres")
var SaeiqaMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/PlayerSeiqa.tres")
var DawMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/Daw'.tres")
var AlmudhanibMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/Almudhanib.tres")
var AlshafaqMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/Alshafaq.tres")
var AlqamarMove: Move = preload("res://Resources/Move Data/Player Moves/ChipMoves/Alqamar.tres")

func itemHandler(inventory) -> void:
	for player in Globals.every_player_entity:
		for item in player.itemData:
			for viewingItem in inventory:
				if viewingItem == item:
					itemHandlerResult(item,player.itemData[item],player.name,true)

func miniItemHandler(chara,playerItems,inventory, removing = false) -> void:
	for item in playerItems:
		for viewingItem in inventory:
			if viewingItem == item:
				itemHandlerResult(item,playerItems[item],chara,true)
			elif removing:
				itemHandlerResult(item,playerItems[item],chara,false) 

func itemHandlerResult(item,ammount,chara,result) -> void:
	if item.equippedOn == null: #Make sure the chip being operated on isn't null
		item.equippedOn = 0
	
	match chara:
		"DREAMER":
			if result:
				item.equippedOn |= 1
				item.ownerArray[0] = ammount
			else:
				item.equippedOn &= ~1
				item.ownerArray[0] = 0
		"Lonna":
			if result:
				item.equippedOn |= 2
				item.ownerArray[1] = ammount
			else:
				item.equippedOn &= ~2
				item.ownerArray[1] = 0
		"Damir":
			if result:
				item.equippedOn |= 4
				item.ownerArray[2] = ammount
			else:
				item.equippedOn &= ~4
				item.ownerArray[2] = 0
		"Pepper":
			if result:
				item.equippedOn |= 8
				item.ownerArray[3] = ammount
			else:
				item.equippedOn &= ~8
				item.ownerArray[3] = 0

func itemAutofill(item,chara,result) -> void:
	if item.autofill == null: #Make sure the chip being operated on isn't null
		item.autofill = 0
	
	match chara:
		"DREAMER":
			if result:
				item.autofill |= 1
			else:
				item.autofill &= ~1
		"Lonna":
			if result:
				item.autofill |= 2
			else:
				item.autofill &= ~2
		"Damir":
			if result:
				item.autofill |= 4
			else:
				item.autofill &= ~4
		"Pepper":
			if result:
				item.autofill |= 8
			else:
				item.autofill &= ~8

func applyItems(chara, inventory) -> void:
	for item in chara.itemData:
		for invItem in inventory:
			if invItem.name == item.name:
				if invItem.autofill & Globals.charFlag(chara):
					applyAutofill(chara,invItem,item)
				else:
					applyItem(item,invItem, chara)

func applyItem(item,invItem, chara) -> void: 
	invItem.ownerArray[Globals.charNum(chara)] = chara.itemData[item]

func applyAutofill(chara,invItem, item = null) -> void:
	if item == null: item = invItem
	
	if invItem.currentItems >= invItem.maxItems:
		chara.itemData[item] = invItem.maxItems
		invItem.ownerArray[Globals.charNum(chara)] = invItem.maxItems
	elif invItem.currentItems != 0:
		chara.itemData[item] = invItem.currentItems
		invItem.ownerArray[Globals.charNum(chara)] = invItem.currentItems

func addItemintoInven(item, ammount, chara):
	item.ownerArray[Globals.charNum(chara)] += ammount
	clamp(item.currentItems, 0, item.maxCarry)

func findItem(item, chara) -> int:
	var index = 0
	for playerItem in chara.itemData:
		if playerItem.name == item.name:
			return index
		else:
			index += 1
	return 90 #90 is the error value

func findCurrentNum(item1, item2) -> bool:
	var count1: int = 0
	var count2: int = 0
	var num1: int  = 0
	var num2: int = 0
	
	for i in range(4):
		count1 += item1.ownerArray[i]
		count2 += item2.ownerArray[i]
	
	num1 = item1.maxCarry - count1
	num2 = item2.maxCarry - count2
	
	if num1 > num2: return true
	elif num1 == num2: return findOwnersNum(item1, item2)
	return false #Only returns false if they are truly equal

func findOwnersNum(item1, item2) -> bool:
	var num1: int = 0
	var num2: int = 0
	var secondary1: int = 0 #Secondary only used when owner num is equal
	var secondary2: int = 0
	
	for i in range(4):
		if item1.ownerArray[i] != 0:
			num1 += 1
			match i: #Formatted to prioritize first character
				0: secondary1 += 8
				1: secondary1 += 4
				2: secondary1 += 2
				3: secondary1 += 1
		if item2.ownerArray[i] != 0:
			num2 += 1
			match i:
				0: secondary2 += 8
				1: secondary2 += 4
				2: secondary2 += 2
				3: secondary2 += 1
	
	if num1 > num2: return true
	elif num1 == num2:
		if secondary1 > secondary2: return true
	return false

func chipHandler(inventory) -> void:
	for player in Globals.every_player_entity:
		for chip in player.specificData.ChipData:
			for viewingChip in inventory:
				if viewingChip == chip:
					chipHandlerResult(chip,player.name,true)

func miniChipHandler(chara,playerChips,inventory, removing = false) -> void:
	for chip in playerChips:
		for viewingChip in inventory:
			if viewingChip == chip:
				chipHandlerResult(viewingChip,chara,true)
			elif removing:
				chipHandlerResult(viewingChip,chara,false)

func chipHandlerResult(chip,chara,result) -> void:
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

func redChipFun(entity, chip) -> void:
	if chip.NewMove != null:
		entity.specificData.ThirdMoveElement |= chip.ThirdMoveElement
		ThirdMoveDetermine(entity, entity.specificData.ThirdMoveElement)
	if chip.newPhyElement != "None" and chip.newPhyElement != "":
		entity.phyElement = chip.newPhyElement
	if chip.AffectedMove == "Boost":
		entity.specificData.boostTarget = chip.NewTarget
	elif chip.AffectedMove == "Basic":
		entity.specificData.basicTarget = chip.NewTarget
	if chip.addedBoost != 0 and chip.addedBoost != null:
		entity.specificData.boostStat |= chip.addedBoost
	if chip.ItemChange != null:
		entity.ItemChange = chip.ItemChange
	if chip.calcBonus != 0 and chip.calcBonus != null:
		entity.calcBonus |= chip.calcBonus
		if chip.calcBonus & 1:
			entity.drainCalcAmmount += chip.calcAmmount
		if chip.calcBonus & 2:
			entity.ailmentCalcAmmount += chip.calcAmmount
		if chip.calcBonus & 4:
			entity.critCalcAmmount += chip.calcAmmount
	if chip.costBonus != null:
		entity.costBonus |= chip.costBonus
		if chip.costBonus & 1:
			entity.HpCostMod += chip.costMod
		if chip.costBonus & 2:
			entity.LpCostMod += chip.costMod
		if chip.costBonus & 4:
			entity.TpCostMod += chip.TpCostMod

func ThirdMoveDetermine(entity, elementMix) -> void:
	match elementMix: #FIRE = 1 | WATER = 2 | ELEC = 4
		1:
			entity.specificData.Basics[1] = HariqMove
		2:
			entity.specificData.Basics[1] = BahrMove
		4:
			entity.specificData.Basics[1] = SaeiqaMove
		3:
			entity.specificData.Basics[1] = AlshafaqMove
		5:
			entity.specificData.Basics[1] = DawMove
		6:
			entity.specificData.Basics[1] = AlmudhanibMove
		7:
			entity.specificData.Basics[1] = AlqamarMove

func blueChipFun(entity, chip) -> void:
	if chip.NewElement != "None" and chip.NewElement != "":
		entity.element = chip.NewElement
	if chip.Condition != null:
		entity.Condition |= chip.Condition
	if chip.Immunity != "None":
		entity.Immunity |= chip.Immunity
	if chip.strong != null:
		entity.strong |= chip.strong
	if chip.SameElement:
		entity.sameElement = true
	
	entity.soloElementMod += chip.ElementModBoost

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

func gearApply(entity, gear) -> void:
	entity.specificData.GearData = gear
	if gear != null:
		gear.equipped = true
		
		entity.strength += gear.Strength
		entity.toughness += gear.Toughness
		entity.ballistics += gear.Ballistics
		entity.resistance += gear.Resistance
		entity.speed += gear.Speed
		entity.luck += gear.Luck
		
		if gear.calcBonus & 1:
			entity.calcBonus |= 1
			entity.drainCalcAmmount = gear.calcAmmount
		if gear.calcBonus & 2:
			entity.calcBonus |= 2
			entity.ailmentCalcAmmount = gear.calcAmmount
		if gear.calcBonus & 4:
			entity.calcBonus |= 4
			entity.critCalcAmmount = gear.calcAmmount
		if gear.calcBonus & 8:
			entity.groupElementMod = gear.calcAmmount
