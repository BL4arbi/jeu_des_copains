extends Pickups
class_name Gem

@export var XP : float 

func activate():
	super.activate()
	player.gain_XP(XP)
