extends Food

@onready var DebuffTimer = $DebuffTimer

var debuffedPlayer : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	type = "icecream"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hit(player : Player) -> void:
	debuffedPlayer = player
	player.speed /= 1.5
	DebuffTimer.start()
	queue_free()


func _on_debuff_timer_timeout() -> void:
	debuffedPlayer.speed *= 1.5
