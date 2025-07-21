extends Node2D

# Preload required scenes
var options_menu_scene = preload("res://ui/options_menu/options_menu.tscn")
var player_select_scene = preload("res://ui/player_menu/player_select.tscn")
var main_menu_scene = preload("res://ui/main_menu/main_menu.tscn")
var cafe_scene = preload("res://levels/cafeteria/cafeteria.tscn")

func _ready():
	if g.red_points > g.blue_points:
		$"Round Over/Label".text = "Round Over! Red team wins!"
	if g.red_points < g.blue_points:
		$"Round Over/Label".text = "Round Over! Blue team wins!"
	if g.blue_points == g.red_points:
		$"Round Over/Label".text = "Round Over! It was a tie!"
		
	# Make sure the Restart button is focused
	$"Round Over/rohbox/rovbox/rorestart".grab_focus()

func _on_rorestart_pressed():
	## Hide the main menu
	#$"Round Over".hide()
#
	## Play the camera animation (yet to be made)
	## get_node("/root/Game/CameraPivot/AnimationPlayer").play("StartGamePan")
#
	## Instance the player select scene
	#var select_instance = player_select_scene.instantiate()
#
	## Add to parent scene tree
	##g.game.add_child(select_instance)
	##select_instance.unHide()
	##g.game.find_child("Player Select").show()
	##g.game.get_node("Player Select").unHide()
	#
	#ps.unHide()
	
	g.game.restart()
	ps.restart()

	Log.info("Opened Player Select")


func _on_rooptions_pressed():
	# Hide the main menu
	$"Round Over".hide()

	# Instance the options menu
	var options_instance = options_menu_scene.instantiate()

	# Used for back button
	if options_instance.has_method("set_previous_menu"):
		options_instance.set_previous_menu($"Round Over")

	# Add to parent scene tree
	get_parent().add_child(options_instance)

	Log.info("Opened Options Menu")
	
