extends Node3D

@onready var spawnTimer = $SpawnTimer

@export var foods:Array[PackedScene]

var isOverlapping : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	if (!get_node("Food")):
		Log.info("Spawning food")
		add_child(foods[randi() % foods.size()].instantiate())
		# some % chance to create secret ingredient
		# or decide on game spawn which food is the secret ingredient


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
