extends Node2D

var previous_menu: Node = null

func set_previous_menu(menu: Node) -> void:
	previous_menu = menu

func _ready():
	# Connect all the good stuff
	$"Options Menu/PanelContainer/omvboxmain/hboxmv/mvslider".value_changed.connect(_on_master_volume_changed)
	$"Options Menu/PanelContainer/omvboxmain/hboxmuv/muvslider".value_changed.connect(_on_music_volume_changed)
	$"Options Menu/PanelContainer/omvboxmain/hboxsfxv/sfxslider".value_changed.connect(_on_sfx_volume_changed)
	$"Options Menu/PanelContainer/omvboxmain/hboxwm/OptionButton".item_selected.connect(_on_window_mode_selected)
	$"Options Menu/PanelContainer/omvboxmain/backbutton".pressed.connect(_on_back_pressed)

	# Load whatever is currently set on the audio busses + window mode
	_load_initial_values()

func _on_back_pressed() -> void:
	config_helper.init_config_if_missing()

	var master = $"Options Menu/PanelContainer/omvboxmain/hboxmv/mvslider".value
	var music = $"Options Menu/PanelContainer/omvboxmain/hboxmuv/muvslider".value
	var sfx = $"Options Menu/PanelContainer/omvboxmain/hboxsfxv/sfxslider".value
	var window_mode = $"Options Menu/PanelContainer/omvboxmain/hboxwm/OptionButton".get_selected_id()

	config_helper.save_settings(master, music, sfx, window_mode)

	if previous_menu:
		previous_menu.show()
	queue_free()

# All these do exactly what they say
func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume("Master", value)

func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume("Music", value)

func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume("SFX", value)

# Set the audio bus volume in dB (value comes straight from the slider)
func _set_bus_volume(bus_name: String, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), value)

# Handle the window mode dropdown
func _on_window_mode_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

# Pull current values from the system and set them to the sliders/buttons
func _load_initial_values() -> void:
	var mv = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	var muv = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var sfxv = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	$"Options Menu/PanelContainer/omvboxmain/hboxmv/mvslider".value = mv
	$"Options Menu/PanelContainer/omvboxmain/hboxmuv/muvslider".value = muv
	$"Options Menu/PanelContainer/omvboxmain/hboxsfxv/sfxslider".value = sfxv

	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED:
			$"Options Menu/PanelContainer/omvboxmain/hboxwm/OptionButton".select(0)
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			$"Options Menu/PanelContainer/omvboxmain/hboxwm/OptionButton".select(1)
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			$"Options Menu/PanelContainer/omvboxmain/hboxwm/OptionButton".select(2)
