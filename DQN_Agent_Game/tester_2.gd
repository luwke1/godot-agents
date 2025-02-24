extends Node

# Step 1: Define the Environment
const STATES = 16  # 4x4 grid with 16 states
const ACTIONS = 4  # Actions: 0 = Left, 1 = Down, 2 = Right, 3 = Up

# Rewards: +10 for reaching the goal (state 15), -10 for falling into a trap (state 5)
var rewards = []
var state_transitions = {}

# Step 2: Set Hyperparameters
const ALPHA = 0.1  # Learning rate
const GAMMA = 0.9  # Discount factor
var epsilon = 0.9  # Initial exploration rate (chance of random action)
const DECAY = 0.999  # Exploration decay rate
const EPISODES = 1000  # Number of training episodes

# Step 3: Initialize Q-Table
var q_table = []

func _ready():
	initialize_environment()
	train_q_learning()
	output_q_table()

	# Example Usage: Predict the Best Action for State 0
	var best_action = predict_best_action(0)
	print("Best action for state 0:", best_action)

func initialize_environment():
	# Initialize rewards
	rewards.resize(STATES)
	for i in range(STATES):
		rewards[i] = 0
	rewards[15] = 10  # Goal state
	rewards[5] = -10  # Trap state

	# Initialize state transitions
	state_transitions = {
		0: [0, 4, 1, 0],
		1: [0, 5, 2, 1],
		2: [1, 6, 3, 2],
		3: [2, 7, 3, 3],
		4: [0, 8, 5, 0],
		5: [1, 9, 6, 4],
		6: [2, 10, 7, 5],
		7: [3, 11, 7, 6],
		8: [4, 12, 9, 8],
		9: [5, 13, 10, 8],
		10: [6, 14, 11, 9],
		11: [7, 15, 11, 10],
		12: [8, 12, 13, 12],
		13: [9, 13, 14, 12],
		14: [10, 14, 15, 13],
		15: [15, 15, 15, 15],
	}

	# Initialize Q-table
	q_table.resize(STATES)
	for i in range(STATES):
		q_table[i] = [0.0, 0.0, 0.0, 0.0]  # Initialize each state with zeros

func train_q_learning():
	for episode in range(EPISODES):
		var state = randi() % STATES  # Start from a random state
		var done = false

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

			# Update Q-value using Bellman's equation
			q_table[state][action] += ALPHA * (
				reward + GAMMA * find_max_value(q_table[next_state]) - q_table[state][action]
			)

			# Move to the next state
			state = next_state

			# Check if the episode ends (goal or trap reached)
			if state == 15 or state == 5:
				done = true

		# Decay epsilon to reduce exploration over time
		epsilon *= DECAY

func output_q_table():
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
