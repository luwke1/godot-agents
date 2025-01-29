extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_muultiplier = 2.0

var current_jumps = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Import and initialize neural networks for DQN
var q_network : NNET = NNET.new([11, 128, 5], false)
var target_network : NNET = NNET.new([11, 128, 5], false)

# Variables for Deep Q-Network (DQN) implementation
var epsilon := 1.0 # Exploration rate for epsilon-greedy policy
var gamma := 0.9 # Discount factor for future rewards
var replay_buffer := [] # Buffer to store past experiences
var max_buffer_size := 1200 # Maximum size of the replay buffer
var batch_size := 64 # Number of experiences to sample for training
var target_update_frequency := 100 # Frequency to update target network
var step_count := 0 # Counter for the number of steps taken
var state = [] # Current state of the agent

# Variables to store previous state information
var previous_distance = 0.0
var previous_state = null
var previous_action = null
var agent_position = self.position
var coin_position = 0

var coins = []
var vision = {}

var episodes = 0 # Number of episodes completed

# Variables to control training frequency
var train_frequency := 30
var train_counter := 0

var level

var just_collected_coin = false

var TIME_LIMIT = 60

var decay_counter = 0

# ---- NEW VARIABLES FOR EPISODE CONTROL ----
var time_since_last_coin_collection = 0.0
var initial_position = Vector2()  # Will set in _ready()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stop_training()
	
	level = get_parent()
	
	 # Store the agent's initial position to reset later
	initial_position = position
	
	# Initialize the Q-network with Adam optimizer and MSE loss
	q_network.use_Adam(0.0005)
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	q_network.set_function(BNNET.ActivationFunctions.identity, 2, 2)
	
	# Initialize the target network similarly
	target_network.use_Adam(0.0005)
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	target_network.set_function(BNNET.ActivationFunctions.identity, 2, 2)
	
	# Synchronize target network with Q-network
	target_network.assign(q_network)
	
	# Load a pre-trained agent if the flag is set
	if Globals.control_type == "agent":
		load_agent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#print(epsilon)
	apply_gravity(delta)
	
	# Increase our "no coin" timer
	time_since_last_coin_collection += delta
	
	# Update positions based on global variables
	agent_position = self.position
	coin_position = get_closest_coin()
	
	# If there is a previous state and action, calculate the reward
	if previous_state != null and previous_action != null:
		# Calculate current distance to the daisey
		var current_distance = (agent_position - coin_position).length()
		
		# Get the reward based on distance change
		var reward = get_reward(previous_distance, current_distance, previous_action)
		
		previous_distance = current_distance
		
		# Get the current state after taking the action
		var current_state = get_state()
		#var done = is_done()
		
		# Store the experience in the replay buffer
		store_experience(previous_state, previous_action, reward, current_state, false)
		
		# Increment training counter and train DQN at specified frequency
		train_counter += 1
		if train_counter % train_frequency == 0 and replay_buffer.size() >= batch_size:
			train_dqn()
			train_counter = 0  # Reset the counter
		
		# Decay epsilon to reduce exploration over time
		decay_counter += 1
		if decay_counter >= 30: # e.g. once per second
			epsilon = max(0.1, epsilon * 0.999)
			decay_counter = 0
		
		# Update the target network periodically
		step_count += 1
		if step_count % target_update_frequency == 0:
			target_network.assign(q_network)
	else:
		# First time initialization of previous state and distance
		previous_state = get_state()
		previous_distance = (agent_position - coin_position).length()
	
	# --- Check if we're done (no coin in 10 seconds) ---
	if Globals.control_type != "agent":
		if is_done():
			# If we're done, store an experience with done = true and an extra penalty
			var current_state_done = get_state()
			store_experience(previous_state, previous_action, -2, current_state_done, true)

			# End of episode: reset
			reset_agent()
			episodes += 1
			return  # Skip and reset agent
	
	# Agent chooses an action based on the current state
	var action = choose_action(previous_state)
	
	# Execute the chosen action
	execute_action(action, delta)
	
	# Store the action for the next iteration's reward calculation
	previous_action = action
	
	just_collected_coin = false

func is_done() -> bool:
	# If no coin collected in 10 seconds, let's end the episode
	if time_since_last_coin_collection >= TIME_LIMIT:
		return true
	return false

# Function to stop training and clear memory
func stop_training():
	replay_buffer.clear()
	previous_state = null
	previous_action = null
	previous_distance = 0.0
	print("Training has been stopped and memory cleared.")

func reset_agent():
	# Reset position and velocity
	position = initial_position
	velocity = Vector2.ZERO

	# Reset jump counters
	current_jumps = 0
	
	# Reset "no coin" timer
	time_since_last_coin_collection = 0.0

	# Clear previous state/action so next frame is "fresh"
	previous_state = null
	previous_action = null

	print("Episode done. Resetting agent to initial position.")

# Retrieves the current state of the agent
func get_state() -> Array:
	var distance_to_coin = coin_position - agent_position
	update_vision()
	return [
		distance_to_coin.x / 100,
		distance_to_coin.y / 100,
		vision["RayCast_Up"],
		vision["RayCast_UpRight"],
		vision["RayCast_Right"],
		vision["RayCast_DownRight"],
		vision["RayCast_Down"],
		vision["RayCast_DownLeft"],
		vision["RayCast_Left"],
		vision["RayCast_UpLeft"],
		int(is_on_floor())
	]

# Executes the given action by applying force to the agent
func execute_action(action: int, delta: float) -> void:
	if is_on_floor():
		current_jumps = 0
	# Default to no horizontal movement
	velocity.x = move_toward(velocity.x, 0, speed * delta)
	match action:
		0: 
			# Move right
			velocity.x = speed
		1:
			# Move left
			velocity.x = -speed
		2:
			# Jump only
			jump_if_possible()
		3:
			# Jump + Right
			jump_if_possible()
			velocity.x = speed
		4:
			# Jump + Left
			jump_if_possible()
			velocity.x = -speed
	move_and_slide()

func jump_if_possible():
	if current_jumps < jump_count:
		velocity.y = jump_velocity
		current_jumps += 1

func update_vision():
	for child in get_children():
		if child is RayCast2D:  # Check if the child is a RayCast2D node
			if child.is_colliding():  # Check if the raycast detects a collision
				var collision_point = (child.get_collision_point() - global_position).length()
				vision[child.name] = collision_point / 150
			else:
				vision[child.name] = 1

func get_reward(prev_dist: float, curr_dist: float, action) -> float:
	var reward = 0.0
	
	# Distance-based reward (exponential)
	var distance_reward = exp(-curr_dist/500)  # Scale based on level size
	reward += distance_reward * 0.5
	
	# Movement-based rewards
	if abs(velocity.x) > 50:
		reward += 0.02  # Reward for maintaining momentum
		
	if curr_dist < prev_dist:
		reward += (prev_dist - curr_dist) * 0.02
	else:
		reward -= (curr_dist - prev_dist) * 0.03
	
	print(vision["RayCast_Left"])
	# Check raycasts for walls (values closer to 0 mean near a wall)
	for dir in ["Right", "Left"]: # Check relevant directions
		if vision["RayCast_"+dir] < 0.4: # Very close to wall
			reward -= 0.1
			if (dir == "Right" and action == 0) or (dir == "Left" and action == 1):
				reward -= 0.5 # Extra penalty for moving into wall

	# Successful jump reward
	if action in [2,3,4] and not is_on_floor() and velocity.y < 0:
		reward += 0.1

	# Coin collection bonus
	if just_collected_coin:
		reward += 15
		time_since_last_coin_collection = 0  # Reset timer
	
	# Time penalty (increases over time)
	reward -= time_since_last_coin_collection * 0.005
	
	#print(reward)
	return reward

func get_closest_coin() -> Vector2:
	var closest_coin = null
	var min_distance = INF
	var best_pos = Vector2.ZERO
	
	for child in level.get_children():
		if child.name.begins_with("collectible"):
			var test_pos = child.global_position
			var distance = (test_pos - agent_position).length()
			if distance < min_distance:
				min_distance = distance
				closest_coin = child
				best_pos = test_pos
	
	return best_pos

# Chooses an action using epsilon-greedy policy
func choose_action(current_state):
	var action = 0
	# Decide whether to explore or exploit
	if randf() < epsilon:
		# Explore: choose a random action
		action = randi() % 5
	else:
		# Exploit: choose the best action based on Q-network's prediction
		q_network.set_input(current_state)
		q_network.propagate_forward()
		
		# Get the predicted Q-values from the network
		var q_values = q_network.get_output()
		
		# Select the action with the highest Q-value
		if q_values.size() > 0:
			var max_q_value = q_values.max()
			var best_actions = []
			for i in range(q_values.size()):
				if q_values[i] == max_q_value:
					best_actions.append(i)
					
			# If multiple best actions, choose one randomly
			if best_actions.size() > 0:
				action = best_actions[randi() % best_actions.size()]
			else:
				# Fallback to a random action if no best action found
				action = randi() % 5
		else:
			# Fallback to a random action if Q-values are empty
			action = randi() % 5
	
	# Return the selected action
	return action

# Stores an experience tuple in the replay buffer
func store_experience(state, action, reward, next_state, done):
	# Ensure the replay buffer does not exceed maximum size
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	# Append the new experience
	replay_buffer.append([state, action, reward, next_state, done])


# Trains the Q-network using experiences from the replay buffer
func train_dqn() -> void:
	# Create a shuffled copy of the replay buffer
	var shuffled_buffer = replay_buffer.duplicate()
	shuffled_buffer.shuffle()

	# Select a random batch of experiences
	var batch = shuffled_buffer.slice(0, batch_size)
	
	var batch_states = []
	var batch_targets = []
	
	for experience in batch:
		var state     = experience[0]
		var action    = experience[1]
		var reward    = experience[2]
		var next_state= experience[3]
		var done      = experience[4]
		
		# -- 1) Get Q-values for the current state (online network) --
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		# -- 2) Double DQN logic: pick the best next action using the online net --
		q_network.set_input(next_state)
		q_network.propagate_forward()
		var next_q_online = q_network.get_output()
		
		# Find argmax action from the online network
		var best_next_action = 0
		var max_val = -INF
		for i in range(next_q_online.size()):
			if next_q_online[i] > max_val:
				max_val = next_q_online[i]
				best_next_action = i
		
		# -- 3) Evaluate that chosen action's Q-value using the target net --
		target_network.set_input(next_state)
		target_network.propagate_forward()
		var target_output = target_network.get_output()
		
		var double_q_value = target_output[best_next_action]
		
		# -- 4) Compute the Bellman target --
		var target_q_value = reward
		if not done:
			target_q_value += gamma * double_q_value
		
		# -- 5) Update the Q-value for the chosen action in q_values --
		var target_q_values = q_values.duplicate()
		target_q_values[action] = target_q_value
		
		# -- 6) Append the (state, updated Q-values) to our training batch --
		batch_states.append(state)
		batch_targets.append(target_q_values)
	
	# -- 7) Finally, train the online Q-network with the updated Q-value targets --
	q_network.train(batch_states, batch_targets)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * gravity_muultiplier * delta 

func _on_area_2d_body_entered(body):
	if body.is_in_group("collectable"):
		# For example, if the coin has a 'value' property or something similar:
		var coin_value = body.value
		
		level.update_ui_score(coin_value)
		body.collect()  # remove the coin, etc.

		# Set your reward trigger
		just_collected_coin = true


# Saves the trained agent's network weights and parameters to disk
func save_agent():
	# Define paths for saving weights and agent data
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"

	# Save the Q-network weights
	var weights_file = FileAccess.open(weights_path, FileAccess.WRITE)
	if weights_file == null:
		push_error("Failed to open weights file for writing: ", weights_path)
	else:
		q_network.save_binary(weights_path)
		print("Q-network weights saved to ", weights_path)

	# Prepare agent parameters for saving
	var agent_data = {
		"epsilon": epsilon,
		"gamma": gamma,
		"step_count": step_count,
		"train_counter": train_counter,
	}
	stop_training()
	# Serialize and save agent parameters
	var agent_file = FileAccess.open(agent_data_path, FileAccess.WRITE)
	if agent_file == null:
		push_error("Failed to open agent data file for writing: ", agent_data_path)
	else:
		agent_file.store_var(agent_data)
		agent_file.close()
		print("Agent parameters saved to ", agent_data_path)
	

# Loads a trained agent's network weights and parameters from disk
func load_agent():
	print("Agent states reset after loading.")
	# Define paths for loading weights and agent data
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"

	# Load the Q-network weights
	if not FileAccess.file_exists(weights_path):
		push_error("Weights file does not exist: ", weights_path)
	else:
		# Load weights directly into the Q-network
		q_network.load_data(weights_path)
		print("Q-network weights loaded from ", weights_path)

		# Synchronize the target network with the loaded Q-network
		target_network.assign(q_network)
		print("Target network synchronized with Q-network.")

	# Load agent parameters
	if not FileAccess.file_exists(agent_data_path):
		push_error("Agent data file does not exist: ", agent_data_path)
	else:
		var agent_file = FileAccess.open(agent_data_path, FileAccess.READ)
		if agent_file == null:
			push_error("Failed to open agent data file for reading: ", agent_data_path)
		else:
			var agent_data = agent_file.get_var()
			agent_file.close()

			# Validate the loaded data format
			if typeof(agent_data) != TYPE_DICTIONARY:
				push_error("Agent data corrupted or invalid format.")
				return

			# Restore agent parameters from the loaded data
			epsilon = agent_data.get("epsilon", 1.0)
			gamma = agent_data.get("gamma", 0.9)
			step_count = agent_data.get("step_count", 0)
			train_counter = agent_data.get("train_counter", 0)
			print("Agent parameters loaded from ", agent_data_path)

			# Optionally set epsilon to a lower value for exploitation
			epsilon = 0.1
			print("Epsilon set to ", epsilon, " for exploitation.")
