extends Node

var game

var red_points : int = 1
var blue_points : int = 0

var foods:Array[PackedScene]

var secret_ingredient

signal round_over

var roundTimer = Timer.new()

func _ready():
	add_child(roundTimer)
