extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_multiplier = 2.0

var current_jumps = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var q_network : NNET = NNET.new([13,64,64, 3], false)
var target_network : NNET = NNET.new([13, 64,64, 3], false)

# --------------------------------------------------------------------------------
# DQN Hyperparameters and training settings
# --------------------------------------------------------------------------------
var epsilon := 1.0         # Exploration rate (starts high)
var gamma := 0.85             # Discount factor for future rewards
var replay_buffer := []
var max_buffer_size := 5000
var batch_size := 64
var target_update_frequency := 500
var step_count := 0
var train_frequency := 100
var train_counter := 0
var decay_counter = 0
var frames_per_action := 10  # The number of frames to continue one action (except jump)

# --------------------------------------------------------------------------------
# Tracking environment state
# --------------------------------------------------------------------------------
var previous_distance = 0.0
var previous_state = null
var previous_action = null
var agent_position = self.position
var coin_position = Vector2.ZERO

var vision = {}
var episodes = 0

var level
var just_collected_coin = false
var TIME_LIMIT = 30

# Reward logging
var rewards_file_path = "user://episode_rewards.csv"
var current_episode_reward = 0
var episode_num = 0
var episode_time = 0
var reward_for_action = 0

var collected_count = 0
var total_collectables = 0
var collectables = []

var time_since_last_coin_collection = 0.0
var initial_position = Vector2()

var action_count := 0        # The number of actions taken 
var action := 0
var previous_action_count := 0 # ensures training only happens once for a data set
var previous_action_count_target := 0 # ensures target update only happens once for a data set

# --------------------------------------------------------------------------------
# _ready() – Initialization, including network optimizer & loading collectables.
# --------------------------------------------------------------------------------
func _ready() -> void:
	stop_training()
	level = get_parent()
	initial_position = position
	collectables = get_tree().get_nodes_in_group("collectable")
	total_collectables = collectables.size()
	
	# Set up Q-network and target network with Adam optimizer and MSE loss.
	q_network.use_Adam(0.0001)
	q_network.set_loss_function(BNNET.LossFunctions.MSE)
	q_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 2)
	q_network.set_function(BNNET.ActivationFunctions.identity, 3, 3)
	
	target_network.use_Adam(0.0001)
	target_network.set_loss_function(BNNET.LossFunctions.MSE)
	target_network.set_function(BNNET.ActivationFunctions.ReLU, 1, 2)
	target_network.set_function(BNNET.ActivationFunctions.identity, 3, 3)
	target_network.assign(q_network)
	
	if Globals.control_type == "agent":
		load_agent()

# --------------------------------------------------------------------------------
# _physics_process() – Main training loop
# --------------------------------------------------------------------------------
func _physics_process(delta):
	apply_gravity(delta)
	time_since_last_coin_collection += delta
	episode_time += delta

	agent_position = self.position
	coin_position = get_closest_coin()

	# If we have a previous state/action, compute a reward and store experience.
	if previous_state != null and previous_action != null:
		var current_distance = (agent_position - coin_position).length()
		var reward = get_reward(current_distance, previous_action)
		var current_state = get_state()
		current_episode_reward += reward
		previous_distance = current_distance
		
		var done = false
		if Globals.control_type != "agent":
			if is_done():
				done = true
				reward = -10  # Penalize episode timeout
		
		reward_for_action += reward
		step_count += 1
		if step_count % frames_per_action == 0:
			store_experience(previous_state, previous_action, reward_for_action, current_state, done)
			previous_state = current_state
			reward_for_action = 0
		
		if done or collected_count == total_collectables:
			episode_num += 1
			print("Episode Reward:", current_episode_reward)
			append_episode_reward(episode_num, current_episode_reward, collected_count, epsilon, episode_time)
			current_episode_reward = 0
			episode_time = 0
			reset_agent()
			reset_collectables()
			episodes += 1
			return
			
		if action_count % train_frequency == 0 and replay_buffer.size() >= batch_size and action_count != previous_action_count:
			print("training dqn")
			train_dqn()
			train_counter = 0
			previous_action_count = action_count

		decay_counter += 1
		if decay_counter >= 240:
			# Decay epsilon gradually; consider a more aggressive schedule if needed.
			print(epsilon)
			epsilon = max(0.01, epsilon * 0.999)
			decay_counter = 0
			
		if action_count % target_update_frequency == 0 and action_count != previous_action_count_target:
			print("training target")
			target_network.assign(q_network)
			previous_action_count_target = action_count
	else:
		previous_state = get_state()
		previous_distance = (agent_position - coin_position).length()
		
	if step_count % frames_per_action == 0 or previous_action == 2 or previous_action == null:
		action = choose_action(previous_state)
		action_count += 1
		previous_action = action
	execute_action(previous_action, delta)

func is_done() -> bool:
	return time_since_last_coin_collection >= TIME_LIMIT

func stop_training():
	replay_buffer.clear()
	velocity = Vector2.ZERO
	current_jumps = 0
	time_since_last_coin_collection = 0.0
	previous_state = null
	previous_action = null
	print("Training has been stopped and memory cleared.")

func reset_agent():
	position = initial_position
	velocity = Vector2.ZERO
	current_jumps = 0
	time_since_last_coin_collection = 0.0
	previous_state = null
	previous_action = null
	print("Episode done. Resetting agent.")

func reset_collectables():
	var temp_score = level.get_ui_score() * -1
	level.update_ui_score(temp_score)
	for collectable in collectables:
		collectable.reset_position()
	collected_count = 0

# --------------------------------------------------------------------------------
# (2) UPDATED STATE: Include coin distance, velocity, jump status, vision, and floor flag.
# --------------------------------------------------------------------------------
func get_state() -> Array:
	var distance_to_coin = coin_position - agent_position
	update_vision()
	# Normalize values to keep scales similar.
	return [
		distance_to_coin.x / 100,
		distance_to_coin.y / 100,
		velocity.x / speed,
		velocity.y / abs(jump_velocity),
		vision.get("RayCast_Up", 1000) / 100,
		vision.get("RayCast_UpRight", 1000) / 100,
		vision.get("RayCast_Right", 1000) / 100,
		vision.get("RayCast_DownRight", 1000) / 100,
		vision.get("RayCast_Down", 1000) / 100,
		vision.get("RayCast_DownLeft", 1000) / 100,
		vision.get("RayCast_Left", 1000) / 100,
		vision.get("RayCast_UpLeft", 1000) / 100,
		int(is_on_floor())
	]

func execute_action(action: int, delta: float) -> void:
	if is_on_floor():
		current_jumps = 0
	velocity.x = move_toward(velocity.x, 0, speed * delta)
	match action:
		0: velocity.x = speed      # Move right
		1: velocity.x = -speed     # Move left
		2: jump_if_possible()      # Jump
	move_and_slide()

func jump_if_possible():
	if current_jumps < jump_count:
		velocity.y = jump_velocity
		current_jumps += 1

func update_vision():
	for child in get_children():
		if child is RayCast2D:
			if child.is_colliding():
				var collision_point = (child.get_collision_point() - global_position).length()
				vision[child.name] = collision_point
			else:
				vision[child.name] = 1000

# --------------------------------------------------------------------------------
# (3) UPDATED REWARD: Cleaned up (removed print calls) and tuned coefficients.
# --------------------------------------------------------------------------------
func get_reward(current_distance, action) -> float:
	var reward = 0.0
	
	if just_collected_coin:
		time_since_last_coin_collection = 0.0
		coin_position = get_closest_coin()
		previous_distance = (agent_position - coin_position).length()
		just_collected_coin = false
		return 200
	
	## Step penalty to encourage efficiency
	reward -= 0.05
	
	## Reward for moving closer, penalty for moving away
	var dist_improvement = previous_distance - current_distance
	reward += dist_improvement * 0.05
	
	 ## Reward for double jumping
	if action == 2 and current_jumps == 1:
		reward += 1.0  # Reward for double jumping
	
	if vision["RayCast_Up"] < 68 and action==2:
		reward -= 0.1
	
	## Small time penalty to discourage dithering
	reward -= (time_since_last_coin_collection * 0.005)
	#print(time_since_last_coin_collection * 0.01)
	#print(reward)
	
	# 6) Heavier wall penalty so it doesn't hug walls
	for dir in ["Right", "Left"]:

		if vision.has("RayCast_"+dir) and vision["RayCast_"+dir] < 0.4:
			# Penalty for hugging a wall
			reward -= 0.3

			# Even bigger penalty if actually pressing into it
			if (dir == "Right" and action == 0) or (dir == "Left" and action == 1):
				reward -= 5.0
	
	return reward

# --------------------------------------------------------------------------------
# (4) get_closest_coin() – Only consider coins within jump range first.
# --------------------------------------------------------------------------------
func get_closest_coin() -> Vector2:
	var reachable_coin = null
	var fallback_coin = null
	var min_reachable_distance = INF
	var min_distance = INF
	
	# Here we use a fixed max jump height (adjust if you compute dynamically)
	var max_jump_height = 150
	
	for child in level.get_children():
		if child.name.begins_with("collectible") and child.is_active:
			var test_pos = child.global_position
			var distance = (test_pos - agent_position).length()
			if distance < min_distance:
				min_distance = distance
				fallback_coin = child
			if test_pos.y < agent_position.y:
				if (agent_position.y - test_pos.y) > max_jump_height:
					continue
			if distance < min_reachable_distance:
				min_reachable_distance = distance
				reachable_coin = child
	
	if reachable_coin:
		return reachable_coin.global_position
	elif fallback_coin:
		return fallback_coin.global_position
	else:
		return agent_position 

func choose_action(current_state):
	var action = 0
	if randf() < epsilon:
		action = randi() % 3
	else:
		q_network.set_input(current_state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		if q_values.size() > 0 and q_values != null:
			var max_q_value = q_values.max()
			var best_actions = []
			for i in range(q_values.size()):
				if q_values[i] == max_q_value:
					best_actions.append(i)
			if best_actions.size() > 0:
				action = best_actions[randi() % best_actions.size()]
			else:
				action = randi() % 3
		else:
			action = randi() % 3
	return action

func store_experience(state, action, reward, next_state, done):
	if replay_buffer.size() >= max_buffer_size:
		replay_buffer.pop_front()
	replay_buffer.append([state, action, reward, next_state, done])

func sample_batch():
	var batch = []
	for i in range(batch_size):
		var idx = randi() % replay_buffer.size()
		batch.append(replay_buffer[idx])
	return batch

# --------------------------------------------------------------------------------
# (5) Training: Double DQN update with target network.
# --------------------------------------------------------------------------------
func train_dqn() -> void:
	var batch = sample_batch()
	var batch_states = []
	var batch_targets = []
	
	for experience in batch:
		var state     = experience[0]
		var action    = experience[1]
		var reward    = experience[2]
		var next_state= experience[3]
		var done      = experience[4]
		
		q_network.set_input(state)
		q_network.propagate_forward()
		var q_values = q_network.get_output()
		
		q_network.set_input(next_state)
		q_network.propagate_forward()
		var next_q_online = q_network.get_output()
		
		var best_next_action = 0
		var max_val = -INF
		for i in range(next_q_online.size()):
			if next_q_online[i] > max_val:
				max_val = next_q_online[i]
				best_next_action = i
		
		target_network.set_input(next_state)
		target_network.propagate_forward()
		var target_output = target_network.get_output()
		var double_q_value = target_output[best_next_action]
		
		var target_q_value = reward
		if not done:
			target_q_value += gamma * double_q_value
		
		var target_q_values = q_values.duplicate()
		target_q_values[action] = target_q_value
		
		batch_states.append(state)
		batch_targets.append(target_q_values)
	
	q_network.train(batch_states, batch_targets)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * gravity_multiplier * delta 

func _on_area_2d_body_entered(body):
	if body.is_in_group("collectable") and body.is_active:
		collected_count += 1
		var coin_value = body.value
		level.update_ui_score(coin_value)
		body.collect()
		just_collected_coin = true

# --------------------------------------------------------------------------------
# Save / Load agent functions (unchanged except for minor logging improvements)
# --------------------------------------------------------------------------------
func save_agent():
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"
	var weights_file = FileAccess.open(weights_path, FileAccess.WRITE)
	if weights_file == null:
		push_error("Failed to open weights file for writing: " + weights_path)
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
		push_error("Failed to open agent data file for writing: " + agent_data_path)
	else:
		agent_file.store_var(agent_data)
		agent_file.close()
		print("Agent parameters saved to ", agent_data_path)

func load_agent():
	print("Agent states reset after loading.")
	var weights_path = "user://q_network_weights.dat"
	var agent_data_path = "user://agent_data.save"
	if not FileAccess.file_exists(weights_path):
		push_error("Weights file does not exist: " + weights_path)
	else:
		q_network.load_data(weights_path)
		print("Q-network weights loaded from ", weights_path)
		target_network.assign(q_network)
		print("Target network synchronized with Q-network.")
	
	if not FileAccess.file_exists(agent_data_path):
		push_error("Agent data file does not exist: " + agent_data_path)
	else:
		var agent_file = FileAccess.open(agent_data_path, FileAccess.READ)
		if agent_file == null:
			push_error("Failed to open agent data file for reading: " + agent_data_path)
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
			# Set epsilon low to favor exploitation post-loading.
			epsilon = 0.1
			print("Epsilon set to ", epsilon, " for exploitation.")

func append_episode_reward(episode_number, ep_reward, num_collected, epsilon, ep_time):
	if not FileAccess.file_exists(rewards_file_path):
		var file = FileAccess.open(rewards_file_path, FileAccess.WRITE)
		if file:
			file.store_line("Episode,Reward,num_collected,epsilon,episode_time")
			file.close()
	
	var file = FileAccess.open(rewards_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(str(episode_number) + "," + str(ep_reward) + "," + str(num_collected) + "," + str(epsilon) + "," + str(ep_time))
		file.close()
