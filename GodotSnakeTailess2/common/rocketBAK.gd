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
var q_network : NNET = NNET.new([6, 128, 4], false) # State size is 6 (position and velocity), hidden size is 128, action size is 4
var target_network : NNET = NNET.new([6, 128, 4], false) # Target network for stability

# Variables for DQN implementation
var epsilon := 0.8 # Epsilon for epsilon-greedy policy
var gamma := 0.99 # Discount factor
var replay_buffer := [] # Experience replay buffer
var max_buffer_size := 10000
var batch_size := 64
var target_update_frequency := 100 # Update target network every 100 steps
var step_count := 0 # Count the number of steps taken
var state = [] # Current state of the agent

var previous_distance = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Initialize the q_network and target_network
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.use_Adam(0.001)
	
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.use_Adam(0.001)
	
	# Initialize q_network with random weights
	q_network.reinit()  # reinit() will fill the weights randomly if designed properly in NNET
	
	# Initialize target_network as a copy of q_network (you can also leave it to be initialized independently)
	target_network.assign(q_network)

	if Global.team_agent_boolean == true:
		#print("made it to the team-learning agent ... hooray")
		Global.team_agent_boolean = false
	
	# Initialize state
	state = get_state()
	print("Initial State: ", state)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# handling parameter labels
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity.length()))
	rocket_position = position
	$my_height.text = str(round(rocket_position.y))
	$my_bombs.text = str(Global.bombs)
	$power_node_location.text = str(round(Global.power_node_position.length()))
	current_time = (Time.get_ticks_msec() - start_time)/1000
	$elapsed_time.text = str(round(current_time))
	
	previous_distance = (rocket_position - daisey_position).length()

	# check to exit human player when have collected enough daisies
	if Global.bombs >= 120 and Global.human_player_boolean and abs(rocket_position.x) < 0.5 and abs(rocket_position.z) < 0.5:
		# send control to the debrief page
		rocket_speed = Vector3.ZERO
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://agents/human_player/snake_human_debrief.tscn")

	# DQN Agent decision-making and learning loop
	#print("State before action selection.")
	var action = 0
	if randf() < epsilon:
		# Explore: choose a random action
		#print("Exploring: Random action.")
		action = randi() % 4 # Assuming 4 possible actions
	else:
		# Exploit: choose the best action based on the Q-network
		#print("Exploiting: Best action.")
		#print(state.size())
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		#print("Q-values for current state: ", q_values)
		
		# Select the action with the highest Q-value, handle multiple max actions
		if q_values.size() > 0:
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
			print("Warning: Q-values empty, using random action.")
			action = randi() % 4

	#print("Action: ", action)

	# Perform the action and observe the reward and next state
	execute_action(action)
	
	var reward = get_reward()
	#print("Reward: ", reward)
	var next_state = get_state()
	
	var done = is_done()
	#print("Episode Done: ", done)

	# Store experience in the replay buffer
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	replay_buffer.append([state, action, reward, next_state, done])
	#print([state, action, reward, next_state, done])

	# Train the Q-network if enough experiences are available
	if replay_buffer.size() >= batch_size:
		#print("Training DQN.")
		train_dqn()

	# Update epsilon to reduce exploration over time
	epsilon = max(0.1, epsilon * 0.99)
	

	# Update the target network periodically
	step_count += 1
	if step_count % target_update_frequency == 0:
		#print("Target network updated.")
		target_network.assign(q_network)

	# Update the state for the next iteration
	state = next_state

func get_state() -> Array:
	# Get the current state representation (e.g., position, velocity, etc.)
	rocket_speed = linear_velocity
	return [
		float(rocket_position.x), 
		float(rocket_position.z), 
		float(rocket_speed.x), 
		float(rocket_speed.z), 
		float(daisey_position.x - rocket_position.x), 
		float(daisey_position.z - rocket_position.z)
	]

func execute_action(action: int) -> void:
	# Execute the chosen action (e.g., apply force or change direction)
	match action:
		0:
			apply_central_force(Vector3(1, 0, 0) * 70)
		1:
			apply_central_force(Vector3(-1, 0, 0) * 70)
		2:
			apply_central_force(Vector3(0, 0, 1) * 70)
		3:
			apply_central_force(Vector3(0, 0, -1) * 70)

func get_reward() -> float:
	var distance_to_daisey = (rocket_position - daisey_position).length()

	# Reward for collecting the daisy
	if Global.bombs >= 120:
		return 100.0  # Massive reward for collecting enough daisies/bombs

	# Reward for being very close to the daisy
	if distance_to_daisey < 0.5:
		return 75.0  # High reward for being very close

	# Calculate distance change
	var distance_change = previous_distance - distance_to_daisey

	# Initialize reward
	var reward = 0.0

	# Reward for moving closer to the daisy
	if distance_change > 0:
		reward += distance_change * 20.0  # Positive reward proportional to closeness

	# Penalty for moving away from the daisy
	elif distance_change < 0:
		reward += distance_change * 20.0  # Negative reward proportional to distance increase

	# Time-Based Penalty
	var time_penalty = (current_time / max_time) * 5.0  # Scaling factor of 5.0 can be adjusted
	reward -= time_penalty

	# Additional Step Penalty to discourage unnecessary movements
	reward -= 0.5  # Fixed small penalty per step

	return float(reward)


#func get_reward() -> float:
	#var distance_to_daisey = (rocket_position - daisey_position).length()
#
	## Reward for collecting the daisy
	#if Global.bombs >= 120:
		#return 100.0  # Massive reward for collecting enough daisy/bombs
#
	## Reward for collecting the daisy when close enough
	#if distance_to_daisey < 1.0:
		#return 50.0  # Massive reward for collecting daisy
#
	## Reward for moving closer to the daisy
	#var distance_change = previous_distance - distance_to_daisey
	#if distance_change > 0:
		#return distance_change * 10  # Positive reward proportional to closeness
#
	## Penalty for moving away from the daisy
	#elif distance_change < 0:
		#return distance_change * 10  # Negative reward proportional to distance increase
#
	## Small step penalty to encourage faster completion
	#return -0.1

func is_done() -> bool:
	# Check if the episode is done
	return Global.bombs >= 120

func train_dqn() -> void:
	# Check if there's enough experiences in the replay buffer
	if replay_buffer.size() < batch_size:
		return  # Not enough experiences in the replay buffer to sample from
	
	# Randomly sample a batch from the replay buffer
	var batch = []
	for i in range(batch_size):
		batch.append(replay_buffer[randi() % replay_buffer.size()])
	
	var batch_states = []
	var batch_targets = []
	
	# Process the batch
	#for experience in batch:
		#var state = experience[0]
		#var action = experience[1]
		#var reward = experience[2]
		#var next_state = experience[3]
		#var done = experience[4]
		#
		## Forward propagate through the Q-network for the current state
		#q_network.set_input(state)
		#q_network.propagate_forward()
		#var q_values = q_network.get_output()
		#
		## Duplicate the Q-values to compute the target
		#var target_q_values = q_values.duplicate()
		#
		## Forward propagate through the target network for the next state
		#target_network.set_input(next_state)
		#target_network.propagate_forward()
		#var target_output = target_network.get_output()
		#print(target_output)
		#
		## Get the maximum Q-value for the next state
		#var max_next_q = target_output.max() if target_output.size() > 0 else 0
		#
		## Bellman equation: Q(s, a) = reward + gamma * max(Q(s', a'))
		#if done:
			#target_q_values[action] = reward  # No future rewards if episode is done
		#else:
			#target_q_values[action] = reward + gamma * max_next_q  # Include discounted future reward
		#
		## Append the state and the updated target Q-values to the batch
		#batch_states.append(state)
		#batch_targets.append(target_q_values)
	#
	##for i in batch_targets:
		##print(i)
			#
	##print(batch_states.size())
	##print(batch_targets.size())
	## Train the Q-network on the entire batch
	#q_network.train(batch_states, batch_targets)



#func train_dqn() -> void:
	## Check if there's enough experiences in the replay buffer
	#if replay_buffer.size() < batch_size:
		#return  # Not enough experiences in the replay buffer to sample from
	#
	## Randomly sample a batch from the replay buffer
	#var batch = []
	#for i in range(batch_size):
		#batch.append(replay_buffer[randi() % replay_buffer.size()])
	#
	#var batch_states = []
	#var batch_targets = []
	#
	## Process the batch
	#for experience in batch:
		#var state = experience[0]
		#var action = experience[1]
		#var reward = experience[2]
		#var next_state = experience[3]
		#var done = experience[4]
		#
		## Forward propagate through the Q-network for the current state
		#q_network.set_input(state)
		#q_network.propagate_forward()
		#var q_values = q_network.get_output()
		#
		## Duplicate the Q-values to compute the target
		#var target_q_values = q_values.duplicate()
		#
		## Forward propagate through the target network for the next state
		#target_network.set_input(next_state)
		#target_network.propagate_forward()
		#var target_output = target_network.get_output()
		#
		## Get the maximum Q-value for the next state
		#var max_next_q = target_output.max() if target_output.size() > 0 else 0
		#
		## Bellman equation: Q(s, a) = reward + gamma * max(Q(s', a'))
		#if done:
			#target_q_values[action] = reward  # No future rewards if episode is done
		#else:
			#target_q_values[action] = reward + gamma * max_next_q  # Include discounted future reward
		#
		## Append the state and the updated target Q-values to the batch
		#batch_states.append(state)
		#batch_targets.append(target_q_values)
	#
	## Train the Q-network on the entire batch
	#print(batch_states)
	#q_network.train(batch_states, batch_targets)
