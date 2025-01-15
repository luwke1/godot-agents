extends RigidBody3D

var bombTime = 20

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0


var launch_site = Global.launch_site
var rocket_position = Global.rocket_position
var rocket_speed = Global.rocket_velocity

var start_time = Time.get_ticks_msec()
var current_time = 0

@onready var twist_pivot := $TwistPvot
@onready var pitch_pivot = $TwistPvot/PitchPivot
@onready var ai_controller_3d: Node3D = $AIController3D

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	rocket_position = Vector3(0,1,0)
	#
	#
	if (Global.function_agent_boolean == true):
		print("function agent boolean START = " , Global.function_agent_boolean)
		print("got to the function agent one ... whoo hoo ")
		function_agent_one()
		Global.function_agent_boolean = false

	
	if (Global.team_agent_boolean == true):
		print("made it to the team-learning agent ... hooray")
		team_agent_one()
		Global.team_agent_boolean = false
		
	# note that the "else" not here is running the human player here in the process function
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# handling parameter labels
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity))
	rocket_position = position
	$my_height.text = str(round(rocket_position))
	$my_bombs.text = str(round(Global.bombs))
	$power_node_location.text = str(round(Global.power_node_position))
	current_time = (Time.get_ticks_msec() - start_time)/1000
	$elapsed_time.text = str(round(current_time))
	
# handling tank fwd/back and left/right for human agent
	var input = Vector3.ZERO
	input.x = Input.get_axis("roll_left", "roll_right")  #variable names are messed up, l/r & f/b
	input.z = Input.get_axis("pitch_down", "pitch_up")
	
# handling tank movement by the AI controller	
	var OLD_diff_position = rocket_position.distance_to(Global.power_node_position)
	print("old diff position", OLD_diff_position)
	
	input.x = ai_controller_3d.move.x
	input.z = ai_controller_3d.move.y
	
	apply_central_force(basis* input*1000.0  * delta)
	
	var diff_position = rocket_position.distance_to(Global.power_node_position)
	
	if OLD_diff_position <= diff_position :
		ai_controller_3d.reward -= 1.0
	else : 
		ai_controller_3d.reward += 1.0
		
	print("new diff position", diff_position)
	# handling camera pitch and roll for player and all agents
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x, -0.5, 0.9 )
	twist_input = 0.0
	pitch_input = 0.0
	
	# check to exit human player when have collected 9 power daiseys. 
	if (Global.bombs >= 120 && Global.human_player_boolean && abs(rocket_position.x) < .5 && abs(rocket_position.z) < .5):
		# send control to the debrief page
		rocket_speed = Vector3.ZERO
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://agents/human_player/snake_human_debrief.tscn")

# handling movemenet of mouse camera 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity 


##################################################################
#  Snake human player specific code
##################################################################
## not needed, human is in process delta

##################################################################
#  Snake Function Agent code
# this Agent is not complete, it works, but it is missing a PID compnent
# it also seems to get stuck once in awhile, and you have to rescue it using the keybaord. 
#
func function_agent_one(): 
	await get_tree().create_timer(2.0).timeout
	
# function agent one movement
# collect pwoer daiseys
	while(Global.bombs <120):
		
		if  (Global.power_node_position.z <= rocket_position.z ):
			apply_central_force(Vector3.FORWARD * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (Global.power_node_position.x <= rocket_position.x ):
			apply_central_force(Vector3.LEFT * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (Global.power_node_position.z > rocket_position.z ):
			apply_central_force(Vector3.BACK * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (Global.power_node_position.x > rocket_position.x ):
			apply_central_force(Vector3.RIGHT * 200 )
			await get_tree().create_timer(0.1).timeout
# move back to the starting pad
	while(abs(rocket_position.x) > 0.01 && abs(rocket_position.z) > 0.01):
		if  (0 < rocket_position.z ):
			apply_central_force(Vector3.FORWARD * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (0 < rocket_position.x ):
			apply_central_force(Vector3.LEFT * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (0 > rocket_position.z ):
			apply_central_force(Vector3.BACK * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (0 > rocket_position.x ):
			apply_central_force(Vector3.RIGHT * 200 )
			await get_tree().create_timer(0.1).timeout
# send control to the debrief page
	rocket_speed = Vector3.ZERO
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://agents/function_agent/function_agent_end.tscn")
##################################################################



##################################################################
# Team Open Agent code
##################################################################
func team_agent_one():
	pass
	
	
##################################################################
