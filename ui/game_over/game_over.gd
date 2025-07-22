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
	
	#stop music
	ps.get_node("CombatMusic").stop()

func _on_rorestart_pressed():
	# Clear everything. 
	self.queue_free()
	
	# Return to player select
	ps.restart()
	
	Log.info("Opened Player Select")


func _on_rtm_pressed():
	# Clear everything
	self.queue_free

	# Return to main menu
	get_tree().change_scene_to_file("res://game.tscn")

	Log.info("Opened Main Menu")
	
