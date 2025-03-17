extends StaticBody2D

@export var value = 10

var is_active = true  # Flag to track if the collectable is active

func collect():
	queue_free()
	
func reset_position():
	set_visible(true)
	is_active = true
