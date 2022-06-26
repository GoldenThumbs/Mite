extends WindowDialog

onready var _3d_camera := get_node("ViewportContainer/Viewport/Scene3D/Camera")
var can_move := false

func _input(event : InputEvent) -> void:
	can_move = visible && Input.is_action_pressed("move_camera_3d")
	_3d_camera_look(event)

func _physics_process(_delta : float) -> void:
	_3d_camera_move()

func _3d_camera_move() -> void:
	if can_move:
		_3d_camera.translate(get_input_direction() * 0.1)

func _3d_camera_look(event : InputEvent) -> void:
	if can_move:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event is InputEventMouseMotion:
			var m_sens := 0.2
			var pitch : float = -event.relative.y * m_sens
			_3d_camera.rotate_y((deg2rad(-event.relative.x * m_sens)))
			_3d_camera.rotate_object_local(Vector3.RIGHT, deg2rad(pitch))
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

static func get_input_direction() -> Vector3:
	return Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0,
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		)
