extends Node

func miscFunCrash(reciever,recieverMaxTP,recieverTP) -> int:
	var count = 0
	var totalLost = 0
	for i in range(reciever.data.AilmentNum):
		count += 1
	for i in range(reciever.data.XSoft.size()):
		count += 1
	
	totalLost = int(((recieverMaxTP/10) * count))
	recieverTP -= totalLost
	return recieverTP

func miscFunWhimBerry(reciever) -> void:
	var healed = randi_range(10,60)
	reciever.currentLP = healed
	if reciever.currentLP > reciever.playerData.MaxLP:
		reciever.currentLP = reciever.playerData.MaxLP
	
	var tween = reciever.LPBar.create_tween().bind_node(reciever) #Tween LP change
	reciever.displayQuick(str("Healed ", healed, "LP!"))
	
	reciever.LPtext.text = str("LP: ",reciever.currentLP)
	await tween.tween_property(reciever.LPBar, "value",
	int(100 * float(reciever.currentLP) / float(reciever.playerData.MaxLP)),.4).set_trans(4).set_ease(1)
