class_name Player
extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed : float = 15.0
@export var powerExp : float = 1.5
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# Movement acceleration and drag
@export var acceleration = 30.0
@export var drag = 100.0

@export var max_power : float = 24.0

@onready var DebuffTimer = $DebuffTimer

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
var inThrowAni : bool = false

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
	
	PlayerLabel = $SubViewport/PlayerNum
	
	AniPlayer.connect("animation_finished", on_animation_finished)

func init(player_num: int):
	player = player_num
	device = ps.get_player_device(player)
	input = DeviceInput.new(device)

	$SubViewport/PlayerNum.text = "Player %s" % (player_num + 1)
	#$SubViewport/PlayerNum.set("theme_override_colors/font_color", Color.RED)
	#if (ps.get_player_data(player, "team") == "red"):
		#$SubViewport/PlayerNum.label_settings.font_color = Color.RED
	#if (ps.get_player_data(player, "team") == "blue"):
		#$SubViewport/PlayerNum.label_settings.font_color = Color.BLUE


func setLabelColor() -> void:
	if team == "red":
		PlayerLabel.label_settings.font_color = Color.RED
	elif team == "blue":
		PlayerLabel.label_settings.font_color = Color.BLUE

func _physics_process(delta: float) -> void:
	setLabelColor()
	
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	
	if input.get_vector("move_left","move_right","move_forward","move_back") == Vector2.ZERO and !inThrowAni:
		AniPlayer.play("Idle_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if input.get_vector("move_left","move_right","move_forward","move_back") != Vector2.ZERO and !inThrowAni:
		AniPlayer.play("Walk_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if !inThrowAni:
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

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Apply acceleration towards target velocity
	if direction.length() > 0:
		# Accelerate towards target velocity
		current_velocity.x = move_toward(current_velocity.x, target_velocity.x, speed * delta)
		current_velocity.z = move_toward(current_velocity.z, target_velocity.z, speed * delta)
	else:
		# Apply drag when no input
		current_velocity.x = move_toward(current_velocity.x, 0, drag * delta)
		current_velocity.z = move_toward(current_velocity.z, 0, drag * delta)

	# Vertical Velocity
	if not is_on_floor(): # if in the air, fall towards the floor. aka gravity
		current_velocity.y = current_velocity.y - (fall_acceleration * delta)
	else:
		current_velocity.y = 0
		
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Moving the Character
	# velocity = current_velocity
	velocity = target_velocity
	
	if throwStarted:
		rotatePivot(Vector3(0, 270, 0))
		
	move_and_slide()

	#if input.is_action_just_pressed("throw"):
		#if hasFood == true:
			#var forward_direction = global_transform.basis.z
			##equipped.boomerang_throw(forward_direction, 10.0)
			#equipped.throw(forward_direction, 10.0)
			#equipped.reparent(get_parent())
			#hasFood = false
	#Log.info("throwTimer is : %s " % throwTimer.is_stopped())
	if hasFood and !inThrowAni:
		if input.is_action_just_pressed("throw"):
			throwStarted = true
			throwTimer.start()
			speed /= powerExp
		if input.is_action_just_released("throw") and throwStarted == true:
			throw_power = (8.0 - throwTimer.get_time_left()) * 3
			throwTimer.stop()
			AniPlayer.play("Throwing")
			inThrowAni = true
			#throw(throw_power)
			throwStarted = false
			speed *= powerExp

	if input.is_action_just_pressed("leave"):
		ps.leave(player)

	if input.is_action_just_pressed("eat") and !inThrowAni:
		if hasFood == true and powerup_active == false:
			hasFood = false
			powerUp()
			equipped.eat()
	
	#if (ps.get_player_data(player, "team") == "red"):
		#$SubViewport/PlayerNum.label_settings.font_color = Color.RED
	#if (ps.get_player_data(player, "team") == "blue"):
		#$SubViewport/PlayerNum.label_settings.font_color = Color.BLUE

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
	Log.info("Player %s ate. Current speed is %s" % [player + 1, speed])
	powerup_active = true
	speed *= powerExp
	#acceleration *= 1.3
	
	if equipped == g.secret_ingredient:
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
	#acceleration /= 1.3
	
	Log.info("Player %s powerup timed out. Current speed is %s" % [player + 1, speed])


func rotatePivot(degrees: Vector3) -> void:
	$Pivot.set_rotation_degrees(degrees)
	
func on_animation_finished(anim_name: String) -> void:
	if anim_name == "Throwing":
		inThrowAni = false
		throw(throw_power)
		#throwStarted = false
		#AniPlayer.stop()


func _on_debuff_timer_timeout() -> void:
	speed *= powerExp
	isDebuffed = false
	Log.info("Player debuff removed. Current speed is %s" % speed)
