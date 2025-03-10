# level.gd
extends Node2D

@onready var ui = %UI
@onready var player_factory = $PlayerFactory

func _ready():
	# Create the player using the factory
	var player = player_factory.create_player()
	if player:
		add_child(player)  # Add the player to the scene
	else:
		print("Failed to create player.")

func update_ui_score(value):
	ui.update_score(value)
	
func get_ui_score():
	return ui.get_score()
