extends MeshInstance3D

func set_player_texture(texture: Texture2D):
	var original_material = get_active_material(0)
	if original_material:
		var new_material = original_material.duplicate()
		new_material.albedo_texture = texture
		set_surface_override_material(0, new_material)
