# player_factory.gd
extends Node

# Export variables to assign player scenes in the editor
@export var human_player_scene: PackedScene
@export var dqn_agent_scene: PackedScene

# Function to create a player based on the control type
func create_player() -> Node2D:
	if Globals.control_type == "human":
		if human_player_scene:
			return human_player_scene.instantiate()
		else:
			print("Human player scene not assigned in the factory.")
	elif Globals.control_type == "train":
		if dqn_agent_scene:
			return dqn_agent_scene.instantiate()
		else:
			print("DQN agent scene not assigned in the factory.")
	
	# Fallback: Return null if no valid player type is found
	return null
