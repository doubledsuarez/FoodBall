extends Food

var flight_timer: float = 0.0
var boomerang_phase: String = "forward"  # "forward", "returning", "done"
var initial_direction: Vector3
var initial_position: Vector3
var return_throw_force

func _ready() -> void:
	type = "bananna"
	gravity_scale = 0.0
	Log.dbg("Banana _ready: gravity_scale set to ", gravity_scale)

func _process(delta: float) -> void:
	if inAction:
		flight_timer += delta

		# Force gravity to stay off every frame
		if gravity_scale != 0.0:
			Log.dbg("Warning: Banana gravity was %s forcing back to 0" % gravity_scale)
			gravity_scale = 0.0

		match boomerang_phase:
			"forward":
				# Gradually slow down as it approaches apex using drag force
				var forward_progress = flight_timer / 0.5  # 0 to 1 over forward phase
				var drag_force = -linear_velocity.normalized() * forward_progress * 3.0
				apply_central_force(drag_force)

				if flight_timer >= 0.5:  # Fly forward for 0.5 seconds
					boomerang_phase = "returning"
			"returning":
				# Smooth curved return using gradual force application
				var return_progress = (flight_timer - 0.5) / 0.5  # 0 to 1 over return phase
				var curve_force = -initial_direction * return_progress * 8.0

				# Speed up during return with additional forward force
				var speedup_force = -initial_direction * return_progress * 4.0
				apply_central_force(curve_force + speedup_force)

				if flight_timer >= 1.5:
					boomerang_phase = "done"
					# Now fly off screen smoothly
					linear_velocity = -initial_direction * return_throw_force
			"done":
				# Check if banana is off-screen using camera viewport
				if is_off_screen():
					queue_free()
				elif flight_timer >= 6.0:  # Safety timer in case camera check fails
					queue_free()

func hit_ground() -> void:
	# Bananas don't get destroyed by ground - they keep flying
	pass

func throw(direction: Vector3, throw_force: float) -> void:
	isEquipped = false
	inAction = true
	flight_timer = 0.0
	boomerang_phase = "forward"

	# Store initial values
	initial_direction = direction.normalized()
	initial_position = global_position

	# Moderate speed throw
	var final_force = initial_direction * (throw_force) * 1.5

	Log.dbg("Throwing banana boomerang with force: ", final_force)

	# Apply the impulse
	apply_central_impulse(final_force)

	# Save the throw_force for use in the return
	return_throw_force = throw_force

	# Ensure no gravity affects it
	gravity_scale = 0.0
	Log.dbg("Banana throw: gravity_scale set to ", gravity_scale)
	Log.dbg("Banana linear_velocity after throw: ", linear_velocity)

func is_off_screen() -> bool:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return false

	# Check if banana is within camera's frustum
	var screen_pos = camera.unproject_position(global_position)
	var viewport_size = get_viewport().get_visible_rect().size

	# Add some margin so it doesn't disappear right at screen edge
	var margin = 100.0

	return (screen_pos.x < -margin or
			screen_pos.x > viewport_size.x + margin or
			screen_pos.y < -margin or
			screen_pos.y > viewport_size.y + margin)
