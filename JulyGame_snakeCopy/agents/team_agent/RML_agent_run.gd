extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	print("we are in the RML agent ")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_to_rml_page_pressed():
	get_tree().change_scene_to_file("res://agents/team_agent/agent_placeholder.tscn")


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
