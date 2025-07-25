extends Node2D

var cafe_scene = preload("res://levels/cafeteria/cafeteria.tscn")

# Signals to notify when a player joins or leaves
signal player_joined(player)
signal player_left(player)

# Constants
const MAX_PLAYERS = 4
const PLAYER_MODELS = [
	"res://entities/player/player.glb",
	"res://entities/player/player.glb",
	"res://entities/player/player.glb",
	"res://entities/player/player.glb"
]

#const PLAYER_COLORS = [
#	Color(0.5, 0, 0),     # Dark red
#	Color(1, 0.3, 0.3),   # Light red
#	Color(0, 0, 0.5),     # Dark blue
#	Color(0.4, 0.6, 1.0)  # Light blue
#]

# Tracks which devices are in which slots
var player_data: Dictionary = {}
var player_panels = []

var players = 0

var blue_team = 0
var red_team = 0

func unHide():
	$"Player Select".show()
	set_process(true)
	
func _restart():
	#print_tree_pretty()
	
	# Hide any menus left over like the game over UI
	for child in get_parent().get_children():
		if child != self and child is CanvasItem and child.visible:
			Log.info("Hiding leftover UI: %s" % child.name)
			child.hide()
	
	var main_menu = get_parent().get_node_or_null("MainMenu")
	#print(main_menu)
	Log.info("Restarting Player Select Screen")

	# Kick out all joined players and clear their panels
	for i in player_data.keys():
		_clear_panel(i)
		player_left.emit(i)
	player_data.clear()

	# Make sure all panels are back to 'Press A to Join'
	for i in player_panels.size():
		_clear_panel(i)

	# Reset the main label back to default
	var connect_label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	if connect_label:
		connect_label.text = "SELECT YOUR TEAM!"

	# Kill any countdowns that might be running
	countdown_active = false
	if countdown_timer and !countdown_timer.is_stopped():
		countdown_timer.stop()

	# Just in case the screen was hidden, show it again and resume input checks
	$"Player Select".show()
	set_process(true)

	Log.info("Player Select screen reset — waiting for input.")

func _ready():
	$"Player Select".hide()
	set_process(false)
	# Cache references to each player panel node using full paths
	player_panels = [
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin1",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin2",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin3",
		$"Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin4",
	]
	Log.info("Panel Index Loaded")

func _process(_delta):
	_check_start_conditions()

	# Check for new joins
	for device in _get_unjoined_devices():
		if not _device_joined(device):
			if MultiplayerInput.is_action_just_pressed(device, "join_red"):
				Log.info("Device %s pressed join_red" % device)
				_join_team(device, "red")
			if MultiplayerInput.is_action_just_pressed(device, "join_blue"):
				Log.info("Device %s pressed join_blue" % device)
				_join_team(device, "blue")
				
	for joinedDevice in _get_joined_devices():
		if MultiplayerInput.is_action_just_pressed(joinedDevice, "leave"):
			_remove_player(_get_player_index_for_device(joinedDevice))

	# Debug output
	var status := []
	for device in Input.get_connected_joypads():
		var joined_index = _get_player_index_for_device(device)
		var label = "Device %d" % device
		label += " (joined as player %d)" % joined_index if joined_index >= 0 else " (not joined)"
		status.append(label)
	#Log.info("Connected devices:\n" + "\n".join(status))

func _join_player(device: int):
	Log.info("Player Joining")
	for i in MAX_PLAYERS:
		if not player_data.has(i):
			var team = "red" if i < 2 else "blue"
			Log.info("Assigning Player %s to %s team" % [i, team])  # DEBUG: announce team assignment
			player_data[i] = {
				"device": device,
				"team": team
			}
			_show_player(i)
			player_joined.emit(i)
			Log.info("Player %s joined using device %s" % [i, device])
			return
	Log.info("No free slots for device", device)
	

func _join_team(device: int, team: String):
	Log.info("Device %s Joining Team %s " % [device, team])
	for i in MAX_PLAYERS:
		if not player_data.has(i):
			var team_pos : int
			
			if team == "red":
				if red_team == 2:
					Log.info("Red team full! Can't join this team.")
					return
				else:
					team_pos = red_team
					red_team += 1
			elif team == "blue":
				if blue_team == 2:
					Log.info("Blue team full! Can't join this team.")
					return
				else:
					team_pos = blue_team + 2
					blue_team += 1
			else:
				Log.err("Invalid team %s passed to _join_team." % team)
				
			players += 1
						
			Log.info("Adding device %s to %s team with player_num %s and panel pos %s" % [device, team, i + 1, team_pos])
			
			player_data[i] = {
				"device": device,
				"team": team,
				"player_num": i + 1,
				"pos": team_pos
			}
				
			_show_player(i)
			player_joined.emit(i)
			Log.info("Player %s joined %s team using device %s" % [i + 1, team, device])
			return
	Log.info("No free slots for device", device)
	

func _remove_player(index: int):
	Log.info("Removing Player")
	if player_data.has(index):
		players -= 1
		
		if _get_player_data(index, "team") == "red":
			red_team -= 1
		elif _get_player_data(index, "team") == "blue":
			blue_team -= 1
			
		_clear_panel(_get_player_data(index, "pos"))
		player_data.erase(index)
		player_left.emit(index)
		Log.info("Player %s removed" % _get_player_data(index, "player_num"))

func _show_player(index: int):
	Log.info("Showing Player %d" % index)

	if index >= player_panels.size():
		Log.info("Invalid player index:", index)
		return

	var panel = player_panels[_get_player_data(index, "pos")]
	var viewport = panel.get_node_or_null("PJVBox/PJSVPContainer/PJSVP")
	if viewport == null:
		Log.info("Missing viewport for player", index)
		return
	
	# Need this if for the restart to work. 
	if viewport.world_3d == null:
		viewport.world_3d = World3D.new()
	var model = load("res://entities/player/player.glb").instantiate()
	model.name = "PlayerModel" #This let's us clear them later.
	viewport.add_child(model)

	var rig = model.get_node_or_null("Rig_Human")
	if rig and rig is Node3D:
		rig.scale = Vector3.ONE * 0.5
		rig.position = Vector3(0, -1, 0)

	var mesh = model.get_node_or_null("Rig_Human/Skeleton3D/Cube")
	if mesh and mesh is MeshInstance3D:
		var texture = g.Player_Textures[_get_player_data(index, "pos")]
		var original_mat = mesh.get_active_material(0)
		if original_mat:
			var mat = original_mat.duplicate()
			mat.albedo_texture = texture
			mesh.set_surface_override_material(0, mat)
			

	var anim = model.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("Idle_Holding"):
		anim.play("Idle_Holding")

	var label = panel.get_node_or_null("PJVBox/PJStatusLabel")
	if label:
		label.text = "READY!"

func _clear_panel(index: int):
	Log.info("Panel Cleared")
	var panel_path = "Player Select/PanelContainer/VBoxContainer/JSHBox/PlayerJoin%d" % (index + 1)
	var panel = get_node_or_null(panel_path)
	if panel == null:
		Log.info("Missing panel to clear for player", index)
		return

	var viewport = panel.get_node_or_null("PJVBox/PJSVPContainer/PJSVP")
	if viewport:
		var model = viewport.get_node_or_null("PlayerModel")
		if model:
				model.queue_free()

	var label = panel.get_node_or_null("PJVBox/PJStatusLabel")
	if label:
		if index < 2:
			label.text = "PRESS A/X TO JOIN"
		elif index >= 2:
			label.text = "PRESS B/O TO JOIN"

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
# Starts the game early if at least 1 player has joined. 
func _start_game_immediately():
	if player_data.size() == 0:
		Log.info("No players have joined, can't start game yet.")
		return	
	
	var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	label.text = "Starting Now!"
	Log.info("Starting game now!")
	_start_game_countdown()

# Countdown Variables
var countdown_time := 5
var countdown_timer: Timer
var countdown_active := false

# Called every frame to check join/start conditions
func _check_start_conditions():
	if countdown_active:
		return  # Don't override the label during countdown

	var total_players = player_data.size()

	for device in _get_joined_devices():
		if MultiplayerInput.is_action_just_pressed(device, "Start"):
			_start_game_immediately()
			return

		if total_players >= MAX_PLAYERS and (MultiplayerInput.is_action_just_pressed(device, "join_red") or MultiplayerInput.is_action_just_pressed(device, "join_blue")):
			_start_game_countdown()
			return

	if total_players >= MAX_PLAYERS:
		var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
		if label:
			label.text = "PRESS A TO CONTINUE"

# Start countdown to launch game
func _start_game_countdown():
	Log.info("Countdown started")
	countdown_time = 5
	countdown_active = true  # prevent label from being reset
	
	$CombatMusic.play()

	var label = $"Player Select/PanelContainer/VBoxContainer/ConnectLabel"
	if label:
		label.text = "Starting in 5..."

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
			
		

# How many players are currently in?
func _get_player_count():
	return player_data.size()

# Get a list of joined player indexes (e.g. [0, 1])
func _get_player_indexes():
	return player_data.keys()

# Get the device ID associated with a player
func _get_player_device(player: int) -> int:
	return _get_player_data(player, "device")

# get player data.
# null means it doesn't exist.
func _get_player_data(player: int, key: StringName):
	if player_data.has(player) and player_data[player].has(key):
		return player_data[player][key]
	return null

# set player data to get later
func _set_player_data(player: int, key: StringName, value: Variant):
	# if this player is not joined, don't do anything:
	if !player_data.has(player):
		return
	player_data[player][key] = value


# Returns true if a device is already assigned to a player
func _is_device_joined(device: int) -> bool:
	for player_id in player_data:
		if _get_player_device(player_id) == device:
			return true
	return false

# Returns all gamepads that *aren’t* joined yet
func _get_unjoined_devices() -> Array:
	var devices = Input.get_connected_joypads()
	# Remove already-joined ones
	devices.append(-1)
	
	return devices.filter(func(device): return !_is_device_joined(device))
	
	
# Returns all gamepads that are joined yet
func _get_joined_devices() -> Array:
	var devices = Input.get_connected_joypads()
	
	if _is_device_joined(-1):
		devices.append(-1)
	
	return devices


func _start_game():
	$"Player Select".hide()
	Log.info("Starting Game")
	get_parent().add_child(cafe_scene.instantiate())
