extends TextureButton

func _ready():
	# On startup, set the label to the default color from the theme
	_set_label_color(_get_theme_color("font_color"))

	# Hook up all the button events to change colors when stuff happens
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_on_pressed)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_focus_entered():
	# When the button gets focus (keyboard/gamepad), use the focus color
	_set_label_color(_get_theme_color("font_focus_color"))

func _on_focus_exited():
	# Lost focus, go back to default color
	_set_label_color(_get_theme_color("font_color"))

func _on_pressed():
	# While the button is pressed down, show the pressed color
	_set_label_color(_get_theme_color("font_pressed_color"))

func _on_button_up():
	# After releasing, see if we're still hovered/focused
	if has_focus() or get_rect().has_point(get_local_mouse_position()):
		_set_label_color(_get_theme_color("font_focus_color"))
	else:
		_set_label_color(_get_theme_color("font_color"))

func _on_mouse_entered():
	# Mouse hover starts - switch to focus color
	_set_label_color(_get_theme_color("font_focus_color"))

func _on_mouse_exited():
	# Mouse left - go back to default
	_set_label_color(_get_theme_color("font_color"))

func _get_theme_color(name: String) -> Color:
	# Pulls a color from the active Theme resource under the Button category
	return get_theme_color(name, "Button")

func _set_label_color(color: Color):
	# Update the label's font color override
	if $Label:
		$Label.add_theme_color_override("font_color", color)
