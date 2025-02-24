extends CanvasLayer
class_name UI

@onready var score_label = %Label
@onready var completed_ui = %GameCompleteUI
@onready var lost_ui = %GameLostUI
@onready var current_control_type = Globals.control_type
var score = 0
var maxScore = 30

func update_score(value):
	score += value
	update_score_label()
	
	if score >= maxScore:
		%GameCompleteUI.visible = true
	#	completed_ui.visable = true
		%Label.visible = false
	#	score_label.visable = false
		Globals.control_type = "human"
		return true # return true if game won
	return false # return false otherwise
	
func show_lost():
	%GameLostUI.visible = true
	
func update_score_label():
	score_label.text = "Score:  " + str(score)
	
func _on_button_pressed():
	Globals.control_type = current_control_type 
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().change_scene_to_file("res://intro.tscn")

	


func _on_end_run_and_quit_pressed():
	get_tree().change_scene_to_file("res://intro.tscn")
