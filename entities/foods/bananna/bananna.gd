extends Food


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func throw(direction: Vector3, throw_force: float) -> void:
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
	
