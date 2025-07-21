extends RigidBody3D

@onready var area = $Area3D		# Area3D I need to make collisions easier
@onready var foodInstance = duplicate()

#@export var throw_force: float = 10.0

# properties
var human
var team: String
var type: String = "food"
var time: int = 5
var isEquipped: bool = false
var inAction: bool = false
var isBoomerang: bool = false
var boomerang_timer: float = 0.0
var boomerang_return_time: float = 1.0  # Time before it starts returning
var thrower_position: Vector3
var original_throw_direction: Vector3

# just let the food float in the air until someone comes to pick it up
func _ready():
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:
	if isBoomerang and inAction:
		boomerang_timer += delta

		# Start returning after the specified time
		if boomerang_timer >= boomerang_return_time:
			apply_boomerang_forces(delta, 10.0)

func throw(direction: Vector3, throw_force: float) -> void:
	isEquipped = false
	inAction = true
	isBoomerang = false
	boomerang_timer = 0.0

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

func boomerang_throw(direction: Vector3, throw_force: int) -> void:
	isEquipped = false
	inAction = true
	isBoomerang = true
	boomerang_timer = 0.0

	gravity_scale = 0.3  # Less gravity for boomerang

	Log.dbg("Throwing boomerang with direction: ", direction)
	Log.dbg("Gravity scale: ", gravity_scale)
	Log.dbg("Mass: ", mass)
	Log.dbg("Freeze mode: ", freeze_mode)

	# Boomerang throw - straight across, no upward arc
	var throw_direction = direction.normalized()
	var final_force = throw_direction * throw_force

	Log.dbg("Final force being applied: ", final_force)

	# Store information for boomerang return
	if human:
		thrower_position = human.global_position
		original_throw_direction = throw_direction

	# Apply the impulse to create projectile motion
	apply_central_impulse(final_force)

	Log.dbg("Linear velocity after impulse: ", linear_velocity)


func eat() -> void:
	isEquipped = false
	queue_free()

func apply_boomerang_forces(delta: float, throw_force: int) -> void:
	if not human:
		return

	# Calculate direction back to thrower
	var to_thrower = (thrower_position - global_position).normalized()

	# Calculate how long it's been returning
	var return_time = boomerang_timer - boomerang_return_time
	var return_strength = min(return_time * 2.0, 3.0)  # Gradually increase return force

	# Apply return force
	var return_force = to_thrower * return_strength * throw_force * 0.5

	# Add some upward force to keep it airborne
	var upward_force = Vector3(0, 2.0, 0) * (1.0 - return_time * 0.3)

	# Apply forces
	apply_central_force((return_force + upward_force) * delta * 60.0)

	# Slow down the original momentum gradually
	linear_velocity = linear_velocity.lerp(to_thrower * 5.0, delta * 2.0)

	# Auto-pickup if close to thrower
	if global_position.distance_to(thrower_position) < 2.0 and return_time > 0.5:
		auto_pickup_by_thrower()


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
			foodInstance.position = body.global_transform.basis.x + Vector3(0, .5, 1)
			foodInstance.isEquipped = true
			foodInstance.gravity_scale = 0
			queue_free()
		# delete it once it hits the ground after being thrown (but not if it's a boomerang)
		# delete it once it hits the ground after being thrown (but not if it's a boomerang)
		["Ground", true]:
			if not isBoomerang:
				queue_free()
			else:
				# Boomerang bounces off ground
				linear_velocity.y = abs(linear_velocity.y) * 0.5

func auto_pickup_by_thrower() -> void:
	if human and human.has_method("pickup_food"):
		human.pickup_food(self)
	else:
		# Fallback: just add as child like normal pickup
		if human and not human.hasFood:
			var pickup_food = duplicate()
			human.add_child(pickup_food)
			human.hasFood = true
			human.equipped = pickup_food
			pickup_food.human = human
			pickup_food.team = PlayerManager.get_player_data(human.player, "team")
			pickup_food.position = human.global_transform.basis.z + Vector3(0, .5, 1)
			pickup_food.isEquipped = true
			pickup_food.gravity_scale = 0
			queue_free()
