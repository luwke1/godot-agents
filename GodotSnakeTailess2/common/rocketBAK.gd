extends RigidBody3D

var bombTime = 20

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

var launch_site = Global.launch_site
var rocket_position = Global.rocket_position
var rocket_speed = Global.rocket_velocity
var daisey_position = Global.power_node_position

var start_time = Time.get_ticks_msec()
var current_time = 0

@onready var twist_pivot := $TwistPvot
@onready var pitch_pivot = $TwistPvot/PitchPivot

# Import NNET
var q_network : NNET = NNET.new([6, 128, 4], false) # State size is 6 (position and velocity), hidden size is 128, action size is 4
var target_network : NNET = NNET.new([6, 128, 4], false) # Target network for stability

# Variables for DQN implementation
var epsilon := 1.0 # Epsilon for epsilon-greedy policy
var gamma := 0.99 # Discount factor
var replay_buffer := [] # Experience replay buffer
var max_buffer_size := 10000
var batch_size := 64
var target_update_frequency := 100 # Update target network every 100 steps
var step_count := 0 # Count the number of steps taken
var state = [] # Current state of the agent

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Global.team_agent_boolean == true:
		print("made it to the team-learning agent ... hooray")
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

	# handling camera pitch and roll for player and all agents
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -0.5, 0.9)
	twist_input = 0.0
	pitch_input = 0.0

	# check to exit human player when have collected enough daisies
	if Global.bombs >= 120 and Global.human_player_boolean and abs(rocket_position.x) < 0.5 and abs(rocket_position.z) < 0.5:
		# send control to the debrief page
		rocket_speed = Vector3.ZERO
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://agents/human_player/snake_human_debrief.tscn")

	# DQN Agent decision-making and learning loop
	print("State before action selection.")
	var action = 0
	if randf() < epsilon:
		# Explore: choose a random action
		print("Exploring: Random action.")
		action = randi() % 4 # Assuming 4 possible actions
	else:
		# Exploit: choose the best action based on the Q-network
		print("Exploiting: Best action.")
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		if q_values.size() > 0:
			var max_q_value = q_values[0]
			for q in q_values:
				if q > max_q_value:
					max_q_value = q
			action = q_values.find(max_q_value)
		else:
			print("Warning: Q-values empty, using random action.")
			action = randi() % 4

	print("Action: ", action)

	# Perform the action and observe the reward and next state
	execute_action(action)
	var reward = get_reward()
	print("Reward: ", reward)
	var next_state = get_state()
	
	var done = is_done()
	print("Episode Done: ", done)

	# Store experience in the replay buffer
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	replay_buffer.append([state, action, reward, next_state, done])
	

	# Train the Q-network if enough experiences are available
	if replay_buffer.size() >= batch_size:
		print("Training DQN.")
		train_dqn()

	# Update epsilon to reduce exploration over time
	epsilon = max(0.1, epsilon * 0.995)
	

	# Update the target network periodically
	step_count += 1
	if step_count % target_update_frequency == 0:
		print("Target network updated.")
		target_network.assign(q_network)

	# Update the state for the next iteration
	state = next_state

func get_state() -> Array:
	# Get the current state representation (e.g., position, velocity, etc.)
	return [rocket_position.x, rocket_position.y, rocket_position.z, rocket_speed.x, rocket_speed.y, rocket_speed.z]

func execute_action(action: int) -> void:
	# Execute the chosen action (e.g., apply force or change direction)
	
	match action:
		0:
			apply_central_force(Vector3(1, 0, 0) * 200)
		1:
			apply_central_force(Vector3(-1, 0, 0) * 200)
		2:
			apply_central_force(Vector3(0, 0, 1) * 200)
		3:
			apply_central_force(Vector3(0, 0, -1) * 200)

func get_reward() -> float:
	# Define the reward function based on the current state
	if Global.bombs >= 120:
		print("Reward: collected enough bombs.")
		return 100.0 # Reward for collecting enough bombs
	elif (rocket_position - daisey_position).length() < 1.0:
		Global.bombs += 10 # Add points for collecting a daisy
		print("Daisy collected. Bombs: ", Global.bombs)
		return 10.0 + (1000.0 / max(1.0, current_time)) # Reward for collecting a daisy, incentivized by speed
	else:
		print("Penalty: No daisy collected.")
		return -1.0 # Small penalty to encourage faster completion

func is_done() -> bool:
	# Check if the episode is done
	return Global.bombs >= 120

func train_dqn() -> void:
	# Sample a batch of experiences from the replay buffer
	print("Sampling replay batch.")
	var batch = []
	for i in range(batch_size):
		batch.append(replay_buffer[randi() % replay_buffer.size()])

	# Train on each experience in the batch
	for experience in batch:
		var state = experience[0]
		var action = experience[1]
		var reward = experience[2]
		var next_state = experience[3]
		var done = experience[4]
		print("Training on experience. Action: ", action, " Reward: ", reward)
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		var target_q_values = q_values.duplicate()

		# Calculate target using the Bellman equation
		target_network.set_input(next_state)
		target_network.propagate_forward()
		var target_output = target_network.get_output()
		if target_output.size() > 0:
			var max_next_q = target_output[0]
			for q in target_output:
				if q > max_next_q:
					max_next_q = q
			if done:
				target_q_values[action] = reward
			else:
				target_q_values[action] = reward + gamma * max_next_q
		else:
			print("Warning: Skipping training, target output empty.")
			continue

		# Train the network with the updated target
		
		q_network.train([state], [target_q_values])

##################################################################
