extends Camera2D

var _2d_camera_target := Vector2.ZERO

func _process(delta: float) -> void:
	if position.distance_to(_2d_camera_target) > 0.001:
		position = lerp(position, _2d_camera_target, 7.5 * delta)

func _unhandled_input(event : InputEvent) -> void:
	_2d_camera_move(event)

func _2d_camera_move(event : InputEvent) -> void:
	if Input.is_action_just_released("zoom_in_camera_2d"):
		if zoom.length() > 1.5:
			zoom -= Vector2.ONE * 0.25
	if Input.is_action_just_released("zoom_out_camera_2d"):
		zoom += Vector2.ONE * 0.25
		zoom.x = min(zoom.x, 3)
		zoom.y = min(zoom.y, 3)
	
	if Input.is_action_pressed("move_camera_2d"):
		if event is InputEventMouseMotion:
			_2d_camera_target -= event.relative * zoom
			_2d_camera_target.x = clamp(_2d_camera_target.x, -2048, 2048)
			_2d_camera_target.y = clamp(_2d_camera_target.y, -2048, 2048)
