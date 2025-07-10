extends Node2D

var options_menu_scene = preload("res://ui/options_menu/options_menu.tscn")
var player_select_scene = preload("res://ui/player_menu/player_select.tscn")
var unlocks_menu_scene = preload("res://ui/unlocks_menu/unlocks.tscn")

func _ready():
	$"Main Menu/mmhbox/mmvbox/mmstart".grab_focus()

func _on_mmstart_pressed():
	hide()
	var player_select_instance = player_select_scene.instantiate()
	get_parent().add_child(player_select_instance)
	print("Sected Start Game")

func _on_mmoptions_pressed():
	hide()
	var options_instance = options_menu_scene.instantiate()
	get_parent().add_child(options_instance)
	print("Sected Options Menu")

func _on_mmunlocks_pressed():
	hide()
	var unlocks_instance = unlocks_menu_scene.instantiate()
	get_parent().add_child(unlocks_instance)
	print("Sected Unlocks Menu")
