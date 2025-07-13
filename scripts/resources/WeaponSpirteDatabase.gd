# WeaponSpritesDatabase.gd - Base de données des sprites d'armes
extends Resource
class_name WeaponSpritesDatabase

# SPRITES D'ARMES DISPONIBLES DANS LE PROJET
static var weapon_sprites: Dictionary = {
	"Tir Basique": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Tir Rapide": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png", 
	"Canon Lourd": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Tir Perçant": "res://assets/SPRITES/weapon/Pickaxe_TOP_DOWN.png",
	"Flèche Fork": "res://assets/SPRITES/weapon/AttackSprite01.png",
	"Tir Chercheur": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Chakram": "res://assets/SPRITES/weapon/Collectibles_TOP_DOWN.png",
	"Foudre": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Pluie de Météores": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Laser Rotatif": "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png",
	"Nova Stellaire": "res://assets/SPRITES/weapon/AttackSprite01.png",
	"Apocalypse": "res://assets/SPRITES/weapon/GRENADE_TOP_DOWN.png",
	"Singularité": "res://assets/SPRITES/weapon/AttackSprite01.png"
}

static func get_weapon_sprite(weapon_name: String) -> String:
	if weapon_sprites.has(weapon_name):
		return weapon_sprites[weapon_name]
	else:
		# Sprite par défaut
		return "res://assets/SPRITES/weapon/BAGUETTE_MAGIQUE.png"
