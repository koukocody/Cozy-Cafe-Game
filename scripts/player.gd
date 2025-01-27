# AStarGrid2D and tile movement assisted by https://www.youtube.com/watch?v=DkAmGxRuCk4&t=614s

extends Node2D

@onready var tile_map = $"../TileMapLayer"
@onready var player_body = $CharacterBody2D
@onready var player_sprite = $CharacterBody2D/AnimatedSprite2D

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var current_point_path: PackedVector2Array # Creating point array for painting path
var target_position: Vector2
var direction: Vector2
var is_moving: bool
var idle_direction: String
var id_path: Array[Vector2i]
var interacted_customer: bool = false
var interacted_direction: Vector2
var animations = {
	Vector2(1, 0): ["walk_left", "idle_left"],
	Vector2(-1, 0): ["walk_right", "idle_right"],
	Vector2(0, 1): ["walk_up", "idle_up"],
	Vector2(0, -1): ["walk_down", "idle_down"]
	}

func _ready():
	# AStarGrid2D grid initialization with cell size of 16x16
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	# Initialize grid map based on walkable tiles, makes non-walkable tiles impassable for pathfinding purposes
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			var tile_data = tile_map.get_cell_tile_data(tile_position)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)


func _input(event):
	if event.is_action_pressed("move") == false:
		return
	# Handles case where a user might click to a new position while currently moving
	# If moving and input is recieved, bases next set of movements on the closest in-progress target tile
	# Basically forces movement to finish and arrive at a tile before moving to a new one
	if is_moving:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(get_global_mouse_position()),
			true # allows partial paths for clicking on inaccessible tiles, with 4.4 Godot update (~February), also allows partial paths to "solid" tiles
		)
	# Else if not moving and input is recieved, creates set of movements based on current tile and desired tile
	# Standing on (0,0) and clicking (1,3) creates id_path array ex: [(0,1), (0,2), (0,3), (1,3)] and so on
	else:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(get_global_mouse_position()),
			true
		)
	if id_path.is_empty() == false:
		current_id_path = id_path
		# Creating point array for painting path
		current_point_path = astar_grid.get_point_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
		for i in current_point_path.size():
			current_point_path[i] = current_point_path[i] + Vector2(8,8)

func _physics_process(_delta):
	if current_id_path.is_empty():
		return
	# If initially not moving, sets target_position as first vector in path array and sets moving status
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	# Moves to first vector of current_id_path and specifies a direction vector
	global_position = global_position.move_toward(target_position, 1)
	direction = (global_position - target_position).normalized()
	# When moving in a specific direction, change to that animation and set directional idle animation
	if direction in animations:
		player_sprite.animation = animations[direction][0]
		idle_direction = animations[direction][1]
	# When arrived at next tile in path array "target_position", remove current tile from list and check if any more steps are required
	# If more steps are required, repeat movement with target position set to the following tile
	# If arrived, change animation to the directional idling animation and flag is_moving as completed
	if global_position == target_position:
		current_id_path.pop_front()
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			if interacted_customer == true:
				player_sprite.animation = animations[interacted_direction][1]
				interacted_customer = false
			else:
				player_sprite.animation = idle_direction
			is_moving = false

func _on_customer_interacted():
	# Brings player to tile closest to customer and faces the customer
	var interacted_location: Vector2
	var arrival_location: Vector2
	interacted_location = id_path.pop_back()
	arrival_location = id_path.back()
	interacted_direction = (arrival_location - interacted_location).normalized()
	interacted_customer = true
