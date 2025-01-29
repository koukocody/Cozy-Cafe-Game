extends Node2D

@onready var player = $"../Player"
@onready var current_map_name = "BaseMapLayer"
@onready var map_manager_array = ["BaseMapLayer", "FirstMapLayer"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _input(event):
	# Currently proceeds to new scene with ALT+Q action - set up this way for debugging/testing while coding
	# Future implementation will likely use one-way progressive map upgrades, so there will be events that call in specific maps
	if event.is_action_pressed("change_scene") == false:
		return
	switch_map(map_manager_array[1])
	map_manager_array.append(map_manager_array.pop_front())

func _process(_delta):
	pass

func switch_map(new_map_name):
	### Function to switch between tile map layers
	if current_map_name == new_map_name:
		return
	# Hide current map
	var current_map = get_node(current_map_name)
	current_map.hide()
	# current_map.queue_free() # only to be used when the maplayer will not be used again, ex: upgrading the kitchen means the previous layout wont ever be used for this save
	# Load new map
	current_map_name = new_map_name
	var new_map = get_node(new_map_name)
	new_map.show()
	# Update player and NPCs (pathfinding_entities) to use the new AStarGrid2D
	for entity in get_tree().get_nodes_in_group("pathfinding_entities"):
		entity.update_astar_grid()
