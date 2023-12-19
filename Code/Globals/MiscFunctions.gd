extends Node

func miscFunCrash(reciever,recieverMaxTP,recieverTP):
	var count = 0
	var totalLost = 0
	for i in range(reciever.data.AilmentNum):
		count += 1
	for i in range(reciever.data.XSoft.size()):
		count += 1
	
	totalLost = int(((recieverMaxTP/10) * count))
	recieverTP -= totalLost
	return recieverTP

func miscFunWhimBerry(reciever):
	var healed = randi_range(10,60)
	reciever.currentLP = healed
	if reciever.currentLP > reciever.playerData.MaxLP:
		reciever.currentLP = reciever.playerData.MaxLP
	
	var tween = reciever.LPBar.create_tween() #Tween LP change
	reciever.displayQuick("Healed ", healed, "LP!")
	
	reciever.HPtext.text = str("HP: ",reciever.currentHP)
	await tween.tween_property(reciever.HPBar, "value",
	int(100 * float(reciever.currentLP) / float(reciever.playerData.MaxLP)),.4).set_trans(4).set_ease(1)
