extends RigidBody3D

const ROT_SPEED = 5     # the numbere of degrees the Nodule rotates every frame

@onready var power_node = $"."


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_y(deg_to_rad(ROT_SPEED))
	

func _on_body_entered(body):
	if(body == $"../rocket"):
		#queue_free()
		Global.bombs = Global.bombs + 10
		regen_power_node()
	
func regen_power_node():
	while Global.power_node_gen:
		Global.power_node_gen = false
		Global.power_node_position = Vector3(randi_range(-25, 25), 3, randi_range(-30, 30))
		power_node.position = Global.power_node_position 
	Global.power_node_gen = true
