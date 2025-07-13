extends Node

var red_points : int = 4
var blue_points : int = 3

signal red_won
signal blue_won
signal tie

var roundTimer = Timer.new()

func _ready():
	add_child(roundTimer)
