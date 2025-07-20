extends Node3D

@onready var spawnTimer = $SpawnTimer

var isOverlapping : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(g.foods[randi() % g.foods.size()].instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	for child in get_children():
		if child is Food:
			return
			
	var foodToSpawn = g.foods[randi() % g.foods.size()].instantiate()
	Log.info("Spawning food " + foodToSpawn.name)
	add_child(foodToSpawn)
	#add_child(g.foods[1].instantiate())


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
