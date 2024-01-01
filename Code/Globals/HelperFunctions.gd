extends Node

var elementFlags = {
	1:"Fire",
	2:"Water",
	4:"Elec",
	8:"Slash",
	16:"Crush",
	32:"Pierce",
	64:"Light",
	128:"Comet",
	256:"Aurora"}
var elementStrings = {
	"Fire":1, 
	"Water":2, 
	"Elec":4, 
	"Slash":8,
	"Crush":16,
	"Pierce":32,
	"Light":64,
	"Comet":128,
	"Aurora":256}

var propertyFlags = {
	1:"Physical",
	2:"Ballistic",
	4:"Bomb",
	8:"Buff",
	16:"Heal",
	32:"Aura",
	64:"Summon",
	128:"Ailment",
	256:"Misc"}
var propertyStrings = {
	"Physical": 1,
	"Ballistic":2,
	"Bomb":4,
	"Buff":8,
	"Heal":16,
	"Aura":32,
	"Summon":64,
	"Ailment":128,
	"Misc":256}

var conditionFlags = {
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
var conditionStrings ={
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

var boostFlags = {
	1: "Attack",
	2: "Defense",
	4: "Speed",
	8: "Luck" }
var boostStrings = {
	"Attack": 1,
	"Defense": 2,
	"Speed": 4,
	"Luck": 8
}

func inCaseNone(property):
	if property == null:
		property = 0

func String_to_Flag(property,type):
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
	
	if string_translate.has(property):
		return string_translate[property]
	return false

func Flag_to_String(flag,type):
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

func NullorAppend(list,value,XSoft=true,maxSize=3):
	for i in range(list.size()):
		if list[i] == null or list[i] == "":
			print("Found a null")
			list[i] = value
			return list
	
	if XSoft:
		if list.size() < maxSize:
			print("list", value)
			list.append(value)
			return list
	
	return list

func emptyXSoftSlots(list):
	var nulls: int = 0
	for i in range(list.size()):
		if list[i] == null or list[i] == "":
			print("Found a null")
			nulls += 1
	
	return nulls

func colorElements(element,inbetween = ""):
	var Elements = ""
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
	return Elements
