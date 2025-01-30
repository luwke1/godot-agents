extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_multiplier = 2.0

var current_jumps = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Import and initialize neural networks for DQN (one online, one target for stability)
var q_network : NNET = NNET.new([11, 64, 64, 5], false)
var target_network : NNET = NNET.new([11, 64, 64, 5], false)

# Variables for Deep Q-Network (DQN) implementation
var epsilon := 1.0    # Exploration rate for epsilon-greedy policy
var gamma := 0.9      # Discount factor for future rewards
var replay_buffer := [] 
var max_buffer_size := 1200
var batch_size := 64
var target_update_frequency := 100
var step_count := 0
var state = []

var previous_distance = 0.0
var previous_state = null
var previous_action = null
var agent_position = self.position
var coin_position = 0

var coins = []
var vision = {}

var episodes = 0

var train_frequency := 30
var train_counter := 0

var level
var just_collected_coin = false
var TIME_LIMIT = 60
var decay_counter = 0

# ---- NEW VARIABLES FOR EPISODE CONTROL ----
var time_since_last_coin_collection = 0.0
var initial_position = Vector2()  # Will set in _ready()

func _ready() -> void:
	# Clears any old training data and sets up the environment.
	stop_training()
	
	# Get a reference to the parent node (the level).
	level = get_parent()
	# Record the initial position to reset back to when an episode ends.
	initial_position = position
	
	# Set up the Q-network with chosen optimizer and functions.
	q_network.use_Adam(0.0001)
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 2)
	q_network.set_function(BNNET.ActivationFunctions.identity, 3, 3)
	
	# Initialize the target network with the same settings.
	target_network.use_Adam(0.0001)
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 2)
	target_network.set_function(BNNET.ActivationFunctions.identity, 3, 3)
	
	# Copy the current Q-network weights into the target network.
	target_network.assign(q_network)
	
	# If a certain global variable indicates we want to load a pre-trained agent, do that now.
	if Globals.control_type == "agent":
		load_agent()

func _physics_process(delta):
	# Apply gravity and update counters
	apply_gravity(delta)
	time_since_last_coin_collection += delta

	# Update agent position and nearest coin
	agent_position = self.position
	coin_position = get_closest_coin()

	# If we have a previous state/action, compute a reward for the last step
	if previous_state != null and previous_action != null:
		var current_distance = (agent_position - coin_position).length()
		var reward = get_reward(previous_distance, current_distance, previous_action)
		previous_distance = current_distance
		
		# Gather the current state observations
		var current_state = get_state()
		print(current_state)
		
		# Check if the episode is done (only if Globals.control_type != "agent", as your code does)
		var done = false
		if Globals.control_type != "agent":
			if is_done():
				done = true
				# Override the reward for forced termination
				reward = -2
		
		# Store exactly one transition (either done=false or done=true)
		store_experience(previous_state, previous_action, reward, current_state, done)
		
		# If done, reset the agent and end this physics frame
		if done:
			reset_agent()
			episodes += 1
			return
			
		train_counter += 1
		if train_counter % train_frequency == 0 and replay_buffer.size() >= batch_size:
			train_dqn()
			train_counter = 0

		decay_counter += 1
		if decay_counter >= 30:
			epsilon = max(0.1, epsilon * 0.999)
			decay_counter = 0

		step_count += 1
		if step_count % target_update_frequency == 0:
			target_network.assign(q_network)
	else:
		# If this is the very first step, set up the initial state and distance
		previous_state = get_state()
		previous_distance = (agent_position - coin_position).length()

	# Now, choose the next action and execute it
	var action = choose_action(previous_state)
	execute_action(action, delta)
	previous_action = action
	just_collected_coin = false

func is_done() -> bool:
	# Check if too much time has passed without collecting a coin.
	if time_since_last_coin_collection >= TIME_LIMIT:
		return true
	return false

func stop_training():
	# Clears everything related to learning for a fresh start.
	replay_buffer.clear()
	previous_state = null
	previous_action = null
	previous_distance = 0.0
	print("Training has been stopped and memory cleared.")

func reset_agent():
	# Put the character back to the initial position, reset velocity, jumps, etc.
	position = initial_position
	velocity = Vector2.ZERO
	current_jumps = 0
	time_since_last_coin_collection = 0.0
	previous_state = null
	previous_action = null
	print("Episode done. Resetting agent to initial position.")

func get_state() -> Array:
	# This function gathers the agent's observations about its environment.
	
	# The difference between the agent and the coin's position (x and y).
	var distance_to_coin = coin_position - agent_position
	
	# Update our "vision" data from RayCast2D nodes.
	update_vision()
	
	return [
		distance_to_coin.x / 100,
		distance_to_coin.y / 100,
		vision["RayCast_Up"] / 100,
		vision["RayCast_UpRight"] / 100,
		vision["RayCast_Right"] / 100,
		vision["RayCast_DownRight"] / 100,
		vision["RayCast_Down"] / 100,
		vision["RayCast_DownLeft"] / 100,
		vision["RayCast_Left"] / 100,
		vision["RayCast_UpLeft"] / 100,
		int(is_on_floor())
	]

func execute_action(action: int, delta: float) -> void:
	# Executes the chosen action in the game world (move, jump, etc.).
	
	# Reset jump counter if we're on the floor.
	if is_on_floor():
		current_jumps = 0
	
	# Gradually slow down any leftover horizontal velocity.
	velocity.x = move_toward(velocity.x, 0, speed * delta)
	
	# Each number from 0 to 4 is a different action or combination of moves/jumps.
	match action:
		0: velocity.x = speed         # Move right
		1: velocity.x = -speed        # Move left
		2: jump_if_possible()         # Jump only
		3:
			jump_if_possible()        # Jump + Right
			velocity.x = speed
		4:
			jump_if_possible()        # Jump + Left
			velocity.x = -speed
	
	# Apply the velocity to the character in the 2D scene.
	move_and_slide()

func jump_if_possible():
	# Allows the character to jump if it hasn't used up its jump_count.
	if current_jumps < jump_count:
		velocity.y = jump_velocity
		current_jumps += 1

func update_vision():
	# For each RayCast2D in the character's node tree, measure distance to collision (if any).
	for child in get_children():
		if child is RayCast2D:
			if child.is_colliding():
				# Distance from the agent to where the ray hits something.
				var collision_point = (child.get_collision_point() - global_position).length()
				# Normalize the distance value so it doesn't become too large.
				vision[child.name] = collision_point
			else:
				# If there's no collision, store a default value (1).
				vision[child.name] = 1000

func get_reward(previous_distance, current_distance, action) -> float:
	var reward = 0.0

	# 1) Encourage active movement with a bigger per-step penalty if stuck:
	reward -= 0.02

	# 2) Large bonus if we actually collect a coin
	if just_collected_coin:
		reward += 120.0
		time_since_last_coin_collection = 0.0
		return reward

	# 3) Distance-based reward (positive if we get closer, negative if we go farther)
	var dist_improvement = previous_distance - current_distance
	reward += dist_improvement * 0.02  # scale to a moderate value

	# 4) Additional penalty if moving away from the coin
	if dist_improvement < 0:
		reward -= 0.05

	# 5) Time penalty for taking too long
	reward -= (time_since_last_coin_collection * 0.001)

	# 6) Heavier wall penalty so it doesn't hug walls
	for dir in ["Right", "Left"]:
		if vision.has("RayCast_"+dir) and vision["RayCast_"+dir] < 0.2:
			# Penalty for hugging a wall
			reward -= 0.2
			# Even bigger penalty if actually pressing into it
			if (dir == "Right" and action == 0) or (dir == "Left" and action == 1):
				reward -= 1.0
	
	#print(reward)
	return reward

func get_closest_coin() -> Vector2:
	# Search the level's children to find the nearest coin and return its position.
	
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

func choose_action(current_state):
	# Chooses which action to take based on epsilon-greedy strategy:
	#   With probability epsilon, pick a random action (exploration).
	#   Otherwise, pick the action that the Q-network says is best (exploitation).
	
	var action = 0
	
	if randf() < epsilon:
		# Random action if exploring.
		action = randi() % 5
	else:
		# Feed the current_state to our Q-network to get the predicted Q-values.
		q_network.set_input(current_state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		if q_values.size() > 0:
			# Find the action(s) that have the highest Q-value.
			var max_q_value = q_values.max()
			var best_actions = []
			for i in range(q_values.size()):
				if q_values[i] == max_q_value:
					best_actions.append(i)
			
			# If there's more than one best action, pick randomly among them.
			if best_actions.size() > 0:
				action = best_actions[randi() % best_actions.size()]
			else:
				action = randi() % 5
		else:
			# If no Q-values, just pick randomly.
			action = randi() % 5
	
	return action

func store_experience(state, action, reward, next_state, done):
	# Adds the latest (state, action, reward, next_state, done) to the replay buffer.
	# If the buffer is full, remove the oldest entry to make space.
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
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
	# Apply gravity to the character if not on the floor, scaled by gravity_muultiplier.
	if not is_on_floor():
		velocity.y += gravity * gravity_multiplier * delta 

func _on_area_2d_body_entered(body):
	# This function is called when the character (Area2D) touches something.
	# If it's a collectible, we collect it, update the score, and set a flag for a reward.
	if body.is_in_group("collectable"):
		var coin_value = body.value
		level.update_ui_score(coin_value)
		body.collect()
		just_collected_coin = true

func save_agent():
	# Saves the Q-network's weights and some training data to files so we can load them later.
	
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"

	var weights_file = FileAccess.open(weights_path, FileAccess.WRITE)
	if weights_file == null:
		push_error("Failed to open weights file for writing: ", weights_path)
	else:
		q_network.save_binary(weights_path)
		print("Q-network weights saved to ", weights_path)

	var agent_data = {
		"epsilon": epsilon,
		"gamma": gamma,
		"step_count": step_count,
		"train_counter": train_counter,
	}

	stop_training()
	var agent_file = FileAccess.open(agent_data_path, FileAccess.WRITE)
	if agent_file == null:
		push_error("Failed to open agent data file for writing: ", agent_data_path)
	else:
		agent_file.store_var(agent_data)
		agent_file.close()
		print("Agent parameters saved to ", agent_data_path)
	
func load_agent():
	# Loads the Q-network's saved weights and parameters, then applies them to our current agent.
	print("Agent states reset after loading.")
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"

	if not FileAccess.file_exists(weights_path):
		push_error("Weights file does not exist: ", weights_path)
	else:
		q_network.load_data(weights_path)
		print("Q-network weights loaded from ", weights_path)
		target_network.assign(q_network)
		print("Target network synchronized with Q-network.")

	if not FileAccess.file_exists(agent_data_path):
		push_error("Agent data file does not exist: ", agent_data_path)
	else:
		var agent_file = FileAccess.open(agent_data_path, FileAccess.READ)
		if agent_file == null:
			push_error("Failed to open agent data file for reading: ", agent_data_path)
		else:
			var agent_data = agent_file.get_var()
			agent_file.close()

			if typeof(agent_data) != TYPE_DICTIONARY:
				push_error("Agent data corrupted or invalid format.")
				return

			epsilon = agent_data.get("epsilon", 1.0)
			gamma = agent_data.get("gamma", 0.9)
			step_count = agent_data.get("step_count", 0)
			train_counter = agent_data.get("train_counter", 0)
			print("Agent parameters loaded from ", agent_data_path)

			# After loading, we often set epsilon lower so it mostly exploits what it has learned.
			epsilon = 0.1
			print("Epsilon set to ", epsilon, " for exploitation.")
