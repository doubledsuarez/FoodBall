extends Node

#@onready var player_scene : PackedScene = preload("res://entities/player/player.tscn")

# map from player integer to the player node
var player_nodes = {}

func _ready():
	PlayerManager.player_joined.connect(spawn_player)
	PlayerManager.player_left.connect(delete_player)

func _process(_delta):
	PlayerManager.handle_join_input()
	
	$"Red Points".text = "Red Points: %s" % (g.red_points)
	$"Blue Points".text = "Blue Points: %s" % (g.blue_points)

func spawn_player(player: int):
	# create the player node
	var player_scene : PackedScene = load("res://entities/player/player.tscn")
	var player_node = player_scene.instantiate()
	player_node.leave.connect(on_player_leave)
	player_nodes[player] = player_node
	
	# let the player know which device controls it
	var device = PlayerManager.get_player_device(player)
	player_node.init(player)
	
	# add the player to the tree
	add_child(player_node)
	
	if PlayerManager.get_player_data(player, "team") == "red":
		player_node.set_rotation_degrees(Vector3(0, 90, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 270, 0))
		player_node.position = Vector3(randf_range(-13, -2), 0, randf_range(-13, 13))
		player_node.assignColor("red")
	elif PlayerManager.get_player_data(player, "team") == "blue":
		player_node.set_rotation_degrees(Vector3(0, 270, 0))
		player_node.get_node("PlayerNumLabel").set_rotation_degrees(Vector3(0, 90, 0))
		player_node.position = Vector3(randf_range(2, 13), 0, randf_range(-13, 13))
		player_node.assignColor("blue")
		


func delete_player(player: int):
	player_nodes[player].queue_free()
	player_nodes.erase(player)

func on_player_leave(player: int):
	# just let the player manager know this player is leaving
	# this will, through the player manager's "player_left" signal,
	# indirectly call delete_player because it's connected in this file's _ready()
	PlayerManager.leave(player)
