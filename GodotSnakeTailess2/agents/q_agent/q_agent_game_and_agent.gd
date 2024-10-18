extends Node2D

# Q-Learning parameters
var alpha = 0.1
var gamma = 0.9
var epsilon = 0.1
var q_table = {}

# Game parameters
var nodules_captured = 0
var max_nodules = 9
var episode_count = 0  # Count of training episodes

# Directions and snake movement
enum Action {UP, DOWN, LEFT, RIGHT}
var actions = [Action.UP, Action.DOWN, Action.LEFT, Action.RIGHT]
var snake_position = Vector2(5, 5)  # Starting position
var nodule_position = Vector2()  # Position of the power nodule

# Variables for game rendering
var snake_sprite_scene = preload("res://common/rocket.tscn")
var nodule_sprite_scene = preload("res://common/power_node.tscn")
var snake_sprite = null
var nodule_sprite = null

# Label for episodes (UI)
var episode_label = null

# Called when the node enters the scene
func _ready():
	# Initialize snake and nodule positions
	snake_position = Vector2(5, 5)
	nodule_position = get_random_nodule_position()

	# Instantiate the snake and nodule sprites
	snake_sprite = snake_sprite_scene.instance()
	nodule_sprite = nodule_sprite_scene.instance()

	# Add the instantiated sprites to the scene tree
	add_child(snake_sprite)
	add_child(nodule_sprite)

	# Initialize sprite positions
	snake_sprite.position = snake_position
	nodule_sprite.position = nodule_position

	# Initialize episode tracking label
	episode_label = Label.new()
	episode_label.text = "Episodes: 0"
	add_child(episode_label)
	nodules_captured = 0

# Q-learning step
func q_learning_step():
	var state = get_state()
	var action = choose_action(state)
	var old_position = snake_position
	
	# Move the snake
	move_snake(action)
	
	# Update the sprite positions on screen
	snake_sprite.position = snake_position
	nodule_sprite.position = nodule_position
	
	# Get reward
	var reward = get_reward(old_position, snake_position)
	
	# Update Q-table
	var next_state = get_state()
	update_q_table(state, action, reward, next_state)
	
	# Check if the snake captures a nodule
	if snake_position == nodule_position:
		nodules_captured += 1
		nodule_position = get_random_nodule_position()
	
	# End episode if the agent captures all nodules
	if nodules_captured >= max_nodules:
		episode_count += 1  # Increment episode count
		print("Episode: ", episode_count, " Nodules Captured: ", nodules_captured)
		update_episode_label()
		reset_game()

# Get the current state (relative position to nodule)
func get_state():
	var delta = nodule_position - snake_position
	return delta

# Choose an action using epsilon-greedy strategy
func choose_action(state):
	if randf() < epsilon:
		return actions[randi() % actions.size()]  # Exploration
	else:
		if q_table.has(state):
			return get_best_action(state)  # Exploitation
		else:
			return actions[randi() % actions.size()]  # Random action

# Move the snake based on action
func move_snake(action):
	match action:
		Action.UP:
			snake_position.y -= 1
		Action.DOWN:
			snake_position.y += 1
		Action.LEFT:
			snake_position.x -= 1
		Action.RIGHT:
			snake_position.x += 1

# Get reward based on movement
func get_reward(old_position, new_position):
	var old_distance = old_position.distance_to(nodule_position)
	var new_distance = new_position.distance_to(nodule_position)
	
	if new_position == nodule_position:
		return 5  # Captured the nodule
	elif new_distance < old_distance:
		return 1  # Moved closer to the nodule
	else:
		return -1  # Moved farther away

# Update Q-table
func update_q_table(state, action, reward, next_state):
	if !q_table.has(state):
		q_table[state] = [0, 0, 0, 0]  # Initialize state-action values
	
	var q_value = q_table[state][action]
	var max_q_value = 0.0
	
	if q_table.has(next_state):
		max_q_value = q_table[next_state].max()
	
	# Q-learning update rule
	q_table[state][action] = q_value + alpha * (reward + gamma * max_q_value - q_value)

# Get the best action for the current state
func get_best_action(state):
	return q_table[state].find(q_table[state].max())

# Reset the game after each episode
func reset_game():
	snake_position = Vector2(5, 5)
	nodule_position = get_random_nodule_position()
	nodules_captured = 0

# Get a random position for the power nodule
func get_random_nodule_position():
	return Vector2(randi() % 10, randi() % 10)

# Update method for each frame
func _process(delta):
	q_learning_step()

# Update the episode label each time an episode ends
func update_episode_label():
	episode_label.text = "Episodes: " + str(episode_count)
