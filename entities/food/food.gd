extends Area3D

@onready var foodInstance = duplicate()

@export var speed : int = 15

var human
var team : String
var type : String = "food"
var time : int = 5

var isEquipped : bool = false
var inAction : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if inAction and team == "red":
		position.x += speed * delta
	elif inAction and team == "blue":
		position.x -= speed * delta

	
func _on_body_entered(body: Node3D) -> void:
	var coll = body
	var opp : String
	if coll is CharacterBody3D and inAction == true:
		opp = PlayerManager.get_player_data(coll.player, "team")
		if opp == "red" and team == "blue":
			queue_free()
			g.blue_points += 1
		if opp == "blue" and team == "red":
			queue_free()
			g.red_points += 1
	elif coll is CharacterBody3D and inAction == false and body.hasFood == false:
		body.add_child(foodInstance)
		body.hasFood = true
		body.equipped = foodInstance
		foodInstance.human = body
		foodInstance.team = PlayerManager.get_player_data(body.player, "team")
		foodInstance.position = Vector3(1, 0, 1)
		foodInstance.isEquipped = true
		queue_free()
	elif coll is StaticBody3D and coll.name.match("Wall*") and inAction == true:
		queue_free()
			
		
func throw() -> void:
	isEquipped = false
	inAction = true
	
	
func eat() -> void:
	isEquipped = false
	queue_free()
	
	
