extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_return_pressed():
	get_tree().change_scene_to_file("res://intro.tscn")

func _on_train_agent_notes_pressed():
	get_tree().change_scene_to_file("res://to_train_agent.tscn")

func _on_process_notes_pressed():
	get_tree().change_scene_to_file("res://process_notes.tscn")
