extends Camera

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	var can_move = Input.is_action_pressed("move_camera")
	if event is InputEventMouseMotion && can_move:
		var m_sens := 0.2
		var pitch : float = -event.relative.y * m_sens
		self.rotate_y((deg2rad(-event.relative.x * m_sens)))
		self.rotate_object_local(Vector3.RIGHT, deg2rad(pitch))

func _physics_process(_delta: float) -> void:
	self.translation += self.global_transform.basis * get_input_direction() * 0.1

static func get_input_direction() -> Vector3:
	return Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0,
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		)
