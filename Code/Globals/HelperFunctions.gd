extends Node

var elementFlags: Dictionary = {
	1: "Fire",
	2: "Water",
	4: "Elec",
	8: "Slash",
	16: "Crush",
	32: "Pierce",
	64: "Comet",
	128: "Light",
	256: "Aurora",
	512: "All"}
var elementStrings: Dictionary = {
	"Fire": 1, 
	"Water": 2, 
	"Elec": 4, 
	"Slash": 8,
	"Crush": 16,
	"Pierce": 32,
	"Comet": 64,
	"Light": 128,
	"Aurora": 256,
	"All": 512}

var propertyFlags: Dictionary = {
	1:"Physical",
	2:"Ballistic",
	4:"Bomb",
	8:"Buff",
	16:"Heal",
	32:"Aura",
	64:"Summon",
	128:"Ailment",
	256:"Misc"}
var propertyStrings: Dictionary = {
	"Physical": 1,
	"Ballistic":2,
	"Bomb":4,
	"Buff":8,
	"Heal":16,
	"Aura":32,
	"Summon":64,
	"Ailment":128,
	"Misc":256}

var conditionFlags: Dictionary = {
	1:"Charge",
	2:"Amp",
	4:"Targetted",
	8:"Endure",
	16:"Peace",
	32:"Lucky",
	64:"Reflect",
	128:"Absorb",
	256:"Devoid",
	512:"AnotherTurn"}
var conditionStrings: Dictionary ={
	"Charge":1,
	"Amp":2,
	"Targetted":4,
	"Endure":8,
	"Peace":16,
	"Lucky":32,
	"Reflect":64,
	"Absorb":128,
	"Devoid":256,
	"AnotherTurn":512}

var boostFlags: Dictionary = {
	1: "Attack",
	2: "Defense",
	4: "Speed",
	8: "Luck"}
var boostStrings: Dictionary = {
	"Attack": 1,
	"Defense": 2,
	"Speed": 4,
	"Luck": 8}

var ailmentStrings: Dictionary = {
	"Overdrive": 1,
	"Poison": 2,
	"Reckless": 4,
	"Exhausted": 8,
	"Rust": 16,
	"Stun": 32,
	"Curse": 64,
	"Protected": 128,
	"Dumbfounded": 256,
	"Miserable": 512,
	"Worn Out": 1024,
	"Explosive": 2048} #XSOFT will be 4096

func inCaseNone(property) -> void:
	if property == null:
		property = 0

func String_to_Flag(property,type)  -> int:
	var string_translate
	match type:
		"Element":
			string_translate = elementStrings
		"Property":
			string_translate = propertyStrings
		"Condition":
			string_translate = conditionStrings
		"Boost":
			string_translate = boostStrings
		"Ailment":
			string_translate = ailmentStrings
	
	if string_translate.has(property):
		return string_translate[property]
	return false

func Flag_to_String(flag,type)  -> String:
	var flag_translate
	match type:
		"Element":
			flag_translate = elementFlags
		"Property":
			flag_translate = propertyFlags
		"Condition":
			flag_translate = conditionFlags
		"Boost":
			flag_translate = boostFlags
	
	if flag_translate.has(flag):
		return flag_translate[flag]
	
	return ""

func BoostTranslation(entityBoosts) -> String:
	var BoostString: String
	if entityBoosts & 1:
		BoostString = str(boostFlags[1])
	if entityBoosts & 2:
		BoostString = ifNotEmpty(BoostString,str("+",boostFlags[2]))
	if entityBoosts & 4:
		BoostString = ifNotEmpty(BoostString,str("+",boostFlags[4]))
	if entityBoosts & 8:
		BoostString = ifNotEmpty(BoostString,str("+",boostFlags[8]))
	return BoostString

func NullorAppend(list,value,XSoft=true,maxSize=3) -> Array:
	print(list, value)
	
	for i in range(list.size()):
		if list[i] == null or list[i] == "":
			list[i] = value
			return list
	
	if XSoft:
		if list == null:
			list = ["","",""]
		elif list.size() < maxSize:
			list.append(value)
			return list
	
	return list

func emptyXSoftSlots(list) -> int:
	var nulls: int = 0
	for i in range(list.size()):
		if list[i] == null or list[i] == "":
			nulls += 1
	
	return nulls

func colorElements(element,inbetween = "") -> String:
	var Elements = element
	if inbetween == "":
		inbetween = str(element)
	
	match element:
		"Fire":
			Elements = str("[color=red]",inbetween,"[/color]")
		"Water":
			Elements = str("[color=aqua]",inbetween,"[/color]")
		"Elec":
			Elements = str("[color=gold]",inbetween,"[/color]")
		"Slash":
			Elements = str("[color=forest_green]",inbetween,"[/color]")
		"Crush":
			Elements = str("[color=olive]",inbetween,"[/color]")
		"Pierce":
			Elements = str("[color=orange]",inbetween,"[/color]")
		"Comet":
			Elements = str("[color=blue_violet]",inbetween,"[/color]")
		"Light":
			Elements = str("[color=navajo_white]",inbetween,"[/color]")
		"Aurora":
			Elements = str("[color=spring_green]",inbetween,"[/color]")
		_:
			Elements = str("[color=white]",inbetween,"[/color]")
	return Elements

func ifNotEmpty(string, added) -> String:
	if string != null:
		return str(string, added)
	else:
		return str(added)

func findCommon(arr, most = true):
	var value = arr[0]
	var arrayMap: Dictionary = {}
	
	#initialize every value
	for i in arr:
		arrayMap[i] = 0
	
	#Count every value
	for i in arr:
		arrayMap[i] += 1
	
	for item in arrayMap.keys():
		#Search for most or least depending on most parameter
		if ((most and arrayMap[value] < arrayMap[item]) or 
		(not most and arrayMap[value] > arrayMap[item])):
			value = item
		
		#If two different things in an array have the same value, return null
		elif value != item and arrayMap[value] == arrayMap[item]:
			print(value, item, "Found in find Common")
			return null
	
	return value
