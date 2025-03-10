extends Node

# Define the Environment
const STATES = 22  			# in a rough 3x13 grid, with several that cannot be moved into
const ACTIONS = 4  			# Actions: 0 = move left, 1 = jump left, 2 = move right, 3 = jump right
var rewards = []			# easiest way to track the rewards, and to change them as achieved
var state_transitions = {}	# a real bonus for this method, we can really control the transitions
var visited_states = []  	# Track visited states
var q_table = []			# this is THE Q-table, it will become the basis of our policy function

# Set Hyperparameters, modify these to learn how they work
const ALPHA = 0.1  			# Learning rate
const GAMMA = 0.9  			# Discount factor
var epsilon = 0.98  		# Initial exploration rate (chance of random action)
const DECAY = 0.99  		# Exploration decay rate
const EPISODES = 10000  		# Number of training episodes

func _ready():
	print("starting")
	initialize_environment()
	print("environment initialized")
	train_q_learning()
	print("training completed")
	output_q_table()			# this also saves the q_table to a file for further use

	# Example Usage: Predict the Best Action for a given State, Comment-out after debugging complete
	var best_action = predict_best_action(1)
	for i in range(STATES):
		best_action = predict_best_action(i)
		print("best action for state ", i, " is ", best_action)
	

func initialize_environment():
	# Initialize rewards
	rewards.resize(STATES)
	for i in range(STATES):
		rewards[i] = 0
	rewards[14] = 30  # Goal state
	rewards[17] = 60  # Goal state
	rewards[21] = 90  # Goal state
	rewards[0] = -20  # Trap state
	rewards[12] = -20  # Trap state

	# Initialize state transitions # Actions: 0 = move left, 1 = jump left, 2 = move right, 3 = jump right
	state_transitions = {
		0: [0, 0, 0, 0],
		1: [0, 0, 2, 13],
		2: [1, 1, 3, 3],
		3: [2, 2, 4, 4],
		4: [3, 3, 5, 5],
		5: [4, 15, 6, 6],
		6: [5, 5, 7, 7],
		7: [6, 6, 8, 19],
		8: [7, 7, 9, 9],
		9: [8, 8, 10, 10],
		10: [9, 9, 11, 11],
		11: [10, 21, 12, 12],
		12: [12, 12, 12, 12],
		13: [1, 1, 14, 14],
		14: [13, 13, 15, 15],
		15: [14, 14, 5, 16],
		16: [15, 15, 17, 17],
		17: [16, 16, 18, 18],
		18: [17, 17, 19, 19],
		19: [7, 18, 20, 20],
		20: [19, 19, 21, 21],
		21: [20, 20, 11, 11],
	}							# Actions: 0 = move left, 1 = jump left, 2 = move right, 3 = jump right

	# Initialize Q-table
	q_table.resize(STATES)
	for i in range(STATES):
		q_table[i] = [0.0, 0.0, 0.0, 0.0]  # Initialize each state with zeros


func train_q_learning():
	for episode in range(EPISODES):
		initialize_visited_states()
		var state = 1  #Start from  state 1
		var done = false
		var action_count = 0  # Track the number of actions in the current episode
		var episode_reward = 0
		var last_state = -1  # Track the last state to detect reversals

		while not done:
			# Choose action using epsilon-greedy policy
			var action = 0
			if randf() < epsilon:
				action = randi() % ACTIONS  # Explore: Random action
			else:
				action = find_max_index(q_table[state])  # Exploit: Best known action

			# Perform the action and get the next state and reward
			var next_state = state_transitions[state][action]
			var reward = rewards[next_state]

			# If the state has been visited, set reward to 0
			if visited_states[next_state]:
				reward -= 1
			else:
				visited_states[next_state] = true
				reward += 4
			# add a negative reward for each action_count
			#reward -= 1
			
			if next_state == last_state:	# if last_state != -1 and state == last_state-1:
				reward -= 20  # Penalize reversals more heavily
			last_state = next_state
		
			# Check if the episode ends (goal reached or wwent off the ends) ... still not quite right
			if state == 0 or state == 12:
				done = true
			if action_count >= 12:
				reward -= 1
				done = true
				
			if visited_states[14] == true and visited_states[17] == true and visited_states[20] == true :
				reward += 100

			# Update Q-value using Bellman's equation
			q_table[state][action] += ALPHA * (
				reward + GAMMA * find_max_value(q_table[next_state]) - q_table[state][action]
			)
			
			# Move to the next state
			state = next_state

			# Increment action count
			action_count += 1

		# Decay epsilon to reduce exploration over time
		epsilon = max(0.1, epsilon * DECAY)  # Ensure exploration doesn't drop too low #epsilon *= DECAY

func output_q_table():						# Comment-out after debugging
	# Example file path
	var file_path = "user://q_table.json"
	# Save the Q-table
	save_q_table(file_path, q_table)
	print("Learned Q-Table:")
	for state in range(STATES):
		print("State", state, ":", q_table[state])
	
func predict_best_action(state):
	return find_max_index(q_table[state])

func find_max_index(array):
	var max_value = array[0]
	var max_index = 0
	for i in range(array.size()):
		if array[i] > max_value:
			max_value = array[i]
			max_index = i
	return max_index

func find_max_value(array):
	return array.reduce(max)

func save_q_table(file_path: String, q_table: Array) -> void:
	var json = JSON.new()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var serialized_data = json.stringify(q_table)
		file.store_line(serialized_data)
		file.close()
		print("Q-table saved to %s" % file_path)
	else:
		print("Failed to open file for writing.")


func load_q_table(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var data = file.get_line()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(data)
		if parse_result == OK:
			return json.data
		else:
			print("Failed to parse JSON.")
			return []
	else:
		print("Failed to open file for reading.")
		return []


func _on_return_pressed():
	get_tree().change_scene_to_file("res://intro.tscn")


func _on_run_the_agent_pressed():
	Globals.control_type = "agent"
	get_tree().change_scene_to_file("res://main_game.tscn")

func initialize_visited_states():
	#visited_states = []
	visited_states.resize(STATES)
	for i in range(STATES):
		visited_states[i] = false
