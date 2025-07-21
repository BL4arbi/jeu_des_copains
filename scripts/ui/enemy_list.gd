extends VBoxContainer

const path = "res://ressource/enemies/"

var enemies = []

func _ready():
	dir_contents()

func dir_contents():
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Found file: " + file_name)
			var enemy_resource : Enemy = load(path + file_name)
			enemies.append(enemy_resource)
			
			var button = Button.new()
			button.pressed.connect(_on_pressed.bind(button))
			button.text = enemy_resource.title
			add_child(button)
			
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	print(enemies)


func _on_pressed(button : Button):
	var index = button.get_index()
	%name.text = "Name : " + enemies[index].title
	%health.text = "Health : " + str(enemies[index].health)
	%Damage.text = "Damage : " + str(enemies[index].damage)
	%Texture.texture = enemies[index].texture
