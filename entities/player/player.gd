class_name Player
extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed : float = 15.0
@export var powerExp : float = 1.5

@export var max_power : float = 21.0

@onready var DebuffTimer = $DebuffTimer

var target_velocity = Vector3.ZERO
var current_velocity = Vector3.ZERO

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

var AniPlayer

var PlayerLabel

var player : int
var input
var device

var throwTimer = Timer.new()

var currDirection = Vector3.ZERO
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


func setLabelColor() -> void:
	if team == "red":
		PlayerLabel.label_settings.font_color = Color.RED
	elif team == "blue":
		PlayerLabel.label_settings.font_color = Color.BLUE

func _physics_process(delta: float) -> void:
	#setLabelColor()
	
	var direction = Vector3.ZERO
	if input.get_vector("move_left","move_right","move_forward","move_back") == Vector2.ZERO and !inThrowAni and !throwStarted:
		AniPlayer.play("Idle_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if input.get_vector("move_left","move_right","move_forward","move_back") != Vector2.ZERO and !inThrowAni and !throwStarted:
		AniPlayer.play("Walk_Holding")
		rotatePivot(Vector3(0, 270, 0))

	if !inThrowAni and !isSticky:
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
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	velocity = target_velocity
  
	if throwStarted:
		rotatePivot(Vector3(0, 270, 0))

	move_and_slide()
	
	if hasFood and !inThrowAni:
		if input.is_action_just_pressed("throw"):
			throwStarted = true
			throwTimer.start()
			speed /= powerExp
			AniPlayer.play("Throwing_WindUp")
		if input.is_action_just_released("throw") and throwStarted:
			throw_power = (7.0 - throwTimer.get_time_left()) * 3
			throwTimer.stop()
			AniPlayer.play("Throwing_Release")
			inThrowAni = true
			speed *= powerExp

	if input.is_action_just_pressed("leave"):
		ps.leave(player)

	if input.is_action_just_pressed("eat") and !inThrowAni:
		if hasFood == true and powerup_active == false:
			hasFood = false
			powerUp()
			equipped.eat()
			

func throw(throw_force: float) -> void:
	if isMaxPower:
		throw_force = max_power

	# Get player's current momentum
	var player_velocity = current_velocity
	var throw_direction
	
	throw_direction = global_transform.basis.x + Vector3(0, input.get_vector("move_left","move_right","move_forward","move_back").x * 0.5, input.get_vector("move_left","move_right","move_forward","move_back").y)

	# Calculate momentum bonus based on movement direction
	var momentum_factor = player_velocity.dot(throw_direction.normalized())
	var momentum_bonus = momentum_factor * 0.3  # Scale the momentum effect

	# Add momentum to throw force
	var final_throw_force = throw_force + momentum_bonus

	#Log.info("Throwing with base force: %s, momentum bonus: %s, final: %s" % [throw_force, momentum_bonus, final_throw_force])
	# Create throw direction with slight momentum influence
	var momentum_direction = (throw_direction + player_velocity.normalized() * 0.1).normalized()

	# Pass both momentum direction and final throw force
	equipped.throw(throw_direction, final_throw_force)
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

	if equipped.name == g.secret_ingredient:
		Log.info("Player % ate the secret ingredient %s!" % [player + 1, g.secret_ingredient])
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
		throw(throw_power)

func set_sticky() -> void:
	isSticky = true
	$StickyTimer.start()
	Log.info("Soda stickiness trap triggered.")


func _on_debuff_timer_timeout() -> void:
	speed *= powerExp
	isDebuffed = false
	Log.info("Player debuff removed. Current speed is %s" % speed)


func _on_sticky_timer_timeout() -> void:
	isSticky = false
	Log.info("Soda stickiness removed.")
