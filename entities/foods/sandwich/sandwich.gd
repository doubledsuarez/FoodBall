extends Food


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	type = "sandwich"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Override throw to give sandwich 2x bigger hitbox
func throw(direction: Vector3, throw_force: float) -> void:
	# Call the base class throw first
	super.throw(direction, throw_force)

	# Scale up the Area3D collision shape for bigger hitbox
	var area3d = $Area3D
	var collision_shape = area3d.get_node("CollisionShape3D")

	# Double the scale of the collision shape
	collision_shape.scale = Vector3(2.0, 2.0, 2.0)
	
	var pivot = $Pivot
	pivot.scale = Vector3(2.0, 2.0, 2.0)

	# Also scale the visual mesh so players can see the bigger sandwich
	#var mesh_instance = $Pivot/MeshInstance3D
	#mesh_instance.scale = Vector3(2.0, 2.0, 2.0)

	Log.dbg("Sandwich thrown with 2x bigger hitbox and visual!")
