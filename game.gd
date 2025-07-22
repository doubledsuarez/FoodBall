extends Node

@onready var cafe_scene : PackedScene = preload("res://levels/cafeteria/cafeteria.tscn")
@onready var main_menu_scene : PackedScene = preload("res://ui/main_menu/main_menu.tscn")

@export var foods:Array[PackedScene]

# load the cafe level and connect ps signals
func _ready():
	config_helper.init_config_if_missing()
	g.foods = foods
	g.secret_ingredient = g.foods[randi() % g.foods.size()].instantiate().name
	
	Log.dbg("Secret ingredient is %s " % g.secret_ingredient)
	
	add_child(main_menu_scene.instantiate())
	
	g.game = self
	

# read devices not joined for the join input
func _process(_delta):
	#ps.handle_join_input()
	pass

func restart():
	get_tree().reload_current_scene()
