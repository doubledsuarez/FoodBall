class_name Player
extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed : float = 10.0
@export var powerExp : float = 1.5

@onready var DebuffTimer = $DebuffTimer
@onready var SlipTimer = $SlipTimer

var target_velocity = Vector3.ZERO
var current_velocity = Vector3.ZERO

var maxPowerScale : float = 7.5
var maxPower : float = maxPowerScale * 3.0

var hasFood : bool = false
var equipped = null
var powerup_active : bool = false
var throw_power : float
var isMaxPower : bool = false
var team : String = ""
var isInvuln : bool = false
var isDebuffed : bool = false
var isSticky : bool = false

var throwStarted : bool = false
var inThrowAni : bool = false
var inHitAni : bool = false

var isSlippery: bool = false
var slip_direction: Vector3 = Vector3.ZERO
var throw_triggered: bool = false

var AniPlayer

var PlayerLabel

var player : int
var input
var device

var throwTimer = Timer.new()

signal leave

func _ready() -> void:
	throwTimer.connect("timeout", on_throw_timer_timeout)
	throwTimer.set_wait_time(3.0)
	throwTimer.set_one_shot(false)
	throwTimer.set_autostart(false)
	add_child(throwTimer)

	AniPlayer = $Pivot/Player_Model.animation_player
	#AniPlayer.speed_scale = 1.5

	PlayerLabel = $SubViewport/PlayerNum

	AniPlayer.connect("animation_finished", on_animation_finished)

func init(player_num: int):
	player = player_num
	device = ps._get_player_device(player)
	input = DeviceInput.new(device)
	$SubViewport/PlayerNum.text = "Player %s" % (player_num + 1)


func setLabelColor() -> void:
	if team == "red":
		PlayerLabel.label_settings.font_color = Color.RED
	elif team == "blue":
		PlayerLabel.label_settings.font_color = Color.BLUE


func attach_to_hand(held_object: Node3D):
	# Use deferred reparenting to avoid physics callback error
	call_deferred("_deferred_attach_to_hand", held_object)

func _deferred_attach_to_hand(held_object: Node3D):
	var hand_socket = $Pivot/Player_Model/Rig_Human/Skeleton3D/Hand_Holds/Hand_Holds
	if hand_socket and held_object:
		held_object.reparent(hand_socket)
		held_object.global_position = hand_socket.global_position
		if (team == "red"):
			held_object.position = Vector3(0.25, 1, -0.5)
		elif (team == "blue"):
			held_object.position = Vector3(-0.25, 1, -0.5)

func _physics_process(delta: float) -> void:
	#setLabelColor()

	var direction = Vector3.ZERO
	if input.get_vector("move_left","move_right","move_forward","move_back") == Vector2.ZERO and !inThrowAni and !throwStarted and !inHitAni and !isSlippery and !isSticky:
		if AniPlayer.is_playing() and AniPlayer.get_current_animation() != "Idle_Holding":
			AniPlayer.stop()

		if AniPlayer.speed_scale > 1.0:
			AniPlayer.set_speed_scale(1.0)

		AniPlayer.play("Idle_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if input.get_vector("move_left","move_right","move_forward","move_back") != Vector2.ZERO and !inThrowAni and !throwStarted and !inHitAni and !isSlippery and !isSticky:
		if AniPlayer.is_playing() and AniPlayer.get_current_animation() != "Walk_Holding":
			AniPlayer.stop()

		if AniPlayer.speed_scale > 1.0:
			AniPlayer.set_speed_scale(1.0)

		AniPlayer.play("Walk_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if !inThrowAni and !isSticky and !inHitAni and !isSlippery and !throwStarted:
		# We check for each move input and update the direction accordingly.
		if input.is_action_pressed("move_right"):
			direction.x += 1
		if input.is_action_pressed("move_left"):
			direction.x -= 1
		if input.is_action_pressed("move_forward"):
			direction.z -= 1
		if input.is_action_pressed("move_back"):
			direction.z += 1

	#if direction != Vector3.ZERO:
		#direction = direction.normalized()
		## Setting the basis property will affect the rotation of the node.
		#if (team == "red"):
			#$Pivot.basis = Basis.looking_at(direction)
		#elif (team == "blue"):
			#$Pivot.basis = Basis.looking_at(-direction)

	# Ground Velocity
	if isSlippery:
		# Force movement in slip direction, ignore input
		target_velocity.x = slip_direction.x * speed
		target_velocity.z = slip_direction.z * speed
	elif inHitAni and !isSticky:
		if team == "red":
			target_velocity.x = -speed/2
			target_velocity.z = 0
		elif team == "blue":
			target_velocity.x = speed/2
			target_velocity.z = 0
	else:
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed

	velocity = target_velocity

	if throwStarted:
		rotatePivot(Vector3(0, 270, 0))

	move_and_slide()

	if hasFood and !inThrowAni and !isSticky and !inHitAni:
		if input.is_action_just_pressed("throw"):
			throwStarted = true
			throwTimer.start()
			#speed /= powerExp
			#AniPlayer.speed_scale = 2.0
			AniPlayer.stop()
			AniPlayer.play("Throwing_WindUp")
		if input.is_action_just_released("throw") and throwStarted:
			throw_power = (maxPowerScale - throwTimer.get_time_left()) * 3
			throwTimer.stop()
			AniPlayer.speed_scale = 2.0
			AniPlayer.play("Throwing_Release")
			inThrowAni = true
			throw_triggered = false  # Reset throw flag
			#speed *= powerExp

	if input.is_action_just_pressed("eat") and !throwStarted:
		if hasFood == true and powerup_active == false:
			hasFood = false
			powerUp()
			equipped.eat()

	# Trigger throw in animation range and only once
	if AniPlayer.current_animation == "Throwing_Release" and not throw_triggered:
		var anim_pos = AniPlayer.get_current_animation_position()
		if anim_pos >= 0.45 and anim_pos <= 0.55:  # Range around 0.48
			throw(throw_power)
			throw_triggered = true  # Prevent multiple throws


func throw(throw_force: float) -> void:
	if isMaxPower:
		throw_force = maxPower

	# Get player's current momentum
	var player_velocity = current_velocity
	var throw_direction

	throw_direction = global_transform.basis.x + Vector3(0, input.get_vector("move_left","move_right","move_forward","move_back").x * 0.5, input.get_vector("move_left","move_right","move_forward","move_back").y * 2)

	# Calculate momentum bonus based on movement direction
	var momentum_factor = player_velocity.dot(throw_direction.normalized())
	var momentum_bonus = momentum_factor * 0.3  # Scale the momentum effect

	# Add momentum to throw force
	var final_throw_force = throw_force + momentum_bonus

	#Log.info("Throwing with base force: %s, momentum bonus: %s, final: %s" % [throw_force, momentum_bonus, final_throw_force])
	# Create throw direction with slight momentum influence
	var momentum_direction = (throw_direction + player_velocity.normalized() * 0.1).normalized()

	# Pass both momentum direction and final throw force
	equipped.rotatePivot(Vector3(0, 0, 270))
	equipped.throw(throw_direction, final_throw_force)
	equipped.reparent(get_parent())
	#get_parent().add_child(equipped)
	hasFood = false
	isMaxPower = false

	# Check for nearby food after throwing (in case player is standing in food)
	# call_deferred("_check_for_nearby_food")  # TODO: Fix after jam

func on_throw_timer_timeout() -> void:
	isMaxPower = true

func powerUp() -> void:
	Log.info("Player %s ate. Current speed is %s" % [player + 1, speed])
	powerup_active = true
	speed *= powerExp
	#acceleration *= 1.3

	if equipped.name == g.secret_ingredient:
		Log.info("Player %s ate the secret ingredient %s!" % [player + 1, g.secret_ingredient])
		if !g.secret_found:
			g.secret_found = true
			get_parent().setFoundLabel("Player %s has eaten and found the secret ingredient %s!\nEat one for 10 seconds of invulnerability." % [ps._get_player_data(player, "player_num"), g.secret_ingredient])
		isInvuln = true

	Log.info("Player %s activated powerup. Current speed is %s" % [player + 1, speed])
	$PowerUpTimer.wait_time = equipped.time
	$PowerUpTimer.start()


func setDefaults() -> void:
	powerup_active = false
	isInvuln = false
	speed = 15
	#acceleration = 20.0

func assignColor(team: String) -> void:
	$Pivot/TeamColor.assignTeamColor(team)


func _on_power_up_timer_timeout() -> void:
	#setDefaults()
	powerup_active = false
	isInvuln = false
	speed /= powerExp
	Log.info("Player %s powerup timed out. Current speed is %s" % [player + 1, speed])


func rotatePivot(degrees: Vector3) -> void:
	$Pivot.set_rotation_degrees(degrees)

func on_animation_finished(anim_name: String) -> void:
	if anim_name == "Throwing":
		inThrowAni = false
		throw(throw_power)
	#elif anim_name == "Throwing_WindUp":
		#inThrowAni = false
		#throw(throw_power)
	elif anim_name == "Throwing_Release":
		throwStarted = false
		inThrowAni = false
		if isSticky:
			isSticky = false
		if inHitAni:
			inHitAni = false
		if AniPlayer.speed_scale > 1.0:
			AniPlayer.set_speed_scale(1.0)
	elif anim_name == "Getting_Hit":
		inHitAni = false
		AniPlayer.speed_scale = 1.0
		if inThrowAni:
			inThrowAni = false
		if throwStarted:
			throwStarted = false
		if isSticky:
			isSticky = false
		if AniPlayer.speed_scale > 1.0:
			AniPlayer.set_speed_scale(1.0)
	elif anim_name == "Sticky":
		isSticky = false
		if inThrowAni:
			inThrowAni = false
		if throwStarted:
			throwStarted = false
		if inHitAni:
			inHitAni = false
		if AniPlayer.speed_scale > 1.0:
			AniPlayer.set_speed_scale(1.0)

func set_sticky() -> void:
	isSticky = true
	$StickyTimer.start()
	AniPlayer.play("Stuck")
	Log.info("Soda stickiness trap triggered.")


func _on_debuff_timer_timeout() -> void:
	speed *= powerExp
	isDebuffed = false
	Log.info("Player debuff removed. Current speed is %s" % speed)


func _on_sticky_timer_timeout() -> void:
	isSticky = false
	inThrowAni = false
	throwStarted = false
	inHitAni = false
	AniPlayer.stop()
	if AniPlayer.speed_scale > 1.0:
		AniPlayer.set_speed_scale(1.0)
	Log.info("Soda stickiness removed.")

func set_slippery(duration: float):
	isSlippery = true
	# slip_direction should be set by the peas before calling this
	if slip_direction == Vector3.ZERO:
		slip_direction = Vector3(1, 0, 0)  # Default forward if no direction set
	SlipTimer.wait_time = duration
	SlipTimer.start()
	Log.info("Player is slipping in direction: %s for %s seconds" % [slip_direction, duration])

func _on_slip_timer_timeout():
	isSlippery = false
	slip_direction = Vector3.ZERO
	Log.info("Player slip ended")

func _check_for_nearby_food():
	if hasFood:  # Already have food, don't need to check
		return

	# Use physics query to find nearby food objects
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5  # Pickup range
	query.shape = shape
	query.transform.origin = global_position
	query.collision_mask = 8  # Food collision layer (Area3D uses collision_layer = 8)

	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		# Check if it's a food area
		if collider.name == "Area3D" and collider.get_parent() is Food:
			var food = collider.get_parent()
			if not food.inAction and not food.isEquipped:
				# Manually trigger food pickup
				food._on_area_3d_body_entered(self)
				break  # Only pick up one food
