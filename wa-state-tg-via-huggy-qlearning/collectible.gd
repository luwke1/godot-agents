extends StaticBody2D

@export var value = 10

var is_active = true  # Flag to track if the collectable is active

func collect():
	if is_active:
		is_active = false
		set_visible(false)

func reset_position():
	set_visible(true)
	is_active = true
