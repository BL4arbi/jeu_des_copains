extends Panel

var skill_tree
var total_stat : Stats
func _ready() -> void:
	load_skill_tree()

func set_skill_tree():
	skill_tree = []
	for each_branch in get_children():
		var branch = []
		for upgrade in each_branch.get_children():
			branch.append(upgrade.enabled)
		skill_tree.append(branch) 
	SaveDataa.skill_tree = skill_tree 
	SaveDataa.set_and_save()
	
	
func load_skill_tree():
	if SaveDataa.skill_tree ==[]:
		set_skill_tree() 
	skill_tree = SaveDataa.skill_tree 
	for branch in get_children() :
		for upgrade in branch.get_children():
			upgrade.enabled = skill_tree[branch.get_index()][upgrade.get_index()]
	get_total_stats()

func add_stats(stat):
	total_stat.max_health += stat.max_health
	total_stat.recovery += stat.recovery
	total_stat.armor += stat.armor
	total_stat.movement_speed += stat.movement_speed
	total_stat.might += stat.might
	total_stat.area +=stat.area
	total_stat.magnet += stat.magnet
	total_stat.growth += stat.growth
	
func get_total_stats():
	total_stat = Stats.new()
	for branch in get_children():
		for upgrade in branch.get_children():
			if upgrade.enabled:
				add_stats(upgrade.skill.stats)
	Persistencee.bonus_stats = total_stat
