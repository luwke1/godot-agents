extends Node

var heading = 0
var bombChoice = 1
var waitTime = 3
var planet = "earth"
var gravityPlanet = 9.8
var breezeSpeed = 5
var breezeDirection = 270
var mountainHeight = 100
var landing_site = Vector3(40,1,70)
var launch_site = Vector3.ZERO
var rocket_position = Vector3.ZERO
var rocket_velocity = Vector3.ZERO
var rocketMass = 22000
var loadMass = 1000 
var altitude = 1
var speed = 0
var bombs = 60
var turret_fire = false
var flying_boolean = false
var power_node_position = Vector3(6,2,7)
var power_node_gen = true
var time_since_start = 0
var function_agent_boolean = false
