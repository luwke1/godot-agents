extends Node2D

@onready var ui = %UI

func update_ui_score(value):
	ui.update_score(value)
	
func get_ui_score():
	return ui.get_score()
