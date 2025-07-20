extends Node3D

var roundTimer : float = 20.0
var pointsToWin : int = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	g.roundTimer.connect("timeout", on_round_timer_timeout)
	g.roundTimer.set_wait_time(roundTimer)
	g.roundTimer.set_one_shot(true)
	g.roundTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$"Red Points".text = "Red Points: %s" % g.red_points
	$"Blue Points".text = "Blue Points: %s" % g.blue_points
	if g.roundTimer.get_time_left() != 0.0:
		$Countdown.text = "Time left: %s seconds" % ceili(g.roundTimer.get_time_left())

	if g.red_points == pointsToWin:
		$Countdown.text = "Round Over! Red team wins!"
		g.red_won.emit()
	if g.blue_points == pointsToWin:
		$Countdown.text = "Round Over! Blue team wins!"
		g.blue_won.emit()
	if g.blue_points == g.red_points and g.blue_points == pointsToWin and g.red_points == pointsToWin:
		Log.info("somehow both teams scored %s points on the same frame. crazy. it's a tie?" % pointsToWin)
		$Countdown.text = "Round Over! It was a tie!"
		g.tie.emit()

	clamp(g.red_points, 0, pointsToWin)
	clamp(g.blue_points, 0, pointsToWin)


func on_round_timer_timeout() -> void:
	if g.red_points > g.blue_points:
		$Countdown.text = "Round Over! Red team wins!"
		Log.info("red team wins!")
		g.red_won.emit()
	elif g.blue_points < g.red_points:
		$Countdown.text = "Round Over! Blue team wins!"
		Log.info("blue team wins!")
		g.blue_won.emit()
	else:
		$Countdown.text = "Round Over! It was a tie!"
		Log.info("it's a tie!")
		g.tie.emit()
