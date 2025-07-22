extends Button

func _ready():
	mouse_entered.connect(_on_mouse_entered)

func _on_mouse_entered():
	grab_focus()

func _pressed():
	var tween = create_tween()
	var shrink_scale = Vector2(0.92, 0.92)
	var original_pos = position
	var offset = (size - (size * shrink_scale)) * 0.5

	tween.parallel().tween_property(self, "scale", shrink_scale, 0.08)
	tween.parallel().tween_property(self, "position", original_pos + offset, 0.08)

	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.08).set_delay(0.08)
	tween.parallel().tween_property(self, "position", original_pos, 0.08).set_delay(0.08)
