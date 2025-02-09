extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_quit_pressed():
	get_tree().quit()

func _on_play_human_pressed():
	Globals.control_type = "human"
	get_tree().change_scene_to_file("res://main_game.tscn")

func _on_play_function_pressed():
	Globals.control_type = "function"
	get_tree().change_scene_to_file("res://main_game.tscn")

func _on_notes_pressed():
	get_tree().change_scene_to_file("res://notes.tscn")

func _on_agent_run_pressed():
	Globals.control_type = "agent"
	get_tree().change_scene_to_file("res://main_game.tscn")

func _on_agent_train_pressed():
	$NowTraining.visible = true
	get_tree().change_scene_to_file("res://tutorial_tester.tscn")
