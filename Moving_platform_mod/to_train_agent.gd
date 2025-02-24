extends Node2D

const STATES = 22  			# in a rough 3x13 grid, with several that cannot be moved into ..careful ... from tutorial_tester
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_return_pressed():
	get_tree().change_scene_to_file("res://notes.tscn")

func _on_more_pressed():
	# Example file path
	var file_path = "user://q_table.json"
	
	# Load the Q-table and print it
	var loaded_q_table = load_q_table(file_path)
	
	print("and here is the current  q_table ")
	print("   ")
	for state in range(STATES):
		print("State", state, ": ", loaded_q_table[state])
	
func load_q_table(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var data = file.get_line()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(data)
		if parse_result == OK:
			return json.data
		else:
			print("Failed to parse JSON.")
			return []
	else:
		print("Failed to open file for reading.")
		return []
