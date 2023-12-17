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
