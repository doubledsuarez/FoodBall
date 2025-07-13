extends RigidBody3D

@onready var area = $Area3D  # Assuming the Area3D is a child of the RigidBody3D
@onready var foodInstance = duplicate()
@export var throw_force: float = 10.0
var human
var team: String
var type: String = "food"
var time: int = 5
var isEquipped: bool = false
var inAction: bool = false

func _ready():
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:
	pass

func throw(direction: Vector3) -> void:
	isEquipped = false
	inAction = true

	gravity_scale = 1.0

	# Debug prints
	print("Throwing food with direction: ", direction)
	print("Gravity scale: ", gravity_scale)
	print("Mass: ", mass)
	print("Freeze mode: ", freeze_mode)

	# Create a more realistic throw with upward arc
	var throw_direction = direction.normalized()
	var upward_force = Vector3(0, 0.5, 0)  # Add upward component for arc
	var final_force = (throw_direction + upward_force) * throw_force

	print("Final force being applied: ", final_force)

	# Apply the impulse to create projectile motion
	apply_central_impulse(final_force)

	# Additional debug - check velocity after impulse
	print("Linear velocity after impulse: ", linear_velocity)

func eat() -> void:
	isEquipped = false
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:	
	match [body.name, inAction]:
		["Player", true]:
			var opp = PlayerManager.get_player_data(body.player, "team")
			match [opp, team]:
				["red", "blue"]:
					queue_free()
					g.blue_points += 1
				["blue", "red"]:
					queue_free()
					g.red_points += 1
		["Player", false]:
			body.add_child(foodInstance)
			body.hasFood = true
			body.equipped = foodInstance
			foodInstance.human = body
			foodInstance.team = PlayerManager.get_player_data(body.player, "team")
			#foodInstance.position = Vector3(0, 0.5, 1)
			foodInstance.position = body.global_transform.basis.z + Vector3(0, .5, 1)
			foodInstance.isEquipped = true
			foodInstance.gravity_scale = 0
			queue_free()
		["Ground", true]:
			queue_free()
