extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO

var hasFood : bool = false
var equipped = null

var player : int
var input
var device

signal leave

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
	var collision_count = move_and_slide()
			
	if input.is_action_just_pressed("throw"):
		if hasFood == true:
			equipped.throw()
			equipped.reparent(get_parent())
			hasFood = false
			
	if input.is_action_just_pressed("leave"):
		PlayerManager.leave(player)
		
		
func assignColor(team: String) -> void:
	$Pivot/TeamColor.assignTeamColor(team)
	
