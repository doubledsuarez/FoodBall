extends Food

var is_trap: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Pivot/Splatter.set_texture(g.Splatter_Textures[randi() % g.Splatter_Textures.size()])
	$Pivot/Splatter.modulate = Color.GREEN
	gravity_scale = 0.0
	type = "peas"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hit_ground() -> void:
	if not is_trap:
		gravity_scale = 1.0
		is_trap = true
		inAction = false  # Stop it from being a projectile

		# Freeze the peas in place to stop rolling
		freeze = true
		
		
		$Pivot/Peas.visible = false
		$Pivot/Splatter.visible = true
		rotatePivot(Vector3(0, 0, 0))


func hit(player) -> void:
	if is_trap:
		Log.dbg("Peas trap triggered by player!")

		# Get player's current input direction for slipping
		var slip_direction = Vector3.ZERO

		# Check player input to determine slip direction
		if player.input.is_action_pressed("move_right"):
			slip_direction.x += 1
		if player.input.is_action_pressed("move_left"):
			slip_direction.x -= 1
		if player.input.is_action_pressed("move_forward"):
			slip_direction.z -= 1
		if player.input.is_action_pressed("move_back"):
			slip_direction.z += 1

		# If no input, use last movement direction or default forward
		if slip_direction == Vector3.ZERO:
			slip_direction = slip_direction.normalized()

		# Make player slip - they slide in their input direction
		if player.has_method("set_slippery_direction"):
			player.set_slippery_direction(1.0, slip_direction)
			Log.dbg("Player is now slippery for 1 second in direction: %s" % slip_direction)
		elif player.has_method("set_slippery"):
			# Store the direction in the player first
			player.slip_direction = slip_direction
			player.set_slippery(1.0)  # 1 second of slipping
			Log.dbg("Player is now slippery for 1 second!")
		else:
			Log.dbg("Warning: Player doesn't have set_slippery method!")
			
		await get_tree().create_timer(1.0).timeout

		# Destroy the peas trap after use
		queue_free()
	else:
		# Normal hit behavior if peas are still flying
		super.hit(player)

# Override collision detection to handle peas trap
func _on_area_3d_body_entered(body: Node3D) -> void:
	Log.dbg("Peas collision detected with: %s, is_trap: %s" % [body.name, is_trap])
	if body is Player and is_trap:
		# Peas trap affects any player that walks over it
		Log.dbg("Player detected on peas trap!")
		hit(body)
	else:
		# Use base class behavior for normal collisions
		super._on_area_3d_body_entered(body)
