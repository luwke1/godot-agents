extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.function_agent_boolean == false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_button_pressed():
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
