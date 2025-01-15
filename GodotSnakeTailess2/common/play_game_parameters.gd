extends Node3D

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot = $TwistPivot/PitchPivot 


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Hello from the playing screen")
	print("human player boolean = ", Global.human_player_boolean)
	print("q-Agent boolean = ", Global.q_agent_boolean)
	print("function Agnet boolean = ", Global.function_agent_boolean) 
	print("team Agent boolean = ", Global.team_agent_boolean)

	Global.bombs = 30
	$powerNode.position = Vector3(6,2,7)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_key_pressed(KEY_P):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
		


