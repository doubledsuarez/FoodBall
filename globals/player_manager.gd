extends Node
# player is 0-3
# device is -1 for keyboard/mouse, 0+ for joypads
# these concepts seem similar but it is useful to separate them so for example, device 6 could control player 1.

# Let the rest of the game know when players join or leave
signal player_joined(player)
signal player_left(player)

# map from player integer to dictionary of data
# the existence of a key in this dictionary means this player is joined.
# use get_player_data() and set_player_data() to use this dictionary.
var player_data: Dictionary = {}

const MAX_PLAYERS = 4  #UI is limited to 4

# Called when a device wants to join the game
func join(device: int):
	var player = next_player()
	if player >= 0:
		var team = "red" if player < 2 else "blue"
		print("Assigning Player", player, "to", team, "team")  # DEBUG: announce team assignment
		player_data[player] = {
			"device": device,
			"team": team
		}
		player_joined.emit(player)  # Tell everyone a player joined

# Remove a player from the game
func leave(player: int):
	if player_data.has(player):
		player_data.erase(player)
		player_left.emit(player)

# How many players are currently in?
func get_player_count():
	return player_data.size()

# Get a list of joined player indexes (e.g. [0, 1])
func get_player_indexes():
	return player_data.keys()

# Get the device ID associated with a player
func get_player_device(player: int) -> int:
	return get_player_data(player, "device")

# get player data.
# null means it doesn't exist.
func get_player_data(player: int, key: StringName):
	if player_data.has(player) and player_data[player].has(key):
		return player_data[player][key]
	return null

# set player data to get later
func set_player_data(player: int, key: StringName, value: Variant):
	# if this player is not joined, don't do anything:
	if !player_data.has(player):
		return
	player_data[player][key] = value

# Run this every frame in menus — handles controller "A" presses to join
func handle_join_input():
	for device in get_unjoined_devices():
		# If this device just pressed the "Connect" button (mapped to A), let them join
		if MultiplayerInput.is_action_just_pressed(device, "Connect"):
			print("Device", device, "pressed A — joining")
			join(device)

# Commenting out as not used here yet, logic exists on player select sscreen. 
# Leaving here for later just incase.  
# Check if anyone who's already joined is pressing Start
#func someone_wants_to_start() -> bool:
#	for player in player_data:
#		var device = get_player_device(player)
#		if MultiplayerInput.is_action_just_pressed(device, "Start"):
#			return true  # Someone’s ready to go
#	return false

# Returns true if a device is already assigned to a player
func is_device_joined(device: int) -> bool:
	for player_id in player_data:
		if get_player_device(player_id) == device:
			return true
	return false

# Returns the next open player slot (0–7), or -1 if full
func next_player() -> int:
	for i in MAX_PLAYERS:
		if !player_data.has(i):
			return i
	return -1

# Returns all gamepads that *aren’t* joined yet
func get_unjoined_devices():
	var devices = Input.get_connected_joypads()
	# Remove already-joined ones
	# Ignoring keyboards for now to simplify things. 
	return devices.filter(func(device): return !is_device_joined(device))
