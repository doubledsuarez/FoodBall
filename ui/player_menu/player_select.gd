extends Node2D

# Signals to notify when a player joins or leaves
signal player_joined(player)
signal player_left(player)

# Constants
const MAX_PLAYERS = 4
const PLAYER_MODELS = [
	"res://entities/player/player1.glb",
	"res://entities/player/player2.glb",
	"res://entities/player/player3.glb",
	"res://entities/player/player4.glb"
]

const PLAYER_COLORS = [
	Color(0.5, 0, 0),     # Dark red
	Color(1, 0.3, 0.3),   # Light red
	Color(0, 0, 0.5),     # Dark blue
	Color(0.4, 0.6, 1.0)  # Light blue
]

# Tracks which devices are in which slots
var player_data: Dictionary = {}
var player_panels = []

func _ready():
	# Cache references to each player panel node using full paths
	player_panels = [
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin1",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin2",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin3",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin4",
	]
	print("Panel Index Loaded")

func _process(_delta):
	_check_start_conditions()

	# Check for new joins
	for device in Input.get_connected_joypads():
		if not _device_joined(device) and MultiplayerInput.is_action_just_pressed(device, "Connect"):
			print("Device", device, "pressed Connect")
			_join_player(device, "neutral")

	# Debug output
	var status := []
	for device in Input.get_connected_joypads():
		var joined_index = _get_player_index_for_device(device)
		var label = "Device %d" % device
		label += " (joined as player %d)" % joined_index if joined_index >= 0 else " (not joined)"
		status.append(label)
	print("Connected devices:\n" + "\n".join(status))

func _join_player(device: int, team: String):
	print("Player Joining")
	for i in MAX_PLAYERS:
		if not player_data.has(i):
			player_data[i] = { "device": device, "team": team }
			_show_player(i)
			player_joined.emit(i)
			print("Player", i, "joined using device", device)
			return
	print("No free slots for device", device)

func _remove_player(index: int):
	print("Removing Player")
	if player_data.has(index):
		_clear_panel(index)
		player_data.erase(index)
		player_left.emit(index)
		print("Player", index, "removed")

func _show_player(index: int):
	print("Showing Player %d" % index)

	if index >= player_panels.size():
		print("Invalid player index:", index)
		return

	var panel = player_panels[index]
	var viewport = panel.get_node_or_null("PJVBox/PJSVPContainer/PJSVP")
	if viewport == null:
		print("Missing viewport for player", index)
		return

	viewport.world_3d = World3D.new()
	var model = load(PLAYER_MODELS[index]).instantiate()
	viewport.add_child(model)

	var rig = model.get_node_or_null("Rig_Human")
	if rig and rig is Node3D:
		rig.scale = Vector3.ONE * 0.5
		rig.position = Vector3(0, -1, 0)

	var mesh = model.get_node_or_null("Rig_Human/Skeleton3D/Cube")
	if mesh and mesh is MeshInstance3D:
		var color = PLAYER_COLORS[index]
		var original_mat = mesh.get_active_material(0)
		if original_mat and original_mat is StandardMaterial3D:
			var mat = original_mat.duplicate()
			mat.albedo_color = color
			mesh.set_surface_override_material(0, mat)

	var anim = model.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("Idle_Holding"):
		anim.play("Idle_Holding")

	var label = panel.get_node_or_null("PJVBox/PJStatusLabel")
	if label:
		label.text = "READY!"

func _clear_panel(index: int):
	print("Panel Cleared")
	var panel_path = "Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin%d" % (index + 1)
	var panel = get_node_or_null(panel_path)
	if panel == null:
		print("Missing panel to clear for player", index)
		return

	var viewport = panel.get_node_or_null("PJVBox/PJSVPContainer/PJSVP")
	if viewport:
		for child in viewport.get_children():
			child.queue_free()

	var label = panel.get_node_or_null("PJVBox/PJStatusLabel")
	if label:
		label.text = "PRESS A TO JOIN"

func _device_joined(device: int) -> bool:
	for entry in player_data.values():
		if entry.device == device:
			return true
	return false

func _get_player_index_for_device(device: int) -> int:
	for i in player_data:
		if player_data[i].device == device:
			return i
	return -1

func _start_game_immediately():
	var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	label.text = "Starting Now!"
	print("Starting game now!")
	_start_game_countdown()

# Countdown Variables
var countdown_time := 3
var countdown_timer: Timer
var countdown_active := false

# Called every frame to check join/start conditions
func _check_start_conditions():
	if countdown_active:
		return  # Don't override the label during countdown

	var total_players = player_data.size()

	for device in Input.get_connected_joypads():
		if MultiplayerInput.is_action_just_pressed(device, "Start"):
			_start_game_immediately()
			return

		if total_players >= MAX_PLAYERS and MultiplayerInput.is_action_just_pressed(device, "Connect"):
			_start_game_countdown()
			return

	if total_players >= MAX_PLAYERS:
		var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
		if label:
			label.text = "PRESS A TO CONTINUE"

# Start countdown to launch game
func _start_game_countdown():
	print("Countdown started")
	countdown_time = 3
	countdown_active = true  # prevent label from being reset

	var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	if label:
		label.text = "Starting in 3..."

	if countdown_timer == null:
		countdown_timer = Timer.new()
		countdown_timer.name = "CountdownTimer"
		countdown_timer.wait_time = 1.0
		countdown_timer.one_shot = false
		countdown_timer.timeout.connect(_on_countdown_tick)
		add_child(countdown_timer)

	countdown_timer.start()

# Countdown tick handler
func _on_countdown_tick():
	countdown_time -= 1

	var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	if label:
		if countdown_time > 0:
			label.text = "Starting in %d..." % countdown_time
		else:
			label.text = "Starting!"
			countdown_timer.stop()
			_start_game()


func _start_game():
	$"Player Select".hide()
	print("TODO: Hook in main game start logic here (Danny's domain)")
