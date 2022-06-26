extends Node2D
class_name EditorLevel

var ed_level : Level

var ed_color_wall := Color.red
var ed_color_line := Color.darkcyan
var ed_color_wall_normal := Color.coral
var ed_color_room := Color.darkslateblue
var ed_color_vert := Color.darkgoldenrod
var ed_display_normal := true
var ed_width_line := 2.0
var ed_font : Font = load("res://fonts/hack.tres")

var needs_update := true

var _rooms := []

var _rooms_points := []
var _lines_points := []

func _process(_delta: float) -> void:
	if needs_update && ed_level != null:
		_ed_gen_level_info()
		update()
		needs_update = false

func _draw() -> void:
	if ed_level != null:
		for room_points in _rooms_points:
			if room_points is PoolVector2Array:
				if room_points.size() >= 3:
					draw_colored_polygon(room_points, ed_color_room)
		for line in _lines_points:
			if line is EdLineInfo:
				if line.wall:
					draw_line(line.vert_start, line.vert_end, ed_color_wall, ed_width_line)
					if ed_display_normal:
						var pos : Vector2 = lerp(line.vert_start, line.vert_end, 0.5)
						var nrm := _ed_get_line_normal(line.vert_start, line.vert_end)
						draw_line(pos, pos + nrm * 20, ed_color_wall_normal)
				else:
					draw_line(line.vert_start, line.vert_end, ed_color_line, ed_width_line)
				
				draw_string(ed_font, line.vert_start + Vector2(1, -1) * 20, var2str(line.idx*2+0))
				draw_circle(line.vert_start, 4.0, ed_color_vert)
				
				draw_string(ed_font, line.vert_end + Vector2(-1, -1) * 20, var2str(line.idx*2+1))
				draw_circle(line.vert_end, 4.0, ed_color_vert)

func _ed_gen_level_info() -> void:
	_rooms.clear()
	_rooms_points.clear()
	_lines_points.clear()
	for i in ed_level.lvl_rooms.size():
		if ed_level.lvl_rooms[i] == null:
			continue
		if ed_level.lvl_rooms[i] is Level_Room:
			var room : Level_Room = ed_level.lvl_rooms[i]
			var room_points : PoolVector2Array = room.get_poly_array()
			
			for j in room_points.size():
				room_points[j] *= 32
			_rooms_points.push_back(room_points)
			for j in room.room_lines.size():
				if room.room_lines[j] is Level_Line:
					var line : Level_Line = room.room_lines[j]
					var linedinfo := EdLineInfo.new(line.vert_start * 32, line.vert_end * 32, j, room.check_line_has_wall(j))
					_lines_points.push_back(linedinfo)

func _ed_get_line_normal(v_0 : Vector2, v_1 : Vector2) -> Vector2:
	var nrm : Vector2 = v_1 - v_0
	nrm = Vector2(-nrm.y, nrm.x).normalized()
	return nrm

class EdLineInfo extends Reference:
	var vert_start : Vector2
	var vert_end : Vector2
	var idx : int
	var wall : bool
	
	func _init(v_0 : Vector2, v_1 : Vector2, id : int, w : bool) -> void:
		vert_start = v_0
		vert_end = v_1
		idx = id
		wall = w
