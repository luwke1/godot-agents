extends CharacterBody2D

# variables for the Human version of hte player
@export var speed = 400.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_muultiplier = 2.0
@export var currentLevel:Node2D
var gameOver = false

var current_jumps = 0

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# variables for the Function version of the player
@onready var my_timer = $player_timer
@onready var agent_episode_timer = $agent_timer

var function_jump = 4			#time before first jump, and between jumps, must be over 3.5
var function_speed = 100		# if the function_jump time goes up, this number goes down. 
var function_cycle_wait_time = 6 
var my_counter = 3

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# variables for the Agent version of the player

var move_distance = 5000
var step_number = 0
# Q-table loaded from training
var q_table: Array = []
# Current state of the player
var current_state: int = 1

var action_in_progress: bool = false
var best_action_index = 1

# State transition table
		# Actions: 0 = move left, 1 = jump left, 2 = move right, 3 = jump right
var state_transitions = {
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
	12: [0, 0, 0, 0],
	13: [1, 1, 14, 14],
	14: [13, 13, 15, 15],
	15: [14, 14, 5, 16],
	16: [15, 15, 17, 17],
	17: [16, 16, 18, 18],
	18: [17, 17, 19, 19],
	19: [7, 18, 20, 20],
	20: [19, 19, 21, 21],
	21: [20, 20, 11, 11],
} 				# Actions: 0 = move left, 1 = jump left, 2 = move right, 3 = jump right

var optimal_action_path: Array = []		# built from the Q-table resulting from training
# Trained Agent file path
var file_path = "user://q_table.json"
var trained_agent_action_list: Array = []
var trained_state_optimal_state_list: Array = []
var start_state = 1
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# variables for all versions of hte player
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	my_timer.wait_time = function_cycle_wait_time		## pause time between jumps 
	q_table = load_q_table(file_path)
	if Globals.control_type == "agent":
		agent_episode_timer.start(45)
		step_number = 1
		trained_agent_action_list.resize(11)
		trained_agent_action_list.fill(0)
		trained_state_optimal_state_list.resize(11)
		trained_state_optimal_state_list.fill(-1)
		#trained_agent_action_list = [3,2,2,3,2,2,2]		#uncomment this line and comment the next line to run the "idea optimized action set"
		build_trained_agent_optimized_action_list()			#comment out this line and uncomment the line above to see the ideal run
			
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Support for Agent in Ready function
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
func build_trained_agent_optimized_action_list():
	for index in range(trained_agent_action_list.size()):
		if index == 0:
			var this_state_action = get_best_action(start_state)
			var next_state = get_next_state(start_state, this_state_action)
			trained_agent_action_list[0] = this_state_action
			trained_state_optimal_state_list[0] = next_state
		else:
			var this_state = trained_state_optimal_state_list[index-1]
			var this_state_action = get_best_action(this_state)
			var next_state = get_next_state(this_state, this_state_action)
			trained_agent_action_list[index] = this_state_action
			trained_state_optimal_state_list[index] = next_state
	print("trained_agent_action_list = ", trained_agent_action_list)
	print("trained_state_optimal_state_list = ", trained_state_optimal_state_list)
	
func get_next_state(state, step):
	var this_step = get_best_action(state)
	var next_state = state_transitions[state][this_step]
	return next_state
	
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

func _physics_process(delta):
	apply_gravity(delta)

	if Globals.control_type == "human" and not gameOver:
		handle_jump()
		handle_movement()
		
	elif Globals.control_type == "function":

		if my_timer.time_left <= function_jump and my_timer.time_left >= function_jump-.05 :
			velocity.y = jump_velocity *1.5
			
		if my_timer.time_left <= function_jump-.05  and my_timer.time_left >= function_jump-2 :
			velocity.x = function_speed
			
		if my_timer.time_left <= function_jump-3.5:
			velocity.x = 0
		move_and_slide()
	
	elif Globals.control_type == "agent":
		if q_table.size() == 0:
			return  # Q-table not loaded yet
		apply_gravity(delta)
		move_and_slide()
		if not action_in_progress:
			action_in_progress = true

		if action_in_progress:
			
			if agent_episode_timer.time_left >= 40:
				execute_action(trained_agent_action_list[0])
			elif agent_episode_timer.time_left < 40 and agent_episode_timer.time_left >= 35:
				execute_action(trained_agent_action_list[1])
			elif agent_episode_timer.time_left < 35 and agent_episode_timer.time_left >= 30:
				execute_action(trained_agent_action_list[2])
			elif agent_episode_timer.time_left < 30 and agent_episode_timer.time_left >= 25:
				execute_action(trained_agent_action_list[3])
			elif agent_episode_timer.time_left < 25 and agent_episode_timer.time_left >= 20:
				execute_action(trained_agent_action_list[4])
			elif agent_episode_timer.time_left < 20 and agent_episode_timer.time_left >= 15:
				execute_action(trained_agent_action_list[5])
			elif agent_episode_timer.time_left < 15 and agent_episode_timer.time_left >= 10:
				execute_action(trained_agent_action_list[6])
			elif agent_episode_timer.time_left < 10 and agent_episode_timer.time_left >= 5:
				execute_action(trained_agent_action_list[7])
			elif agent_episode_timer.time_left < 5 and agent_episode_timer.time_left > 0:
				execute_action(trained_agent_action_list[8])
			else:
				velocity.x = 0
				velocity.y = 0

		
	elif Globals.control_type == "agent_in_training":
		pass # run the training function from the main menu
		# this option is not currrenlty being used. 

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Functions for the Human player
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
func handle_jump():
	if is_on_floor(): current_jumps = 0
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or current_jumps < jump_count:
			velocity.y = jump_velocity
			current_jumps += 1
			
func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		$GFX.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Functions for all players
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

func _on_area_2d_body_entered(body):
	if body.is_in_group("collectable"):
		gameOver = currentLevel.update_ui_score(body.value)
		body.collect()
	if gameOver:
		stop_platforms()
		
func stop_platforms():
	var platforms = get_tree().get_nodes_in_group("platform")
	for platform in platforms:
		platform.set_game_over()
		
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * gravity_muultiplier * delta *1.1
	else:
		velocity.y = 0  # Reset vertical velocity when on the floor
			
			
# ++++++++++++++++++++++++++++++++++++++++++++
# support functions for the Agent player
# ++++++++++++++++++++++++++++++++++++++++++++

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

	
# Action: Move Left
func move_left() -> void:
	#print("move left")
	if my_timer.time_left <= 1 and my_timer.time_left > 0:
		velocity.x = -function_speed*1.1
	else:
		velocity.x = 0
	move_and_slide()
	finalize_action()

# Action: Move Right
func move_right() -> void:
	#print("move right")
	if my_timer.time_left <= 1 and my_timer.time_left > 0:
		velocity.x = function_speed*1.1
	else:
		velocity.x = 0
	move_and_slide()
	finalize_action()

# Action: Jump Left
func jump_left() -> void:
	#print("jump left")
	if my_timer.time_left <= 4 and my_timer.time_left >= 3.7 :
		velocity.y = jump_velocity *1.8
	if my_timer.time_left < 3.7  and my_timer.time_left >= 2.4:
		velocity.x = -function_speed * 0.8
	if my_timer.time_left < 2.4:
		velocity.x = 0
	move_and_slide()
	finalize_action()

# Action: Jump Right
func jump_right() -> void:
	#print("jump right")
	if my_timer.time_left <= 4 and my_timer.time_left >= 3.7 :
		velocity.y = jump_velocity *1.8
	if my_timer.time_left < 3.7  and my_timer.time_left >= 2.4:
		velocity.x = function_speed*.8
	if my_timer.time_left < 2.4:
		velocity.x = 0
	move_and_slide()
	finalize_action()

# Finalize action: reset velocity and update state
func finalize_action() -> void:
	#print("finalize action")
	velocity = Vector2.ZERO
	action_in_progress = false
	update_current_state()
	
# Execute the selected action based on the index
func execute_action(action_index: int) -> void:
	#print("execute action: ", action_index)

	if action_index == 0:
		my_timer.wait_time = 3
		move_left()
	elif action_index == 1:
		my_timer.wait_time = 5
		jump_left()
	elif action_index == 2:
		my_timer.wait_time = 3
		move_right()
	elif action_index == 3:
		my_timer.wait_time = 5
		jump_right()
	else:
		print("yoikes too many errirs")

	
func get_best_action(state: int ) -> int:
	#print("get best action")
	var q_values = q_table[state]
	return q_values.find(q_values.max())
	
func update_current_state():
	# Update the current state (based on the best action
	current_state = state_transitions[current_state][best_action_index]
	#print("Updated state:", current_state)
	#print("Action completed, ready for the next.")
	
