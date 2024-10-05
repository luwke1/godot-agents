extends RigidBody3D

var bombTime = 20

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

var landing_site = Global.landing_site
var launch_site = Global.launch_site
var rocket_position = Global.rocket_position
var rocket_speed = Global.rocket_velocity
var turret_can_fire = Global.turret_fire
var flying = 1.0

var start_time = Time.get_ticks_msec()
var current_time = 0

@onready var twist_pivot := $TwistPvot
@onready var pitch_pivot = $TwistPvot/PitchPivot

@onready var fire = $Fire
@onready var kaboom_1 = $Kaboom1
@onready var smoke = $Smoke



# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Feelers.disabled = true
	Global.flying_boolean = false
	
	if (Global.function_agent_boolean == true):
		print("got to the function agent one ... whoo hoo ")
		function_agent_one()
		#Global.function_agent_boolean == false
	Global.function_agent_boolean = false
	
# note that a similar if statement would go 
#    here for your RML agent, then ... 
#    add your Agent's as a funciton below. 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	check_input()	# checking for rotating the tank turret
	#check_kablooey()

	if Input.is_action_just_pressed("turret_can_fire"):		# the "t" key6
		turret_can_fire = !turret_can_fire
		$Feelers.disabled = !$Feelers.disabled
		Global.flying = !Global.flying


	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# handling parameter labels
	var my_velocity = linear_velocity
	$my_speed.text = str(round(my_velocity))
	rocket_position = position
	
	$my_height.text = str(round(rocket_position))
	
	$my_roll.text = str(round(Global.heading))
	
	$my_bombs.text = str(round(Global.bombs))
	$power_node_location.text = str(round(Global.power_node_position))
	current_time = (Time.get_ticks_msec() - start_time)/1000
	$elapsed_time.text = str(round(current_time))
	print(current_time)
	print(Global.bombs)
		
	# handling tank fwd/back and left/right
	var input = Vector3.ZERO
	input.x = Input.get_axis("roll_left", "roll_right")		#variable names are messed up, l/r & f/b
	input.z = Input.get_axis("pitch_down", "pitch_up")
	apply_central_force(basis* input*1000.0 * flying * delta)
	
	# handling camera pitch and roll
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x, -0.5, 0.9 )
	twist_input = 0.0
	pitch_input = 0.0

func explode():
	fire.emitting = true
	$Fire3.emitting = true
	kaboom_1.play(true)
	smoke.emitting = true
	Global.bombs -=  1
	#if (Global.bombs <= 0):
		#kablooey()
	return true
	
func kablooey():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://common/crashed.tscn")

# handling movemenet of mouse camera 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity 

func check_input():
	if Input.is_action_pressed("ui_left"):
		$turret.rotate_y(deg_to_rad(.3))
		Global.heading = $turret.get_rotation_degrees().y
	elif Input.is_action_pressed("ui_right"):
		$turret.rotate_y(deg_to_rad(-.3))
		Global.heading = $turret.get_rotation_degrees().y

func check_kablooey():
	if (position.y < 2 && explode()):
		kablooey()

func send_action():
	var send_event = InputEventAction.new()
	send_event.action = "pitch_down"
	send_event.pressed = true
	Input.parse_input_event(send_event)
	send_event = false

func function_agent_one(): 
	await get_tree().create_timer(3.0).timeout
	
# functino agent one movement
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
	while(abs(rocket_position.x) > .5 || abs(rocket_position.z) > .5):
		if  (0 <= rocket_position.z ):
			apply_central_force(Vector3.FORWARD * 200 )
			await get_tree().create_timer(0.1).timeout
		if  (0 <= rocket_position.x ):
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
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://common/snake_debrief.tscn")
