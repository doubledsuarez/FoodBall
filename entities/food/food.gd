extends Area3D

@onready var foodInstance = preload("res://entities/food/food.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.add_child(foodInstance)
		foodInstance.position = Vector3(1, 0, 1)
		queue_free()
		print("added")
