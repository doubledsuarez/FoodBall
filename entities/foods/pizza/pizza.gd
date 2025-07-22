extends Food

var has_bounced: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	type = "pizza"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func hit_ground() -> void:
	if not has_bounced and inAction:
		# First bounce - apply upward impulse
		has_bounced = true
		var bounce_force = Vector3(0, 12, randi_range(-12, 12))
		#var bounce_force = Vector3(0, 12, 0)
		apply_central_impulse(bounce_force)
		Log.dbg("Pizza bounced!")
	else:
		# Second hit or not in action - destroy
		queue_free()
