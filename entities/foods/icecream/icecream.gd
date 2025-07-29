extends Food

var debuffedPlayer : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0
	type = "icecream"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hit(player : Player) -> void:
	if !player.isDebuffed:
		Log.info("Player %s hit with ice cream. Current speed is %s" % [player.player + 1, player.speed])
		player.isDebuffed = true
		#debuffedPlayer = player
		player.speed /= player.powerExp
		player.DebuffTimer.start()
		Log.info("Player debuffed. Current speed is %s" % player.speed)
	player.AniPlayer.stop()
	player.AniPlayer.play("Getting_Hit")
	player.inHitAni = true
	queue_free()
