extends AIController3D

# meta-name: AI Controller Logic
# meta-description: Methods that need implementing for AI controllers
# meta-default: true
#-- Methods that need implementing using the "extend script" option in Godot --#

var move = Vector2.ZERO
#@onready var rocket = $rocket
#@onready var power_node = $powerNode

func get_obs() -> Dictionary:
	var obs := [
		Global.rocket_position.x,
		Global.rocket_position.z,
		Global.power_node_position.x,
		Global.power_node_position.z
	]
	return {"obs":[]}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"move" : {
			"size": 2,
			"action_type": "continuous"
		},
	}
	
func set_action(action) -> void:	
	move.x = action["move"][0]
	move.y = action["move"][1]
# -----------------------------------------------------------------------------#

#-- Methods that can be overridden if needed --#

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
#	var obs = get_obs()
#	return {
#		"obs": {
#			"size": [len(obs["obs"])],
#			"space": "box"
#		},
#	}
