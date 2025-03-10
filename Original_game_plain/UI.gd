extends CanvasLayer
class_name UI

@onready var score_label = %Label
@onready var completed_ui = %GameCompleteUI
@onready var current_control_type = Globals.control_type
var score = 0
var maxScore = 30

func update_score(value):
	score += value
	update_score_label()
	
	if Globals.control_type != "train" and score >= maxScore:
		%GameCompleteUI.visible = true
	#	completed_ui.visable = true
		%Label.visible = false
	#	score_label.visable = false
		Globals.control_type = "human"
	
	
func update_score_label():
	score_label.text = "Score:  " + str(score)
	
func get_score():
	return score
	
func _on_button_pressed():
	Globals.control_type = current_control_type 
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().change_scene_to_file("res://intro.tscn")

	


func _on_end_run_and_quit_pressed():
	var player = get_parent().get_node("level/player")
	if player:
		if Globals.control_type == "train":
			if player.has_method("save_agent"):
				player.save_agent()
				print("Saving agent state...")
			Globals.control_type == ""
		elif Globals.control_type == "agent":
			if player.has_method("stop_training"):
				player.stop_training()
	get_tree().change_scene_to_file("res://intro.tscn")
