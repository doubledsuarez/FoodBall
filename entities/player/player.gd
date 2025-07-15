extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO

var hasFood : bool = false
var equipped = null
var powerup_active : bool = false

var player : int
var input
var device

var throwTimer = Timer.new()

signal leave

func _ready() -> void:
	throwTimer.connect("timeout", on_throw_timer_timeout)
	throwTimer.set_wait_time(3.0)
	throwTimer.set_one_shot(false)
	add_child(throwTimer)

func init(player_num: int):	
	player = player_num
	device = PlayerManager.get_player_device(player)
	input = DeviceInput.new(device)

	$SubViewport/PlayerNum.text = "Player %s" % (player_num + 1)

func _physics_process(delta: float) -> void:
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

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
		$Pivot.basis = Basis.looking_at(direction)

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # if in the air, fall towards the floor. aka gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

	if input.is_action_just_pressed("throw"):
		if hasFood == true:
			var forward_direction = global_transform.basis.z
			#equipped.boomerang_throw(forward_direction)
			equipped.throw(forward_direction, 10.0)
			equipped.reparent(get_parent())
			hasFood = false
			
	#if input.is_action_pressed("throw"):
		#throwTimer.start()
	#if input.is_action_just_released("throw"):
		#if hasFood == true:
			#throw(g.roundTimer.get_time_left())
		#throwTimer.stop()

	if input.is_action_just_pressed("leave"):
		PlayerManager.leave(player)

	if input.is_action_just_pressed("eat"):
		if hasFood == true and powerup_active == false:
			hasFood = false
			equipped.eat()
			powerUp()

func throw(throw_force: int) -> void:
	Log.info("Throwing with a force of %s." % throw_force)
	var forward_direction = global_transform.basis.z
	#equipped.boomerang_throw(forward_direction)
	equipped.throw(forward_direction, throw_force)
	equipped.reparent(get_parent())
	hasFood = false
	
func on_throw_timer_timeout() -> void:
	throw(9.0)

func powerUp() -> void:
	powerup_active = true
	match equipped.type:
		"food":
			speed *= 1.5
			$PowerUpTimer.wait_time = equipped.time
			$PowerUpTimer.start()
		_:
			print("Invalid food type %s passed" % equipped.type)


func setDefaults() -> void:
	powerup_active = false
	speed = 14

func assignColor(team: String) -> void:
	$Pivot/TeamColor.assignTeamColor(team)


func _on_power_up_timer_timeout() -> void:
	setDefaults()
