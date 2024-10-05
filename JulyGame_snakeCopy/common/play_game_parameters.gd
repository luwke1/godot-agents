extends Node3D

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot = $TwistPivot/PitchPivot 

var SAFE_LANDING_SPEED = -20

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Hello from the Human playing screen")
	$landing_zone.position = Global.landing_site
	Global.bombs = 30
	$powerNode.position = Vector3(6,2,7)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_key_pressed(KEY_P):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://starting_folder/main_menu.tscn")
		
# rocket landing where it shouldn't 
func _on_rocket_body_entered(body):
	#print("hit something")
	if(Global.flying_boolean):
		print("flying and hit something")
		
		if(abs($rocket.rocket_position.x - $rocket.landing_site.x) <= 20.0 && abs($rocket.rocket_position.z - $rocket.landing_site.z) <= 20.0 && $rocket.rocket_speed.y > SAFE_LANDING_SPEED ):
			print("landed safely")
			get_tree().change_scene_to_file("res://common/safe_landing.tscn")
		else: 
			Global.flying_boolean = false
			$rocket.kablooey()

