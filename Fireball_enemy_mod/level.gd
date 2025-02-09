extends Node2D

@onready var ui = %UI

func update_ui_score(value):
	return ui.update_score(value)
	
func show_lost_ui():
	ui.show_lost()
