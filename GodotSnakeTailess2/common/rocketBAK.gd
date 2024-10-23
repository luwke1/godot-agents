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
var q_network : NNET = NNET.new([6, 64, 4], false) # State size is 6 (position and velocity), hidden size is 128, action size is 4
var target_network : NNET = NNET.new([6, 64, 4], false) # Target network for stability

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
    q_network.use_Adam(0.0005)
    
    target_network.set_loss_function(BNNET.LossFunctions.MSE)
    target_network.use_Adam(0.0005)
    
    # Initialize q_network with random weights
    q_network.reinit()
    
    # Initialize target_network as a copy of q_network
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
    
    # DQN Agent decision-making and learning loop
    var action = 0
    if randf() < epsilon:
        # Explore: choose a random action
        action = randi() % 4  # Assuming 4 possible actions
    else:
        # Exploit: choose the best action based on the Q-network
        q_network.set_input(state)
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
            else:
                action = randi() % 4
        else:
            action = randi() % 4

    # Execute the action
    execute_action(action)
    
    # Calculate reward
    var reward = get_reward()
    #print("Reward: ", reward, " -- Action: ", action)
    print(daisey_position)
    var next_state = get_state()
    var done = is_done()
    
    # Store experience in the replay buffer
    if replay_buffer.size() >= max_buffer_size:
        replay_buffer.pop_front()
    replay_buffer.append([state, action, reward, next_state, done])
    
    # Train the Q-network if enough experiences are available
    if replay_buffer.size() >= batch_size:
        train_dqn()
    
    # Update epsilon to reduce exploration over time
    epsilon = max(0.1, epsilon * 0.995)
    
    # Update the target network periodically
    step_count += 1
    if step_count % target_update_frequency == 0:
        target_network.assign(q_network)
    
    # Update the state for the next iteration
    state = next_state
    
    # Update previous_distance after the action and physics update
    previous_distance = (rocket_position - daisey_position).length()

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
        0:
            apply_central_force(Vector3(1, 0, 0) * 25)
        1:
            apply_central_force(Vector3(-1, 0, 0) * 25)
        2:
            apply_central_force(Vector3(0, 0, 1) * 25)
        3:
            apply_central_force(Vector3(0, 0, -1) * 25)

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
    
    # Debugging statements
    #print("Previous Distance: ", previous_distance)
    #print("Current Distance: ", distance_to_daisey)
    #print("Distance Change: ", distance_change)
    
    # Initialize reward
    var reward = 0.0
    
    # Reward for moving closer to the daisy
    if distance_change > 0:
        reward += distance_change * 20.0  # Positive reward proportional to closeness
    
    # Penalty for moving away from the daisy
    elif distance_change < 0:
        reward += distance_change * 80.0  # Negative reward proportional to distance increase
    
    # Time-Based Penalty
    #var time_penalty = (current_time / max_time) * 5.0  # Scaling factor can be adjusted
    #reward -= time_penalty
    
    # Additional Step Penalty to discourage unnecessary movements
    reward -= 0.5  # Fixed small penalty per step
    
    return reward

func is_done() -> bool:
    return Global.bombs >= 120

func train_dqn() -> void:
    if replay_buffer.size() < batch_size:
        return  # Not enough experiences to train
    
    # Randomly sample a batch from the replay buffer
    var batch = []
    for i in range(batch_size):
        batch.append(replay_buffer[randi() % replay_buffer.size()])
    
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
        
        # Duplicate the Q-values to compute the target
        var target_q_values = q_values.duplicate()
        
        # Forward propagate through the target network for the next state
        target_network.set_input(next_state)
        target_network.propagate_forward()
        var target_output = target_network.get_output()
        
        # Get the maximum Q-value for the next state
        var max_next_q = target_output.max() if target_output.size() > 0 else 0
        
        # Bellman equation: Q(s, a) = reward + gamma * max(Q(s', a'))
        if done:
            target_q_values[action] = reward  # No future rewards if episode is done
        else:
            target_q_values[action] = reward + gamma * max_next_q  # Include discounted future reward
        
        # Append the state and the updated target Q-values to the batch
        batch_states.append(state)
        batch_targets.append(target_q_values)
    
    # Train the Q-network on the entire batch
    q_network.train(batch_states, batch_targets)
