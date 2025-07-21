extends Node3D

@onready var player_scene = preload("res://entities/player/player.tscn")
@onready var game_over_scene = preload("res://ui/game_over/game_over.tscn")


var roundTimer : float = 90.0
var pointsToWin : int = 15

# map from player integer to the player node
var player_nodes = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	g.roundTimer.connect("timeout", on_round_timer_timeout)
	g.roundTimer.set_wait_time(roundTimer)
	g.roundTimer.set_one_shot(true)
	g.roundTimer.start()
	
	g.red_won.connect(red_won)
	g.blue_won.connect(blue_won)
	
	ps.player_joined.connect(spawn_player)
	ps.player_left.connect(delete_player)
	
	for i in ps.MAX_PLAYERS:
		if ps.player_data.has(i):
			spawn_player(i)


func red_won() -> void:
	queue_free()
	g.game.add_child(game_over_scene.instantiate())
	
func blue_won() -> void:
	queue_free()
	g.game.add_child(game_over_scene.instantiate())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#ps.handle_join_input()
	
	$"Red Points".text = "Red Points: %s" % g.red_points
	$"Blue Points".text = "Blue Points: %s" % g.blue_points
	if g.roundTimer.get_time_left() != 0.0:
		$Countdown.text = "Time left: %s seconds" % ceili(g.roundTimer.get_time_left())

	if g.red_points == pointsToWin:
		$Countdown.text = "Round Over! Red team wins!"
		g.red_won.emit()
	if g.blue_points == pointsToWin:
		$Countdown.text = "Round Over! Blue team wins!"
		g.blue_won.emit()
	if g.blue_points == g.red_points and g.blue_points == pointsToWin and g.red_points == pointsToWin:
		Log.info("somehow both teams scored %s points on the same frame. crazy. it's a tie?" % pointsToWin)
		$Countdown.text = "Round Over! It was a tie!"
		g.tie.emit()

	#clamp(g.red_points, 0, pointsToWin)
	#clamp(g.blue_points, 0, pointsToWin)
	


func on_round_timer_timeout() -> void:
	if g.red_points > g.blue_points:
		$Countdown.text = "Round Over! Red team wins!"
		Log.info("red team wins!")
		g.red_won.emit()
	elif g.blue_points < g.red_points:
		$Countdown.text = "Round Over! Blue team wins!"
		Log.info("blue team wins!")
		g.blue_won.emit()
	else:
		$Countdown.text = "Round Over! It was a tie!"
		Log.info("it's a tie!")
		g.tie.emit()

func spawn_player(player: int):
	# create the player node
	var player_node = player_scene.instantiate()
	player_node.leave.connect(on_player_leave)
	player_nodes[player] = player_node

	# let the player know which device controls it
	var device = ps.get_player_device(player)
	player_node.init(player)

	# add the player to the tree
	add_child(player_node)

	# set the player color, position, and rotation based on the team they joined
	if ps.get_player_data(player, "team") == "red":
		player_node.team = "red"
		player_node.rotatePivot(Vector3(0, 0, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 0, 0))
		#player_node.find_child("PlayerNum").label_settings.font_color = Color.RED
		#player_node.setLabelColor()
		player_node.position = Vector3(randf_range(-13, -2), 0, randf_range(-13, 13))
		#player_node.assignColor("red")
	elif ps.get_player_data(player, "team") == "blue":
		player_node.team = "blue"
		player_node.set_rotation_degrees(Vector3(0, 180, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 180, 0))
		#player_node.find_child("PlayerNum").label_settings.font_color = Color.BLUE
		#player_node.setLabelColor()
		player_node.position = Vector3(randf_range(2, 13), 0, randf_range(-13, 13))
		#player_node.assignColor("blue")
		
	#var model = load(ps.PLAYER_MODELS[player]).instantiate()
	#var mesh = player_node.get_node_or_null("Rig_Human/Skeleton3D/Cube")
	#
	#if mesh and mesh is MeshInstance3D:
		#var color = ps.PLAYER_COLORS[player]
		#var original_mat = mesh.get_active_material(0)
		#if original_mat and original_mat is StandardMaterial3D:
			#var mat = original_mat.duplicate()
			#mat.albedo_color = color
			#mesh.set_surface_override_material(0, mat)



func delete_player(player: int):
	player_nodes[player].queue_free()
	player_nodes.erase(player)

func on_player_leave(player: int):
	ps.leave(player)
