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
	
	if flag_translate.has(flag):
		return flag_translate[flag]
	return false
