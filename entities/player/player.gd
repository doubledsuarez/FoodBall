class_name Player
extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 10
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# Movement acceleration and drag
@export var acceleration = 20.0
@export var drag = 30.0

@export var max_power : float = 16.5

var target_velocity = Vector3.ZERO
var current_velocity = Vector3.ZERO

var hasFood : bool = false
var equipped = null
var powerup_active : bool = false
var throw_power : float
var isMaxPower : bool = false
var throwStarted : bool = false
var team : String = ""
var isInvuln : bool = false
var isDebuffed : bool = false

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

func init(player_num: int):
	player = player_num
	device = PlayerManager.get_player_device(player)
	input = DeviceInput.new(device)

	$SubViewport/PlayerNum.text = "Player %s" % (player_num + 1)
	#$SubViewport/PlayerNum.set("theme_override_colors/font_color", Color.RED)

func _physics_process(delta: float) -> void:
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

	if input.get_vector("move_left","move_right","move_forward","move_back") == Vector2.ZERO:
		$Pivot/Player_Model.animation_player.play("Idle_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if input.get_vector("move_left","move_right","move_forward","move_back") != Vector2.ZERO:
		$Pivot/Player_Model.animation_player.play("Walk_Holding")
		rotatePivot(Vector3(0, 270, 0))

	# We check for each move input and update the direction accordingly.
	if input.is_action_pressed("move_right"):
		direction.x += 1
	if input.is_action_pressed("move_left"):
		direction.x -= 1
	if input.is_action_pressed("move_forward"):
		direction.z -= 1
	if input.is_action_pressed("move_back"):
		direction.z += 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		if (team == "red"):
			$Pivot.basis = Basis.looking_at(direction)
		elif (team == "blue"):
			$Pivot.basis = Basis.looking_at(-direction)

	# Ground Velocity with acceleration and drag
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Apply acceleration towards target velocity
	if direction.length() > 0:
		# Accelerate towards target velocity
		current_velocity.x = move_toward(current_velocity.x, target_velocity.x, acceleration * delta)
		current_velocity.z = move_toward(current_velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Apply drag when no input
		current_velocity.x = move_toward(current_velocity.x, 0, drag * delta)
		current_velocity.z = move_toward(current_velocity.z, 0, drag * delta)

	# Vertical Velocity
	if not is_on_floor(): # if in the air, fall towards the floor. aka gravity
		current_velocity.y = current_velocity.y - (fall_acceleration * delta)
	else:
		current_velocity.y = 0

	# Moving the Character
	velocity = current_velocity
	move_and_slide()

	#if input.is_action_just_pressed("throw"):
		#if hasFood == true:
			#var forward_direction = global_transform.basis.z
			##equipped.boomerang_throw(forward_direction, 10.0)
			#equipped.throw(forward_direction, 10.0)
			#equipped.reparent(get_parent())
			#hasFood = false
	#Log.info("throwTimer is : %s " % throwTimer.is_stopped())
	if hasFood == true:
		if input.is_action_just_pressed("throw"):
			throwStarted = true
			throwTimer.start()
		if input.is_action_just_released("throw") and throwStarted == true:
			throw_power = (5.5 - throwTimer.get_time_left()) * 3
			throw(throw_power)
			#throw(clampf((5.0 - throwTimer.get_time_left() * 3), 6.0, 15.0))
			throwTimer.stop()
			throwStarted = false

	if input.is_action_just_pressed("leave"):
		PlayerManager.leave(player)

	if input.is_action_just_pressed("eat"):
		if hasFood == true and powerup_active == false:
			hasFood = false
			powerUp()
			equipped.eat()

func throw(throw_force: float) -> void:
	if isMaxPower:
		throw_force = max_power

	# Get player's current momentum
	var player_velocity = current_velocity
	var throw_direction = global_transform.basis.x

	# Calculate momentum bonus based on movement direction
	var momentum_factor = player_velocity.dot(throw_direction.normalized())
	var momentum_bonus = momentum_factor * 0.3  # Scale the momentum effect

	# Add momentum to throw force
	var final_throw_force = throw_force + momentum_bonus

	#Log.info("Throwing with base force: %s, momentum bonus: %s, final: %s" % [throw_force, momentum_bonus, final_throw_force])

	# Create throw direction with slight momentum influence
	var momentum_direction = (throw_direction + player_velocity.normalized() * 0.1).normalized()

	# Pass both momentum direction and final throw force
	equipped.throw(momentum_direction, final_throw_force)
	#equipped.boomerang_throw(momentum_direction, final_throw_force)
	equipped.reparent(get_parent())
	hasFood = false
	isMaxPower = false

func on_throw_timer_timeout() -> void:
	isMaxPower = true

func powerUp() -> void:
	powerup_active = true
	speed *= 1.5
	acceleration *= 1.3
	
	if equipped == g.secret_ingredient:
		isInvuln = true
		
	Log.info("Player activated powerup. Current speed is %s" % speed)
		
	$PowerUpTimer.wait_time = equipped.time
	$PowerUpTimer.start()


func setDefaults() -> void:
	powerup_active = false
	isInvuln = false
	speed = 14
	acceleration = 20.0

func assignColor(team: String) -> void:
	$Pivot/TeamColor.assignTeamColor(team)


func _on_power_up_timer_timeout() -> void:
	#setDefaults()
	powerup_active = false
	isInvuln = false
	speed /= 1.5
	acceleration /= 1.3

func rotatePivot(degrees: Vector3) -> void:
	$Pivot.set_rotation_degrees(degrees)
