extends Area3D

@onready var foodInstance = duplicate()

@export var speed : int = 15

var isEquipped : bool = false
var inAction : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if inAction:
		position.x += speed * delta

	
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.hasFood == false:
		body.add_child(foodInstance)
		body.hasFood = true
		body.equipped = foodInstance
		foodInstance.position = Vector3(1, 0, 1)
		foodInstance.isEquipped = true
		queue_free()
		
func throw() -> void:
	inAction = true
	
	
