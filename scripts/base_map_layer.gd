extends TileMapLayer

var astar_grid: AStarGrid2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# AStarGrid2D grid initialization with cell size of 16x16
	astar_grid = AStarGrid2D.new()
	astar_grid.region = get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	# Initialize grid map based on walkable tiles, makes non-walkable tiles impassable for pathfinding purposes
	for x in get_used_rect().size.x:
		for y in get_used_rect().size.y:
			var tile_position = Vector2i(
				x + get_used_rect().position.x,
				y + get_used_rect().position.y
			)
			var tile_data = get_cell_tile_data(tile_position)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)

func _process(_delta):
	pass
