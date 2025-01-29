# AStarGrid2D and tile movement assisted by https://www.youtube.com/watch?v=DkAmGxRuCk4&t=614s

extends Node2D

@onready var tile_map = $"../MapManager"
@onready var player_body = $CharacterBody2D
@onready var player_sprite = $CharacterBody2D/AnimatedSprite2D
@onready var path = $"../Path"

var astar_grid: AStarGrid2D
var current_point_path: PackedVector2Array # Creating point array for painting path
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var idle_direction: String
var id_path: Array[Vector2i]
var interacted_customer: bool = false
var interacted_direction: Vector2

func _ready():
	update_astar_grid()

func _input(event):
	if event.is_action_pressed("move") == false:
		return
	var destination = get_global_mouse_position()
	set_destination(destination)

func _physics_process(_delta):
	move()

func update_astar_grid():
	### Function that sets the astar grid to whichever tile map layer is being used
	var map_manager = get_parent().get_node("MapManager")
	var current_map_name = map_manager.current_map_name
	tile_map = map_manager.get_node(current_map_name)
	astar_grid = tile_map.astar_grid
	
func set_destination(destination):
	### Function to create a path along the grid that the entity will walk along 
	# Handles case where a user might click to a new position while currently moving
	# If moving and input is recieved, bases next set of movements on the closest in-progress target tile
	# Basically forces movement to finish and arrive at upcoming tile before moving to a new one
	if is_moving:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(destination),
			true # allows partial paths for clicking on inaccessible tiles, with 4.4 Godot update (~February), also allows partial paths to "solid" tiles
		)
	# Else if not moving and input is recieved, creates set of movements based on current tile and desired tile
	# Standing on (0,0) and clicking (1,3) creates id_path array ex: [(0,1), (0,2), (0,3), (1,3)] and so on
	else:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(destination),
			true
		)
	# Sends path to outside function for movement
	if id_path.is_empty() == false:
		current_id_path = id_path
		# Creating point array for painting path for debugging purposes
		current_point_path = astar_grid.get_point_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(destination)
		)
		for i in current_point_path.size():
			current_point_path[i] = current_point_path[i] + Vector2(8,8)

func move():
	### Function to move entity along the path created in set_destination()
	var direction: Vector2
	# Do nothing while there is no path set to move on
	if current_id_path.is_empty():
		return
	# If initially not moving, sets target_position as first vector in path array and flags moving status to true
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	# Moves to first vector of current_id_path and specifies a direction vector
	global_position = global_position.move_toward(target_position, 1)
	direction = (global_position - target_position).normalized()
	# When moving in a specific direction, change to that animation and set directional walking animation
	set_animation(direction, 0)
	# When arrived at next tile in path array "target_position", remove current tile from list and check if any more steps are required
	if global_position == target_position:
		current_id_path.pop_front()
		# If more steps are required, repeat move() with target position set to the following tile
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		# If arrived, change animation to the directional idling animation and flag is_moving as false
		else:
			# Edge case to ensure entity is facing customer, might be redundant once get_id_path(.., .., true) works for inaccessble tiles
			if interacted_customer == true:
				set_animation(interacted_direction, 1)
				interacted_customer = false
			# Change animation to directional idling animation
			else:
				player_sprite.animation = idle_direction
			is_moving = false

func set_animation(direction, key):
	### Function to set animations of entities such as NPCs, player, etc.
	var animations = {
		Vector2(1, 0): ["walk_left", "idle_left"],
		Vector2(-1, 0): ["walk_right", "idle_right"],
		Vector2(0, 1): ["walk_up", "idle_up"],
		Vector2(0, -1): ["walk_down", "idle_down"]
		}
	# Searches animations map for direction vector and sets animation to desired key (0 for walking, 1 for idling)
	if direction in animations:
		player_sprite.animation = animations[direction][key]
		idle_direction = animations[direction][1]

func _on_customer_interacted():
	### Function that signals that an NPC was interacted with by the player 
	# Brings player to tile closest to customer and faces the customer, might be redundant once get_id_path(.., .., true) works for inaccessble tiles
	var interacted_location: Vector2
	var arrival_location: Vector2
	interacted_location = id_path.pop_back()
	arrival_location = id_path.back()
	interacted_direction = (arrival_location - interacted_location).normalized()
	interacted_customer = true
