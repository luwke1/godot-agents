extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.team_agent_boolean = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	

	if Input.is_key_pressed(KEY_P):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")


func _on_button_pressed():
	print("we are at the Team Agent - yaayyy")
	Global.team_agent_boolean = true 
	get_tree().change_scene_to_file("res://common/play_game_parameters.tscn")


func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
