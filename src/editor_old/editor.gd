extends Node2D

onready var _3d_view := get_node("GUI_Layer/GUI_Control/View_3D")
onready var _3d_scene := _3d_view.get_node("ViewportContainer/Viewport/Scene3D")
onready var _3d_level := _3d_scene.get_node("Level3D")

onready var _2d_scene := get_node("Scene2D")
onready var _2d_level := _2d_scene.get_node("Level2D")
onready var _2d_camera := _2d_scene.get_node("Camera2D")
onready var _2d_grid := _2d_camera.get_node("Grid")

var _level : Level
var _2d_can_move := false

var _2d_camera_target := Vector2.ZERO

var _drawing_wall := false
var _drawn_wall : Editor_Wall
var _drawn_line : Editor_Line
var _drawn_room : Editor_Room
var _sel_wall : Editor_Wall
var _sel_room : Editor_Room
var _stored_vert_0 := Vector2.ZERO
var _stored_vert_1 := Vector2.ZERO

enum {TM_DRAW, TM_WALL_EDIT, TM_VERTEX_EDIT}

var _tool_mode : int = TM_DRAW

func _ready() -> void:
	create_new_level()
	
	_drawn_room = Editor_Room.new()
	_2d_level.add_child(_drawn_room)

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("show_view3d"):
		_3d_level.add_child(_level.gen_level_geometry())
		_3d_view.visible = !_3d_view.visible
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	_2d_can_move = Input.is_action_pressed("move_camera_2d")
	
	_2d_camera_move(event)
	
	match _tool_mode:
		TM_DRAW:
			_draw_tool_input(event)
		TM_WALL_EDIT:
			_wall_edit_tool_input(event)

func _draw() -> void:
	if _drawing_wall:
		draw_line(_stored_vert_0, _stored_vert_1, Color.maroon, 2.0)

func _process(delta : float) -> void:
	if _2d_camera.position.distance_to(_2d_camera_target) > 0.001:
		_2d_camera.position = lerp(_2d_camera.position, _2d_camera_target, 7.5 * delta)

func _2d_camera_move(event : InputEvent) -> void:
	if Input.is_action_just_released("zoom_in_camera_2d"):
		if _2d_camera.zoom.length() > 1.5:
			_2d_camera.zoom -= Vector2.ONE * 0.25
	if Input.is_action_just_released("zoom_out_camera_2d"):
		_2d_camera.zoom += Vector2.ONE * 0.25
		_2d_camera.zoom.x = min(_2d_camera.zoom.x, 3)
		_2d_camera.zoom.y = min(_2d_camera.zoom.y, 3)
	
	if _2d_can_move:
		if event is InputEventMouseMotion:
			_2d_camera_target -= event.relative * _2d_camera.zoom
			_2d_camera_target.x = clamp(_2d_camera_target.x, -2048, 2048)
			_2d_camera_target.y = clamp(_2d_camera_target.y, -2048, 2048)

func _update_line_children(line : Editor_Line) -> void:
	for child in line.get_children():
		if child is Editor_Wall:
			child.do_redraw()

func _draw_tool_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var raw_pos : Vector2 = (event.position * _2d_camera.zoom + (_2d_camera.position - get_viewport_rect().size * 0.5 * _2d_camera.zoom))
		var pos = (raw_pos/_2d_grid.grid).round()*_2d_grid.grid
		
		if !_drawing_wall:
			_stored_vert_0 = pos
		else:
			_stored_vert_1 = pos
			update()
	
	if event.is_action_pressed("create_wall"):
		if !_drawing_wall:
			_drawing_wall = true
			_drawn_line = Editor_Line.new()
			_drawn_line.ed_vert_start = _stored_vert_0
		else:
			if _stored_vert_0.distance_to(_stored_vert_1) > 0.001:
				_drawing_wall = false
				_drawn_line.ed_vert_end = _stored_vert_1
				
				if _drawn_room != null:
					_drawn_room.add_child(_drawn_line)
					var drawn_wall := Editor_Wall.new()
					drawn_wall.ed_linedef = _drawn_line
					_drawn_line.add_child(drawn_wall)
					_drawn_room.needs_update = true

func _wall_edit_tool_input(event : InputEvent) -> void:
	pass

func create_new_level(lvl_name := "Untitled") -> void:
	if _level != null:
		_level.free()
	
	_level = Level.new(lvl_name)

func _on_Tool_Draw_pressed() -> void:
	_tool_mode = TM_DRAW

func _on_Tool_Wall_Edit_pressed() -> void:
	_tool_mode = TM_WALL_EDIT

func _on_Op_FlipWall_pressed() -> void:
	if !_drawing_wall && _drawn_line != null:
		var cache_v_0 := _drawn_line.ed_vert_start
		var cache_v_1 := _drawn_line.ed_vert_end
		_drawn_line.ed_vert_start = cache_v_1
		_drawn_line.ed_vert_end = cache_v_0
		_update_line_children(_drawn_line)
		_drawn_room.needs_update = true
