extends Node2D

# Preload required scenes
var options_menu_scene = preload("res://ui/options_menu/options_menu.tscn")
var player_select_scene = preload("res://ui/player_menu/player_select.tscn")
var main_menu_scene = preload("res://ui/main_menu/main_menu.tscn")
var cafe_scene = preload("res://levels/cafeteria/cafeteria.tscn")

func _ready():
	# For testing only, can be removed after game startup has been properly coded. 
	config_helper.load_settings()
	# Make sure the Start button is focused
	$"Main Menu/mmhbox/mmvbox/mmstart".grab_focus()

func _on_mmstart_pressed():
	# Hide the main menu
	$"Main Menu".hide()

	# Play the camera animation (yet to be made)
	# get_node("/root/Game/CameraPivot/AnimationPlayer").play("StartGamePan")

	# Instance the player select scene
	#var select_instance = player_select_scene.instantiate()

	# Add to parent scene tree
	#g.game.add_child(select_instance)
	#select_instance.unHide()
	#g.game.find_child("Player Select").show()
	#g.game.get_node("Player Select").unHide()
	
	ps.restart()

	Log.info("Opened Player Select")


func _on_mmoptions_pressed():
	# Hide the main menu
	$"Main Menu".hide()

	# Instance the options menu
	var options_instance = options_menu_scene.instantiate()

	# Used for back button
	if options_instance.has_method("set_previous_menu"):
		options_instance.set_previous_menu($"Main Menu")

	# Add to parent scene tree
	get_parent().add_child(options_instance)

	Log.info("Opened Options Menu")
