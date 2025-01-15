extends Node

var heading = 0
var waitTime = 3

var launch_site = Vector3.ZERO
var rocket_position = Vector3.ZERO
var rocket_velocity = Vector3.ZERO

var speed = 0
var bombs = 60

var power_node_position = Vector3(6,2,7)
var power_node_gen = true
var time_since_start = 0

var function_agent_boolean = false
var q_agent_boolean = false
var team_agent_boolean = false
var human_player_boolean = false

var episode_score = 0
