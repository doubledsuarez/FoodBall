class_name Food
extends RigidBody3D

@onready var area = $Area3D		# Area3D I need to make collisions easier
@onready var foodInstance = duplicate()

# properties
var human
var team: String

var type: String
var time: int = 5
var isEquipped: bool = false
var inAction: bool = false

# just let the food float in the air until someone comes to pick it up
func _ready():
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:	
	if (isEquipped):
		position = human.find_child("Player_Model").position


func throw(direction: Vector3, throw_force: float) -> void:
	isEquipped = false
	inAction = true

	gravity_scale = 1.0

	Log.dbg("Throwing food with direction: ", direction)
	Log.dbg("Gravity scale: ", gravity_scale)
	Log.dbg("Mass: ", mass)
	Log.dbg("Freeze mode: ", freeze_mode)

	# Create a more realistic throw with upward arc
	var throw_direction = direction.normalized()
	var upward_force = Vector3(0, 0.3, 0)  # Add upward component for arc
	var final_force = (throw_direction + upward_force) * throw_force

	Log.dbg("Final force being applied: ", final_force)

	# Apply the impulse to create projectile motion
	apply_central_impulse(final_force)

	Log.dbg("Linear velocity after impulse: ", linear_velocity)


func eat() -> void:
	isEquipped = false
	queue_free()
	

func hit(player : Player) -> void:
	queue_free()

func hit_ground() -> void:
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		if (inAction and !body.isInvuln):
			var opp = ps.get_player_data(body.player, "team")

			match [opp, team]:
				["red", "blue"]:
					hit(body)
					g.blue_points += 1
				["blue", "red"]:
					hit(body)
					g.red_points += 1
		elif (!inAction and !body.hasFood and !isEquipped):
			body.hasFood = true
			body.equipped = foodInstance
			foodInstance.human = body
			foodInstance.team = ps.get_player_data(body.player, "team")

			foodInstance.position = body.find_child("Hand").position
			foodInstance.isEquipped = true
			foodInstance.gravity_scale = 0
			#foodInstance.set_scale(Vector3(0.125,0.125,0.125))
			body.find_child("Pivot").add_child(foodInstance)
			queue_free()
	elif body.name == "Ground":
		hit_ground()
