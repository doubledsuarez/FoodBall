class_name Food
extends RigidBody3D

@onready var area = $Area3D		# Area3D I need to make collisions easier

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
	# No manual positioning needed - attach_to_hand handles it
	pass


func throw(direction: Vector3, throw_force: float) -> void:
	isEquipped = false
	inAction = true

	# Re-enable physics when thrown
	freeze = false
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
	player.AniPlayer.speed_scale = 2.0
	player.AniPlayer.stop()
	player.AniPlayer.play("Getting_Hit")
	player.inHitAni = true
	queue_free()

func hit_ground() -> void:
	queue_free()

func rotatePivot(degrees: Vector3) -> void:
	$Pivot.set_rotation_degrees(degrees)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		if (inAction and !body.isInvuln):
			var opp = ps._get_player_data(body.player, "team")
			match [opp, team]:
				["red", "blue"]:
					hit(body)
					g.blue_points += 1
				["blue", "red"]:
					hit(body)
					g.red_points += 1
		elif (!inAction and !body.hasFood and !isEquipped and !body.inHitAni):
			body.hasFood = true
			body.equipped = self
			human = body
			team = ps._get_player_data(body.player, "team")
			isEquipped = true

			# Disable physics when equipped
			freeze = true
			gravity_scale = 0
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO

			# Reset any scaling that might have been applied during throwing
			scale = Vector3(1.0, 1.0, 1.0)

			# Let attach_to_hand handle positioning through deferred reparenting
			body.attach_to_hand(self)
	elif body.name == "Ground":
		hit_ground()
