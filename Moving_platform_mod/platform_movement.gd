extends StaticBody2D

var movement_speed = 700
var left_edge = 0
var right_edge = 1152

var direction: int = 1  # 1 for right, -1 for left
var x_width: float = 0

var gameOver = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var polygon = $Polygon2D
	if polygon and polygon.polygon.size() > 0:
		var points = polygon.polygon
		var min_x = points[0].x
		var max_x = points[0].x
		
		for point in points:
			min_x = min(min_x, point.x)
			max_x = max(max_x, point.x)
		
		x_width = max_x - min_x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not gameOver:
		position.x += movement_speed * direction * delta

	# Check boundaries and reverse direction if necessary
		if position.x >= right_edge - x_width:
			position.x = right_edge - x_width
			direction = -1
		elif position.x <= left_edge:
			position.x = left_edge
			direction = 1
		
func set_game_over():
	gameOver = true
