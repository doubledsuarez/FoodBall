extends Node

var game

var red_points : int = 0
var blue_points : int = 0

var foods:Array[PackedScene]

var secret_ingredient

signal round_over

var roundTimer = Timer.new()

var Player_Textures = [
	preload("res://entities/player/player textures/player_model_1.glb.png") as Texture2D,
	preload("res://entities/player/player textures/player_model_2_Character_Red.png") as Texture2D,
	preload("res://entities/player/player textures/player_model_3_Character_Blue.png") as Texture2D,
	preload("res://entities/player/player textures/player_model_4_Character_Blue.png") as Texture2D
]

func _ready():
	add_child(roundTimer)
