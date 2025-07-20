extends Node

var red_points : int = 4
var blue_points : int = 3

var foods:Array[PackedScene]

var secret_ingredient

signal red_won
signal blue_won
signal tie

var roundTimer = Timer.new()

func _ready():
	add_child(roundTimer)
