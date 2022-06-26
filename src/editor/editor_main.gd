extends Node2D

onready var _2d_scene := get_node("Scene2D")
onready var _2d_level := _2d_scene.get_node("Level2D")
onready var _2d_camera := _2d_scene.get_node("Camera2D")
onready var _2d_grid := _2d_camera.get_node("Grid")

onready var _3d_view := get_node("GUI_Layer/GUI_Control/View_3D")
onready var _3d_scene := _3d_view.get_node("ViewportContainer/Viewport/Scene3D")
onready var _3d_level := _3d_scene.get_node("Level3D")

var _ed_level : Level

enum TOOL_MODE { TM_DRAW, TM_WALL_EDIT, TM_VERTEX_EDIT }
enum SEL_MODE { SEL_VERT_NONE, SEL_VERT_START, SEL_VERT_END }

var _ed_tool_mode : int = TOOL_MODE.TM_DRAW

var _ed_sel_room : int = -1
var _ed_sel_line : int = -1
var _ed_sel_vert : int = SEL_MODE.SEL_VERT_NONE

var _ed_stored_vert_0 := Vector2.ZERO
var _ed_stored_vert_1 := Vector2.ZERO

var _ed_drawing := false

func _init() -> void:
	#VisualServer.set_debug_generate_wireframes(true)
	pass

func _ready() -> void:
	create_new_level()
	_ed_level.create_box_no_walls(Vector2.ZERO, Vector2(6, 6), "devtex_0", "devtex_0")
	
	_ed_sel_room = _ed_level.lvl_rooms.size() - 1
	
	_ed_gen_level_3d()
	#_3d_scene.get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _process(_delta: float) -> void:
	update()

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("show_view3d"):
		_3d_view.visible = !_3d_view.visible
	match _ed_tool_mode:
		TOOL_MODE.TM_DRAW:
			_draw_tool_input(event)
		TOOL_MODE.TM_WALL_EDIT:
			_wall_edit_tool_input(event)
		TOOL_MODE.TM_VERTEX_EDIT:
			_vert_edit_tool_input(event)

func _draw() -> void:
	match _ed_tool_mode:
		TOOL_MODE.TM_DRAW:
			if _ed_drawing:
				draw_line(_ed_stored_vert_0*32, _ed_stored_vert_1*32, Color.green)
		TOOL_MODE.TM_WALL_EDIT:
			draw_line(_ed_stored_vert_0*32, _ed_stored_vert_1*32, Color.green)
		TOOL_MODE.TM_VERTEX_EDIT:
			draw_line(_ed_stored_vert_0*32, _ed_stored_vert_1*32, Color.green)
			draw_circle(_ed_stored_vert_0*32, 4.0, Color.green)

func create_new_level(lvl_name := "Untitled") -> void:
	if _ed_level != null:
		_ed_level.free()
	
	_ed_level = Level.new(lvl_name)
	_2d_level.ed_level = _ed_level
	
	_redo_scene_displays()

func _draw_tool_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var raw_pos : Vector2 = _get_mouse_event_pos(event)
		var pos : Vector2 = (raw_pos/_2d_grid.grid).round()*_2d_grid.grid
		
		if !_ed_drawing:
			_ed_stored_vert_0 = pos / 32
		else:
			_ed_stored_vert_1 = pos / 32
	
	if Input.is_action_just_pressed("primary"):
		if !_ed_drawing:
			_ed_drawing = true
		else:
			if _ed_stored_vert_0.distance_squared_to(_ed_stored_vert_1) > 0.001:
				_ed_drawing = false
				if _ed_sel_room >= _ed_level.lvl_rooms.size():
					_ed_sel_room = _ed_level.lvl_rooms.size() - 1
				if _ed_sel_room > -1:
					var room : Level_Room = _ed_level.get_room(_ed_sel_room)
					room.add_wall(_ed_stored_vert_0, _ed_stored_vert_1)
					_ed_sel_line = room.room_lines.size() - 1
					
					_redo_scene_displays()

func _wall_edit_tool_input(event : InputEvent) -> void:
	var room : Level_Room = null
	if _ed_sel_room > -1:
		room = _ed_level.get_room(_ed_sel_room)
	var different := false
	
	if room.room_lines.size() > 0:
		if Input.is_action_just_pressed("sel_increment"):
			_ed_sel_line = posmod(_ed_sel_line+1, room.room_lines.size())
			different = true
		if Input.is_action_just_pressed("sel_decrement"):
			_ed_sel_line = posmod(_ed_sel_line-1, room.room_lines.size())
			different = true
	
	var line : Level_Line = null
	if _ed_sel_line > -1 && room != null:
		line = room.get_line(_ed_sel_line)
	
	if line != null && different:
		var center_0 : Vector2 = lerp(_ed_stored_vert_0, _ed_stored_vert_1, 0.5)
		var center_1 : Vector2 = lerp(line.vert_start, line.vert_end, 0.5)
		
		var v_0 := center_1 - line.vert_start
		var v_1 := center_1 - line.vert_end
		
		_ed_stored_vert_0 = center_0 + v_1
		_ed_stored_vert_1 = center_0 + v_0
	
	if event is InputEventMouseMotion:
		var raw_pos : Vector2 = _get_mouse_event_pos(event)
		var pos : Vector2 = (raw_pos/_2d_grid.grid).round()*_2d_grid.grid
		
		if line != null:
			var center : Vector2 = lerp(line.vert_start, line.vert_end, 0.5)
			var v_0 := center - line.vert_start
			var v_1 := center - line.vert_end
			
			_ed_stored_vert_0 = pos / 32 + v_1
			_ed_stored_vert_1 = pos / 32 + v_0
	
	if line != null && Input.is_action_just_pressed("primary"):
		line.vert_start = _ed_stored_vert_0
		line.vert_end = _ed_stored_vert_1
		
		_redo_scene_displays()

func _vert_edit_tool_input(event : InputEvent) -> void:
	var room : Level_Room = null
	if _ed_sel_room > -1:
		room = _ed_level.get_room(_ed_sel_room)
	
	if Input.is_action_just_pressed("sel_increment"):
		_ed_sel_vert = SEL_MODE.SEL_VERT_START
	if Input.is_action_just_pressed("sel_decrement"):
		_ed_sel_vert = SEL_MODE.SEL_VERT_END
	
	var line : Level_Line = null
	if _ed_sel_line > -1 && room != null:
		line = room.get_line(_ed_sel_line)
		
		if _ed_sel_vert == SEL_MODE.SEL_VERT_START:
			_ed_stored_vert_1 = line.vert_start
		else:
			_ed_stored_vert_1 = line.vert_end
	
	if event is InputEventMouseMotion:
		var raw_pos : Vector2 = _get_mouse_event_pos(event)
		var pos : Vector2 = (raw_pos/_2d_grid.grid).round()*_2d_grid.grid
		
		if line != null:
			_ed_stored_vert_0 = pos / 32
	
	if line != null && _ed_sel_vert != SEL_MODE.SEL_VERT_NONE && Input.is_action_just_pressed("primary"):
		if _ed_sel_vert == SEL_MODE.SEL_VERT_START:
			line.vert_start = _ed_stored_vert_0
		else:
			line.vert_end = _ed_stored_vert_0
		
		_redo_scene_displays()

func _get_mouse_event_pos(event : InputEvent) -> Vector2:
	return event.position * _2d_camera.zoom + (_2d_camera.position - get_viewport_rect().size * 0.5 * _2d_camera.zoom)

func _redo_scene_displays() -> void:
	_2d_level.needs_update = true
	_ed_gen_level_3d()

func _ed_gen_level_3d() -> void:
	_ed_clear_level_3d()
	
	for i in _ed_level.lvl_rooms.size():
		var room := _ed_level.get_room(i)
		var room_msh : ArrayMesh = room.gen_room_mesh()
		var room_mdl := MeshInstance.new()
		room_mdl.mesh = room_msh
		_3d_level.add_child(room_mdl)

func _ed_clear_level_3d() -> void:
	if _3d_level.get_child_count() > 0:
		for child in _3d_level.get_children():
			_3d_level.remove_child(child)
			child.queue_free()

func _on_Tool_Draw_pressed() -> void:
	_ed_tool_mode = TOOL_MODE.TM_DRAW

func _on_Tool_Wall_Edit_pressed() -> void:
	_ed_tool_mode = TOOL_MODE.TM_WALL_EDIT

func _on_Tool_Vertex_Edit_pressed() -> void:
	_ed_tool_mode = TOOL_MODE.TM_VERTEX_EDIT

func _on_Op_NewRoom_pressed() -> void:
	_ed_level.create_empty_room()
	_ed_sel_room = _ed_level.lvl_rooms.size() - 1

func _on_Op_FlipWall_pressed() -> void:
	var room : Level_Room = null
	var line : Level_Line = null
	
	if _ed_sel_room > -1:
		room = _ed_level.get_room(_ed_sel_room)
	
	if _ed_sel_line > -1 && room != null:
		line = room.get_line(_ed_sel_line)
	
	if line != null:
		var tmp := line.vert_start
		
		line.vert_start = line.vert_end
		line.vert_end = tmp
		
		_redo_scene_displays()
