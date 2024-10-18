extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	print("we are in the function agent ")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_go_button_pressed():
	Global.function_agent_boolean = true 
	get_tree().change_scene_to_file("res://common/play_game_parameters.tscn")


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
