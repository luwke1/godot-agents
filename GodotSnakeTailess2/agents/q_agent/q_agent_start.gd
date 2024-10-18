extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_P):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")


func _on_button_start_agent_pressed():
	Global.q_agent_boolean = true 
	print("q-agent boolean from START is ", Global.q_agent_boolean)
	print("we are at the Q-learning agent ... wonderful")
	get_tree().change_scene_to_file("res://common/play_game_parameters.tscn")
	#Global.q_agent_boolean = false 


func _on_button_pressed():
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
