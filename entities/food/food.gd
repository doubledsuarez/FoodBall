extends RigidBody3D

@onready var area = $Area3D		# Area3D I need to make collisions easier
@onready var foodInstance = duplicate()

@export var throw_force: float = 10.0

# properties
var human
var team: String
var type: String = "food"
var time: int = 5
var isEquipped: bool = false
var inAction: bool = false

# just let the food float in the air until someone comes to pick it up
func _ready():
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:
	pass

func throw(direction: Vector3) -> void:
	isEquipped = false
	inAction = true

	gravity_scale = 1.0

	Log.dbg("Throwing food with direction: ", direction)
	Log.dbg("Gravity scale: ", gravity_scale)
	Log.dbg("Mass: ", mass)
	Log.dbg("Freeze mode: ", freeze_mode)

	# Create a more realistic throw with upward arc
	var throw_direction = direction.normalized()
	var upward_force = Vector3(0, 0.5, 0)  # Add upward component for arc
	var final_force = (throw_direction + upward_force) * throw_force

	Log.dbg("Final force being applied: ", final_force)

	# Apply the impulse to create projectile motion
	apply_central_impulse(final_force)

	Log.dbg("Linear velocity after impulse: ", linear_velocity)


func eat() -> void:
	isEquipped = false
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:	
	# reminder: inAction means the food is mid-throw
	match [body.name, inAction]:
		# if it hits a player
		["Player", true]:
			var opp = PlayerManager.get_player_data(body.player, "team")
			match [opp, team]:
				["red", "blue"]:
					queue_free()
					g.blue_points += 1
				["blue", "red"]:
					queue_free()
					g.red_points += 1
		# if a player walks over the food to pick it up
		["Player", false] when !body.hasFood:
			body.add_child(foodInstance)
			body.hasFood = true
			body.equipped = foodInstance
			foodInstance.human = body
			foodInstance.team = PlayerManager.get_player_data(body.player, "team")
			foodInstance.position = body.global_transform.basis.z + Vector3(0, .5, 1)
			foodInstance.isEquipped = true
			foodInstance.gravity_scale = 0
			queue_free()
		# delete it once it hits the ground after being thrown
		["Ground", true]:
			queue_free()
