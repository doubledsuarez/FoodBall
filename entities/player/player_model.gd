extends Node3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var cube_mesh := $Rig_Human/Skeleton3D/Cube

func set_player_texture(texture: Texture2D):
	var original_material = cube_mesh.get_active_material(0)
	if original_material:
		var new_material = original_material.duplicate()
		new_material.albedo_texture = texture
		cube_mesh.set_surface_override_material(0, new_material)
		
		
func attach_to_hand(held_object: Node3D):
	var hand_socket = $Rig_Human/Skeleton3D/Hand_Holds  # Your BoneAttachment3D
	if hand_socket and held_object:
		hand_socket.add_child(held_object)
		held_object.global_transform = hand_socket.global_transform

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set_player_texture(preload(""))
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#animation_player.play("Walk_Holding")
	#print( animation_player.get_current_animation_positition() )
	pass
