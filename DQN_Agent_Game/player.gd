extends CharacterBody2D

@export var speed = 400.0
@export var jump_velocity = -650.0
@export var jump_count = 2
@export var gravity_muultiplier = 2.0
@export var currentLevel:Node2D

var current_jumps = 0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var vision = {}

func _physics_process(delta):
	apply_gravity(delta)
	handle_jump()
	handle_movement()
	
	var player_position = self.position
	update_vision()
	print(vision)

func update_vision():
	for child in get_children():
		if child is RayCast2D:  # Check if the child is a RayCast2D node
			if child.is_colliding():  # Check if the raycast detects a collision
				var collision_point = (child.get_collision_point() - global_position).length()
				vision[child.name] = collision_point / 150
			else:
				vision[child.name] = 150

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
	if body.is_in_group("collectable"):
		currentLevel.update_ui_score(body.value)
		body.collect()
		
