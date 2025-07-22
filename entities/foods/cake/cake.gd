extends Food

var is_trap: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	type = "cake"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func hit_ground() -> void:
	if not is_trap:
		gravity_scale = 1.0
		is_trap = true
		inAction = false  # Stop it from being a projectile

		# Freeze the cake in place to stop rolling
		freeze = true

		Log.dbg("Cake became a ground trap!")
	# Don't call queue_free() - let it stay as a trap


func hit(player) -> void:
	if is_trap:
		Log.dbg("Cake trap triggered by player!")
		Log.dbg("Player hasFood: %s" % player.hasFood)
		Log.dbg("Player equipped: %s" % player.equipped)

		# Make player drop their food
		if player.hasFood and player.equipped:
			Log.dbg("Player stepped on cake trap - dropping food!")
			player.equipped.isEquipped = false
			player.equipped.inAction = false
			player.equipped.gravity_scale = 1.0
			player.equipped.reparent(get_parent())
			player.hasFood = false
			player.equipped.queue_free()
		else:
			Log.dbg("Player has no food to drop")

		# Destroy the cake trap after use
		queue_free()
	else:
		# Normal hit behavior if cake is still flying
		super.hit(player)

# Override collision detection to handle cake trap
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player and is_trap:
		# Cake trap affects any player that walks over it
		hit(body)
	else:
		# Use base class behavior for normal collisions
		super._on_area_3d_body_entered(body)
