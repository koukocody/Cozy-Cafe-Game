extends Node2D

@onready var tile_map = $"../MapManager"

var astar_grid: AStarGrid2D

func _ready():
	pass

func update_astar_grid():
	### Function that sets the astar grid to whichever tile map layer is being used
	var map_manager = get_parent().get_node("MapManager")
	var current_map_name = map_manager.current_map_name
	tile_map = map_manager.get_node(current_map_name)
	astar_grid = tile_map.astar_grid
