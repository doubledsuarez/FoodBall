extends Food

var is_trap: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Pivot/Splatter.set_texture(g.Splatter_Textures[randi() % g.Splatter_Textures.size()])
	$Pivot/Splatter.modulate = Color.BLUE
	gravity_scale = 0.0
	type = "soda"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func hit_ground() -> void:
	if not is_trap:
		gravity_scale = 1.0
		is_trap = true
		inAction = false  # Stop it from being a projectile
		#rotatePivot(Vector3(0, 180, 0))

		# Freeze the soda in place to stop rolling
		freeze = true
		
		$Pivot/Soda.visible = false
		$Pivot/Splatter.visible = true

		Log.dbg("Soda became a sticky trap!")
	# Don't call queue_free() - let it stay as a trap


func hit(player) -> void:
	if is_trap:
		Log.dbg("Soda trap triggered by player!")

		# Make player sticky using their own method
		if player.has_method("set_sticky"):
			player.set_sticky()
			Log.dbg("Player is now sticky for 1 second!")
		else:
			Log.dbg("Warning: Player doesn't have set_sticky method!")

		await get_tree().create_timer(1.0).timeout

		# Destroy the soda trap after use
		queue_free()
	else:
		# Normal hit behavior if cake is still flying
		super.hit(player)

# Override collision detection to handle soda trap
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player and is_trap:
		# Soda trap affects any player that walks over it
		hit(body)
	else:
		# Use base class behavior for normal collisions
		super._on_area_3d_body_entered(body)
