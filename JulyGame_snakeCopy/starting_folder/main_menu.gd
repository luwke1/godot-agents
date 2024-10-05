extends Control

func _ready():
	#print(Global.heading)
	#print(Global.waitTime)
	#print(Global.bombChoice)
	print("hello from teh main menu")
	Global.function_agent_boolean = false


func _on_quit_pressed():
	get_tree().quit()

func _on_play_menu_pressed():
	get_tree().change_scene_to_file("res://common/play_game_parameters.tscn")

func _on_help_pressed():
	get_tree().change_scene_to_file("res://starting_folder/help.tscn")

func _on_run_function_agent_pressed():
	get_tree().change_scene_to_file("res://agents/function_agent.tscn")


func _on_run_agent_pressed():
	get_tree().change_scene_to_file("res://agents/team_agent/RML_agent_run.tscn")
