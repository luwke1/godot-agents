extends CharacterBody2D

@export var speed = 400.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_muultiplier = 2.0

var current_jumps = 0
var level

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	initialize()
	
func initialize() -> void:
	level = get_parent()
	# Snap the player to the ground
	var collision = move_and_collide(Vector2(0, 10))  # Move down slightly to detect the ground
	if collision:
		position.y = collision.get_position().y  # Align with the ground
	print("Human player initialized")
	
func _physics_process(delta):
	apply_gravity(delta)
	handle_jump()
	handle_movement()
	
	var player_position = self.position


func apply_gravity(delta):
	# If not on the floor, accelerate downward
	if not is_on_floor():
		velocity.y += gravity * gravity_muultiplier * delta
	else:
		# If on the floor, reset jump count
		current_jumps = 0
			
func handle_jump():
	if is_on_floor(): current_jumps = 0
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or current_jumps < jump_count:
			velocity.y = jump_velocity
			current_jumps += 1
			
func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		$GFX.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func _on_area_2d_body_entered(body):
	if body.is_in_group("collectable") and body.is_active:
		var coin_value = body.value
		level.update_ui_score(coin_value)
		body.collect()
