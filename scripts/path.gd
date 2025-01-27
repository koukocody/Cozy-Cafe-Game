extends Node2D

@onready var player = $"../Player"

func _process(_delta):
	queue_redraw()
	
func _draw():
	if player.current_point_path.size() <= 1:
		return
	draw_polyline(player.current_point_path, Color.BLUE_VIOLET)
