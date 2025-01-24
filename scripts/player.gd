# AStarGrid2D and tile movement assisted by https://www.youtube.com/watch?v=DkAmGxRuCk4&t=614s

extends Node2D

@onready var tile_map = $"../TileMapLayer"
@onready var player_sprite = $CharacterBody2D/AnimatedSprite2D

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var direction: Vector2
var is_moving: bool
var idle_direction : String

func _ready():
	player_sprite.animation = "idle_down"
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
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
	var id_path
	if event.is_action_pressed("move") == false:
		return
	if is_moving:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
	else:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
	if id_path.is_empty() == false:
		current_id_path = id_path

func _physics_process(_delta):
	if current_id_path.is_empty():
		return
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	global_position = global_position.move_toward(target_position, 1)
	direction = (global_position - target_position).normalized()
	print(direction)
	var animations = {
		Vector2(1, 0): ["walk_left", "idle_left"],
		Vector2(-1, 0): ["walk_right", "idle_right"],
		Vector2(0, 1): ["walk_up", "idle_up"],
		Vector2(0, -1): ["walk_down", "idle_down"]
			}
	if direction in animations:
		player_sprite.animation = animations[direction][0]
		idle_direction = animations[direction][1]

	if global_position == target_position:
		current_id_path.pop_front()
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			player_sprite.animation = idle_direction
			is_moving = false
