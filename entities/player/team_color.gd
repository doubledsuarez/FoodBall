extends MeshInstance3D

var mat = StandardMaterial3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func assignTeamColor(team: String) -> void:
	if team == "red":
		mat.albedo_color = Color(1, 0, 0)
	elif team == "blue":
		mat.albedo_color = Color(0, 0, 1)

	self.material_override = mat
