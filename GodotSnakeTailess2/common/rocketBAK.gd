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
var q_network : NNET = NNET.new([6, 64, 8], false)
var target_network : NNET = NNET.new([6, 64, 8], false)

# Variables for DQN implementation
var epsilon := 1.0 # Epsilon for epsilon-greedy policy
var gamma := 0.99 # Discount factor
var replay_buffer := [] # Experience replay buffer
var max_buffer_size := 5000
var batch_size := 64
var target_update_frequency := 100 # Update target network every 100 steps
var step_count := 0 # Count the number of steps taken
var state = [] # Current state of the agent

var previous_distance = 0.0
var previous_state = null
var previous_action = null

# Training frequency variables
var train_frequency := 4
var train_counter := 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = 1.0  # Increased damping for quicker momentum decay
	
	# Initialize the q_network and target_network
	q_network.use_Adam(0.0005)
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	q_network.set_function(BNNET.ActivationFunctions.identity, 2, 2)
	
	target_network.use_Adam(0.0005)
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 1)
	target_network.set_function(BNNET.ActivationFunctions.identity, 2, 2)
	
	
	# Copy the weights to target_network to be an exact copy
	target_network.assign(q_network)
	
	# Ensure initial positions are accurate
	rocket_position = position
	daisey_position = Global.power_node_position
	
	# Initialize previous_distance
	previous_distance = (rocket_position - daisey_position).length()
	
	# Initialize previous_state
	previous_state = get_state()

func _physics_process(delta):
	daisey_position = Global.power_node_position
	rocket_position = position  # Update current position
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update labels and other variables
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity.length()))
	$my_height.text = str(round(rocket_position.y))
	$my_bombs.text = str(Global.bombs)
	$power_node_location.text = str(round(Global.power_node_position.length()))
	current_time = (Time.get_ticks_msec() - start_time)/1000
	$elapsed_time.text = str(round(current_time))
	
	# If we have a previous state and action, calculate the reward
	if previous_state != null and previous_action != null:
		var current_distance = (rocket_position - daisey_position).length()
		var reward = get_reward(previous_distance, current_distance)
		var current_state = get_state()
		var done = is_done()
		
		# Store experience in the replay buffer
		store_experience(previous_state, previous_action, reward, current_state, done)
		
		# Training the network less frequently to reduce lag
		train_counter += 1
		if train_counter % train_frequency == 0 and replay_buffer.size() >= batch_size:
			train_dqn()
			train_counter = 0  # Reset the counter
		
		# Update epsilon to reduce exploration over time
		epsilon = max(0.1, epsilon * 0.99)
		
		# Update the target network periodically
		step_count += 1
		if step_count % target_update_frequency == 0:
			target_network.assign(q_network)
		
		# Prepare for the next iteration
		previous_state = current_state
		previous_distance = current_distance
	else:
		# First time initialization
		previous_state = get_state()
		previous_distance = (rocket_position - daisey_position).length()
	
	# DQN Agent decision-making
	var action = choose_action(previous_state)
	
	# Execute the action
	execute_action(action)
	
	# Update previous_action for the next iteration
	previous_action = action

func choose_action(current_state):
	var action = 0
	if randf() < epsilon:
		# Explore: choose a random action
		#print("RNADOM action")
		action = randi() % 8 
	else:
		# Exploit: choose the best action based on the Q-network
		q_network.set_input(current_state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		# Select the action with the highest Q-value
		if q_values.size() > 0:
			var max_q_value = q_values.max()
			var best_actions = []
			for i in range(q_values.size()):
				if q_values[i] == max_q_value:
					best_actions.append(i)
			if best_actions.size() > 0:
				action = best_actions[randi() % best_actions.size()]
				#print("best action")
			else:
				action = randi() % 8
		else:
			action = randi() % 8
	return action

func store_experience(state, action, reward, next_state, done):
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	replay_buffer.append([state, action, reward, next_state, done])

func get_state() -> Array:
	var norm_factor = 50.0  # Adjust based on your environment's scale
	rocket_speed = linear_velocity
	var direction_to_coin = (daisey_position - rocket_position).normalized()
	return [
		rocket_position.x / norm_factor,
		rocket_position.z / norm_factor,
		rocket_speed.x / norm_factor,
		rocket_speed.z / norm_factor,
		direction_to_coin.x,
		direction_to_coin.z
	]

func execute_action(action: int) -> void:
	# Execute the chosen action
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
	apply_central_force(force * 40)  # Increased force for more movement
	# Limit the velocity
	var max_speed = 10.0  # Adjust as needed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func get_reward(previous_distance, current_distance):
	var distance_reward = (previous_distance - current_distance) * 500  # Positive if moving closer
	
	var bounds = 50.0
	
	var time_penalty = -0.1
	var goal_reward = 0.0
	
	if abs(rocket_position.x) > bounds or abs(rocket_position.z) > bounds:
		print(-150)
		goal_reward-=150
	
	if current_distance > previous_distance:
		distance_reward += -1
	else:
		distance_reward += 1
	
	if Global.reward_for_pickup:
		Global.reward_for_pickup = false  # Reset the reward flag
		goal_reward+=50
	
	var reward = distance_reward + time_penalty + goal_reward + goal_reward
	return reward

func is_done() -> bool:
	var bounds = 50.0
	# Check if the agent is out of bounds
	if abs(rocket_position.x) > bounds or abs(rocket_position.z) > bounds:
		print("Agent went out of bounds.")
		reset_agent()  # Reset the agent's position
		return true
	return false

func reset_agent() -> void:
	# Reset agent position and relevant variables
	position = launch_site  # Reset position to the launch site or any initial position
	rocket_position = position
	linear_velocity = Vector3(0, 0, 0)  # Reset velocity to zero
	start_time = Time.get_ticks_msec()  # Optionally reset the time
	previous_state = get_state()  # Reinitialize the state
	previous_distance = (rocket_position - daisey_position).length()
	print("Agent has been reset to the starting position.")

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
