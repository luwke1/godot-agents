extends CharacterBody2D # or Area2D/KinematicBody2D depending on your setup

# Speed of the enemy (pixels per second)
@export var speed: float = 250.0

# Reference to the player node
var player: CharacterBody2D
var gameOver = false

func _ready():
	# Find the player node in the scene
	player = get_tree().get_first_node_in_group("player")  # Assuming the player is in a "Player" group
	if not player:
		print("Player not found! Make sure the player is in the 'Player' group.")

func _process(delta):
	if player and not gameOver:
		# Calculate the direction to the player
		var direction = (player.global_position - global_position).normalized()
		
		# Move the enemy towards the player
		velocity = direction * speed
		
		# Move the enemy using move_and_slide (for CharacterBody2D)
		move_and_slide()

func set_game_over():
	gameOver = true
