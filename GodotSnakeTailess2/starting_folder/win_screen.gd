extends Node2D
@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = "The agent won! \nIt successfully got " + str(Global.bombs) + " points"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
