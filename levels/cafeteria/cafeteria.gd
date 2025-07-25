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
	
	g.round_over.connect(round_over)
	
	ps.player_joined.connect(spawn_player)
	ps.player_left.connect(delete_player)
	
	for i in ps.MAX_PLAYERS:
		if ps.player_data.has(i):
			spawn_player(i)


func round_over() -> void:
	queue_free()
	g.game.add_child(game_over_scene.instantiate())
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$"Red Points".text = "Red Points: %s" % g.red_points
	$"Blue Points".text = "Blue Points: %s" % g.blue_points
	if g.roundTimer.get_time_left() != 0.0:
		$Countdown.text = "Time left: %s seconds" % ceili(g.roundTimer.get_time_left())

	if g.red_points == pointsToWin:
		$Countdown.text = "Round Over! Red team wins!"
		g.round_over.emit()
	if g.blue_points == pointsToWin:
		$Countdown.text = "Round Over! Blue team wins!"
		g.round_over.emit()
	if g.blue_points == g.red_points and g.blue_points == pointsToWin and g.red_points == pointsToWin:
		Log.info("somehow both teams scored %s points on the same frame. crazy. it's a tie?" % pointsToWin)
		$Countdown.text = "Round Over! It was a tie!"
		g.round_over.emit()
	


func on_round_timer_timeout() -> void:
	if g.red_points > g.blue_points:
		$Countdown.text = "Round Over! Red team wins!"
		Log.info("red team wins!")
		g.round_over.emit()
	elif g.blue_points < g.red_points:
		$Countdown.text = "Round Over! Blue team wins!"
		Log.info("blue team wins!")
		g.round_over.emit()
	else:
		$Countdown.text = "Round Over! It was a tie!"
		Log.info("it's a tie!")
		g.round_over.emit()

func spawn_player(player: int):
	# create the player node
	var player_node = player_scene.instantiate()
	player_node.leave.connect(on_player_leave)
	player_nodes[player] = player_node

	# let the player know which device controls it
	var device = ps._get_player_device(player)
	player_node.init(player)

	# add the player to the tree
	add_child(player_node)

	# set the player color, position, and rotation based on the team they joined
	if ps._get_player_data(player, "team") == "red":
		player_node.team = "red"
		player_node.rotatePivot(Vector3(0, 0, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 0, 0))
		#player_node.find_child("PlayerNum").label_settings.font_color = Color.RED
		#player_node.setLabelColor()
		player_node.position = Vector3(randf_range(-13, -2), 0, randf_range(-13, 13))
		player_node.find_child("Player_Model").set_player_texture(g.Player_Textures[ps._get_player_data(player, "pos")])
	elif ps._get_player_data(player, "team") == "blue":
		player_node.team = "blue"
		player_node.set_rotation_degrees(Vector3(0, 180, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 180, 0))
		#player_node.find_child("PlayerNum").label_settings.font_color = Color.BLUE
		#player_node.setLabelColor()
		player_node.position = Vector3(randf_range(2, 13), 0, randf_range(-13, 13))
		player_node.find_child("Player_Model").set_player_texture(g.Player_Textures[ps._get_player_data(player, "pos")])
		

func delete_player(player: int):
	player_nodes[player].queue_free()
	player_nodes.erase(player)

func on_player_leave(player: int):
	ps._leave(player)
