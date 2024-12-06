extends Control

func _ready():
	#print(Global.heading)
	#print(Global.waitTime)
	#print(Global.bombChoice)
	print("hello from teh main menu")
	Global.function_agent_boolean = false
	Global.human_player_boolean = false
	Global.q_agent_boolean = false
	Global.team_agent_boolean = false


func _on_quit_pressed():
	get_tree().quit()

func _on_play_menu_pressed():
	Global.human_player_boolean = true
	get_tree().change_scene_to_file("res://agents/human_player/snake_human_start.tscn")
	# note that this button is for the human player

func _on_help_pressed():
	get_tree().change_scene_to_file("res://starting_folder/help.tscn")

func _on_run_function_agent_pressed():
	Global.function_agent_boolean = true
	get_tree().change_scene_to_file("res://agents/function_agent/function_agent_start.tscn")


func _on_run_agent_pressed():	# NOT USED
	get_tree().change_scene_to_file("res://agents/team_agent/team_agent_start.tscn")
	# note that this button is for the teams own Agent - aka the Open Agent or the Team Agent

func _on_docs_pressed():
	get_tree().change_scene_to_file("res://starting_folder/docs.tscn")

func _on_run_dqn_agent_pressed() -> void:
	Global.dqn_agent_boolean = true
	get_tree().change_scene_to_file("res://agents/team_agent/team_agent_start.tscn")
