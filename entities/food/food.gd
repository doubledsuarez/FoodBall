extends RigidBody3D

@onready var area = $Area3D  # Assuming the Area3D is a child of the RigidBody3D
@onready var foodInstance = duplicate()
@export var throw_force: float = 15.0
var human
var team: String
var type: String = "food"
var time: int = 5
var isEquipped: bool = false
var inAction: bool = false

func _ready():
	# Connect the body_entered signal if not already connected in the editor
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	pass

func throw(direction: Vector3) -> void:
	isEquipped = false
	inAction = true

	# Apply an impulse to the RigidBody3D to throw it
	apply_impulse(Vector3(0, 1, 0), direction * throw_force)

func eat() -> void:
	isEquipped = false
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
		var coll = body
		var opp: String
		if coll is CharacterBody3D and inAction == true:
			opp = PlayerManager.get_player_data(coll.player, "team")
			if opp == "red" and team == "blue":
				queue_free()
				g.blue_points += 1
			elif opp == "blue" and team == "red":
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
