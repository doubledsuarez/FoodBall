extends Node

# make config saves work in editor and hopefully work after compile. 
static func get_config_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://config.cfg")
	else:
		return OS.get_executable_path().get_base_dir().path_join("config.cfg")

var CONFIG_PATH := get_config_path()
const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"

# If no config file exists, write some defaults to it
func init_config_if_missing() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		Log.info("Config not found. Writing defaults.")
		# Defaults: 0 is full volume, -10 is a bit quieter, -80 would be silent
		config.set_value(SECTION_AUDIO, "master", 0.0)
		config.set_value(SECTION_AUDIO, "music", -10.0)
		config.set_value(SECTION_AUDIO, "sfx", -10.0)
		# First boot is in windowed mode. 
		config.set_value(SECTION_DISPLAY, "window_mode", 0)
		# Try to save config to file
		var save_err := config.save(CONFIG_PATH)
		if save_err != OK:
			Log.info("Failed to save default config. Error code: %s" % save_err)
	else:
		Log.info("Config loaded successfully.")

# Save values and verify everything actually stuck, might not need all the extra debug crap later, but it wasn't working so I added a ton of it. 
func save_settings(master: float, music: float, sfx: float, window_mode: int) -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		push_error("Failed to load config for saving. Error code: %s" % err)
		return

	# Save to disk
	config.set_value(SECTION_AUDIO, "master", master)
	config.set_value(SECTION_AUDIO, "music", music)
	config.set_value(SECTION_AUDIO, "sfx", sfx)
	config.set_value(SECTION_DISPLAY, "window_mode", window_mode)
	var save_err := config.save(CONFIG_PATH)
	if save_err != OK:
		push_error("Failed to save settings. Error code: %s" % save_err)
		return

	# Debug info: what we *tried* to save
	Log.info("\n--- DEBUG: SAVING SETTINGS ---")
	Log.info("Saving master slider:", master)
	Log.info("Saving music slider:", music)
	Log.info("Saving sfx slider:", sfx)
	Log.info("Saving window mode:", window_mode)

	# Load it again to confirm it's actually saved
	var verify_config := ConfigFile.new()
	var verify_err := verify_config.load(CONFIG_PATH)
	if verify_err == OK:
		Log.info("File check - master:", verify_config.get_value(SECTION_AUDIO, "master"))
		Log.info("File check - music:", verify_config.get_value(SECTION_AUDIO, "music"))
		Log.info("File check - sfx:", verify_config.get_value(SECTION_AUDIO, "sfx"))
		Log.info("File check - window_mode:", verify_config.get_value(SECTION_DISPLAY, "window_mode"))
	else:
		Log.info("Couldn’t reload config to verify. Error code: %s" % verify_err)

	# Apply to system (this actually changes the audio levels and window mode)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx)
	DisplayServer.window_set_mode(window_mode)

	# Confirm the system got the update
	Log.info("System check - master:", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	Log.info("System check - music:", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	Log.info("System check - sfx:", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	Log.info("System check - window mode:", DisplayServer.window_get_mode())
	Log.info("--- DEBUG END ---\n")

# Grab current settings from file and hand them off
func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		push_error("Failed to load config for reading. Error code: %s" % err)
		return

	var master: float = config.get_value(SECTION_AUDIO, "master", 0.0)
	var music: float = config.get_value(SECTION_AUDIO, "music", -10.0)
	var sfx: float = config.get_value(SECTION_AUDIO, "sfx", -10.0)
	var window_mode: int = config.get_value(SECTION_DISPLAY, "window_mode", 0)

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx)
	DisplayServer.window_set_mode(window_mode)

	Log.info("Config loaded.")
