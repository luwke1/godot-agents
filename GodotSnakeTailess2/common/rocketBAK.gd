extends RigidBody3D

var bombTime = 20

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

var launch_site = Global.launch_site
var rocket_position = Global.rocket_position
var rocket_speed = Global.rocket_velocity
var daisey_position = Global.power_node_position

var max_time := 120.0 # Maximum time in seconds (2 minutes)

var start_time = Time.get_ticks_msec()
var current_time = 0

@onready var twist_pivot := $TwistPvot
@onready var pitch_pivot = $TwistPvot/PitchPivot

# Import NNET
var q_network : NNET = NNET.new([6, 64, 4], false)
var target_network : NNET = NNET.new([6, 64, 4], false)

# Variables for DQN implementation
var epsilon := 1.0 # Epsilon for epsilon-greedy policy
var gamma := 0.99 # Discount factor
var replay_buffer := [] # Experience replay buffer
var max_buffer_size := 10000
var batch_size := 64
var target_update_frequency := 100 # Update target network every 100 steps
var step_count := 0 # Count the number of steps taken
var state = [] # Current state of the agent

var previous_distance = 0

# Training frequency variables
var train_frequency := 4
var train_counter := 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Initialize the q_network and target_network
	q_network.use_Adam(0.0001)
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	q_network.set_function(BNNET.ActivationFunctions.identity, 2,2)
	
	target_network.use_Adam(0.0001)
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	target_network.set_function(BNNET.ActivationFunctions.identity, 2,2)
	
	# Initialize networks
	q_network.reinit()
	target_network.reinit()
	
	# Copy the weights to target_network to be an exact copy
	target_network.assign(q_network)
	
	# Initialize state
	state = get_state()
	print("Initial State: ", state)
	
	# Initialize previous_distance
	previous_distance = (rocket_position - daisey_position).length()

func _physics_process(delta):
	daisey_position = Global.power_node_position
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update labels and other variables
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity.length()))
	rocket_position = position
	$my_height.text = str(round(rocket_position.y))
	$my_bombs.text = str(Global.bombs)
	$power_node_location.text = str(round(Global.power_node_position.length()))
	current_time = (Time.get_ticks_msec() - start_time)/1000
	$elapsed_time.text = str(round(current_time))
	
	# DQN Agent decision-making
	var action = choose_action(state)
	
	# Execute the action
	execute_action(action)
	
	# Physics update happens here, so the agent moves according to the action
	
	# Calculate reward based on the new state after action is executed
	var next_state = get_state()
	var reward = get_reward()
	var done = is_done()
	
	# Store experience in the replay buffer
	store_experience(state, action, reward, next_state, done)
	
	# Update the state for the next iteration
	state = next_state
	
	# Update previous_distance after updating the state
	previous_distance = (rocket_position - daisey_position).length()
	
	#print("Action: ",action, " -- Reward: ",reward, " -- Distance: ", previous_distance)
	
	# Training the network less frequently to reduce lag
	train_counter += 1
	if train_counter % train_frequency == 0 and replay_buffer.size() >= batch_size:
		train_dqn()
		train_counter = 0  # Reset the counter
	
	# Update epsilon to reduce exploration over time
	epsilon = max(0.1, epsilon * 0.995)
	
	# Update the target network periodically
	step_count += 1
	if step_count % target_update_frequency == 0:
		target_network.assign(q_network)

func choose_action(current_state):
	var action = 0
	if randf() < epsilon:
		# Explore: choose a random action
		print("random")
		action = randi() % 4  # Assuming 4 possible actions
	else:
		# Exploit: choose the best action based on the Q-network
		q_network.set_input(current_state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		# Select the action with the highest Q-value
		if q_values.size() > 0:
			print(q_values)
			var max_q_value = q_values.max()
			var best_actions = []
			for i in range(q_values.size()):
				if q_values[i] == max_q_value:
					best_actions.append(i)
			if best_actions.size() > 0:
				action = best_actions[randi() % best_actions.size()]
			else:
				action = randi() % 4
		else:
			action = randi() % 4
	return action

func store_experience(state, action, reward, next_state, done):
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	replay_buffer.append([state, action, reward, next_state, done])

func get_state() -> Array:
	rocket_speed = linear_velocity
	return [
		rocket_position.x, 
		rocket_position.z, 
		rocket_speed.x, 
		rocket_speed.z, 
		daisey_position.x - rocket_position.x, 
		daisey_position.z - rocket_position.z
	]

func execute_action(action: int) -> void:
	# Execute the chosen action
	match action:
		0: # Move right
			apply_central_force(Vector3(1, 0, 0) * 20)
		1: # Move left
			apply_central_force(Vector3(-1, 0, 0) * 20)
		2: # Move back
			apply_central_force(Vector3(0, 0, 1) * 20)
		3: # Move forward
			apply_central_force(Vector3(0, 0, -1) * 20)

func get_reward() -> float:
	var distance_to_daisey = (rocket_position - daisey_position).length()
	
	# Reward for collecting the daisy
	if distance_to_daisey < 0.5:
		previous_distance = (rocket_position - daisey_position).length()
		return 100.0  # Increased reward for collecting the coin
	
	# Small penalty for each time step to encourage faster completion
	var reward = -0.5
	
	# Reward proportional to the decrease in distance
	var distance_change = previous_distance - distance_to_daisey
	
	
	if distance_change > 0:
		reward += 10  # Reward for moving closer
	elif distance_change < 0:
		reward -= 10 + distance_to_daisey # Penalty for moving away
	
	# Update previous distance
	previous_distance = distance_to_daisey
	
	return reward

func is_done() -> bool:
	return Global.bombs >= 120

func train_dqn() -> void:
	# Shuffle the replay buffer and select a random batch of experiences without replacement
	var shuffled_buffer = replay_buffer.duplicate()
	shuffled_buffer.shuffle()

	# Get the first 'batch_size' experiences from the shuffled buffer
	var batch = shuffled_buffer.slice(0, batch_size)
	
	var batch_states = []
	var batch_targets = []
	
	# Process the batch
	for experience in batch:
		var state = experience[0]
		var action = experience[1]
		var reward = experience[2]
		var next_state = experience[3]
		var done = experience[4]
		
		# Forward propagate through the Q-network for the current state
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		# Forward propagate through the target network for the next state
		target_network.set_input(next_state)
		target_network.propagate_forward()
		var target_output = target_network.get_output()
		
		# Get the maximum Q-value for the next state
		var max_next_q = target_output.max() if target_output.size() > 0 else 0
		
		# Compute the target Q-value
		var target_q_value = reward
		if not done:
			target_q_value += gamma * max_next_q
		
		# Update the target Q-values
		var target_q_values = q_values.duplicate()
		target_q_values[action] = target_q_value
		
		# Append the state and the updated target Q-values to the batch
		batch_states.append(state)
		batch_targets.append(target_q_values)
	
	# Train the Q-network on the entire batch
	q_network.train(batch_states, batch_targets)
