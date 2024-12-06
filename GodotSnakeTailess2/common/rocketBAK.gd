extends RigidBody3D

# Time until the bomb detonates
var bombTime = 20

# Sensitivity for mouse input
var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

# Global positions and velocities
var launch_site = Global.launch_site
var rocket_position = Global.rocket_position
var rocket_speed = Global.rocket_velocity
var daisey_position = Global.power_node_position

# Maximum allowed time for an episode
var max_time := 120.0

# Time tracking variables
var start_time = Time.get_ticks_msec()
var current_time = 0

# Ready variables for pivot points in the scene
@onready var twist_pivot := $TwistPvot
@onready var pitch_pivot = $TwistPvot/PitchPivot

# Import and initialize neural networks for DQN
var q_network : NNET = NNET.new([2, 128, 8], false)
var target_network : NNET = NNET.new([2, 128, 8], false)

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

var episodes = 0 # Number of episodes completed

# Variables to control training frequency
var train_frequency := 6
var train_counter := 0

func _ready():
	# Capture the mouse for input
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = 1.0  # Increased damping for quicker momentum decay
	
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
	
	# Ensure initial positions are accurate
	rocket_position = position
	daisey_position = Global.power_node_position
	
	# Initialize previous distance between rocket and daisey
	previous_distance = (rocket_position - daisey_position).length()
	
	# Initialize the previous state
	previous_state = get_state()
	
	# Load a pre-trained agent if the flag is set
	if Global.team_agent_boolean:
		load_agent()

# Function to stop training and clear memory
func stop_training():
	replay_buffer.clear()
	previous_state = null
	previous_action = null
	previous_distance = 0.0
	print("Training has been stopped and memory cleared.")

func _physics_process(delta):
	# Update positions based on global variables
	daisey_position = Global.power_node_position
	rocket_position = position  # Update current position
	
	# Calculate elapsed time since start
	current_time = (Time.get_ticks_msec() - start_time)/1000
	
	# If the cancel action is pressed, make the mouse visible
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Check if bomb count has reached 80 to end the game
	if (Global.bombs == 80):
		stop_training()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://starting_folder/win_screen.tscn")
	
	# Update UI labels with current game state
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity.length()))
	$my_height.text = str(round(rocket_position.y))
	$my_bombs.text = str(Global.bombs)
	$power_node_location.text = str(round(Global.power_node_position.length()))
	
	$elapsed_time.text = str(round(current_time))
	
	# If there is a previous state and action, calculate the reward
	if previous_state != null and previous_action != null:
		# Calculate current distance to the daisey
		var current_distance = (rocket_position - daisey_position).length()
		
		# Get the reward based on distance change
		var reward = get_reward(previous_distance, current_distance)
		
		# Get the current state after taking the action
		var current_state = get_state()
		var done = is_done()
		
		# Store the experience in the replay buffer
		store_experience(previous_state, previous_action, reward, current_state, false)
		
		# Increment training counter and train DQN at specified frequency
		train_counter += 1
		if train_counter % train_frequency == 0 and replay_buffer.size() >= batch_size:
			train_dqn()
			train_counter = 0  # Reset the counter
		
		# Decay epsilon to reduce exploration over time
		# print(epsilon)  # Debugging line (commented out)
		epsilon = max(0.1, epsilon * 0.999)
		
		# Update the target network periodically
		step_count += 1
		if step_count % target_update_frequency == 0:
			target_network.assign(q_network)
		
		# If the episode is done, reset the agent
		if done:
			reset_agent()
		else:
			# Prepare for the next iteration by updating previous state and distance
			previous_state = current_state
			previous_distance = current_distance
	else:
		# First time initialization of previous state and distance
		previous_state = get_state()
		previous_distance = (rocket_position - daisey_position).length()
	
	# Agent chooses an action based on the current state
	var action = choose_action(previous_state)
	
	# Execute the chosen action
	execute_action(action)
	
	# Store the action for the next iteration's reward calculation
	previous_action = action

# Chooses an action using epsilon-greedy policy
func choose_action(current_state):
	var action = 0
	# Decide whether to explore or exploit
	if randf() < epsilon:
		# Explore: choose a random action
		action = randi() % 8 
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
				action = randi() % 8
		else:
			# Fallback to a random action if Q-values are empty
			action = randi() % 8
	
	# Return the selected action
	return action

# Stores an experience tuple in the replay buffer
func store_experience(state, action, reward, next_state, done):
	# Ensure the replay buffer does not exceed maximum size
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	# Append the new experience
	replay_buffer.append([state, action, reward, next_state, done])

# Retrieves the current state of the agent
func get_state() -> Array:
	var norm_factor = 50.0
	rocket_speed = linear_velocity
	# Calculate the vector distance to the daisey power node
	var distance_to_coin = daisey_position - rocket_position
	return [
		distance_to_coin.x / norm_factor,
		distance_to_coin.z / norm_factor
	]

# Executes the given action by applying force to the agent
func execute_action(action: int) -> void:
	var force = Vector3()
	match action:
		0: # Move right
			force = Vector3(1, 0, 0)
		1: # Move left
			force = Vector3(-1, 0, 0)
		2: # Move back
			force = Vector3(0, 0, 1)
		3: # Move forward
			force = Vector3(0, 0, -1)
		4: # Move forward-right
			force = Vector3(1, 0, -1).normalized()
		5: # Move forward-left
			force = Vector3(-1, 0, -1).normalized()
		6: # Move back-right
			force = Vector3(1, 0, 1).normalized()
		7: # Move back-left
			force = Vector3(-1, 0, 1).normalized()
	# Apply the calculated force to the center of mass
	apply_central_force(force * 40) 
	# Limit the agent's velocity to prevent excessive speed
	var max_speed = 10.0 
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

# Calculates the reward based on the agent's movement and state
func get_reward(previous_distance, current_distance):
	var distance_reward = 0
	var bounds = 50.0
	var time_penalty = -0.5
	var goal_reward = 0.0

	if Global.reward_for_pickup:
		# Reward for picking up the coin
		episodes += 1
		Global.reward_for_pickup = false  # Reset the pickup flag
		goal_reward += 40  # Add goal reward
		# Reset previous_distance to avoid large negative rewards
		previous_distance = (rocket_position - daisey_position).length()
	else:
		# Calculate reward based on distance improvement
		distance_reward = (previous_distance - current_distance) * 25

		if current_distance > previous_distance:
			distance_reward += -3  # Penalty for moving away
		else:
			distance_reward += 1   # Reward for moving closer

	# Penalize if the agent goes out of bounds
	if abs(rocket_position.x) > bounds or abs(rocket_position.z) > bounds:
		episodes += 1
		goal_reward -= 50  # Penalty for out of bounds

	# Combine all reward components
	var reward = distance_reward + time_penalty + goal_reward
	# print("Reward: ", reward)  # Debugging line (commented out)
	return reward

# Determines if the current episode is done
func is_done() -> bool:
	var bounds = 50.0
	# Check if the agent has moved out of bounds
	if abs(rocket_position.x) > bounds or abs(rocket_position.z) > bounds:
		print("Agent went out of bounds.")
		return true
	return false

# Resets the agent and environment for a new episode
func reset_agent() -> void:
	# Reset global variables and agent's state
	Global.bombs = 30
	position = launch_site  # Reset position to the launch site
	rocket_position = position
	linear_velocity = Vector3(0, 0, 0)  # Reset velocity
	start_time = Time.get_ticks_msec()  # Reset start time
	previous_state = get_state()  # Reinitialize state
	previous_distance = (rocket_position - daisey_position).length()
	previous_action = null  # Clear previous action
	print("Agent has been reset to the starting position.")

# Trains the Q-network using experiences from the replay buffer
func train_dqn() -> void:
	# Create a shuffled copy of the replay buffer
	var shuffled_buffer = replay_buffer.duplicate()
	shuffled_buffer.shuffle()

	# Select a random batch of experiences
	var batch = shuffled_buffer.slice(0, batch_size)
	
	var batch_states = []
	var batch_targets = []
	
	# Process each experience in the batch
	for experience in batch:
		var state = experience[0]
		var action = experience[1]
		var reward = experience[2]
		var next_state = experience[3]
		var done = experience[4]
		
		# Predict Q-values for the current state using Q-network
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		# Predict Q-values for the next state using target network
		target_network.set_input(next_state)
		target_network.propagate_forward()
		var target_output = target_network.get_output()
		
		# Get the maximum Q-value for the next state
		var max_next_q = target_output.max() if target_output.size() > 0 else 0
		
		# Compute the target Q-value using the Bellman equation
		var target_q_value = reward
		if not done:
			target_q_value += gamma * max_next_q
		
		# Update the Q-value for the taken action
		var target_q_values = q_values.duplicate()
		target_q_values[action] = target_q_value
		
		# Append the state and updated Q-values to the training batch
		batch_states.append(state)
		batch_targets.append(target_q_values)
	
	# print(q_network.get_loss(batch_states, batch_targets))  # Debugging line (commented out)
	
	# Train the Q-network with the batch of states and target Q-values
	q_network.train(batch_states, batch_targets)

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
	# Reset environment variables before loading
	previous_state = get_state()
	previous_distance = (rocket_position - daisey_position).length()
	previous_action = null
	
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
