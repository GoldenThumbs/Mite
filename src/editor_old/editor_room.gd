extends Node2D
class_name Editor_Room

var needs_update := true
var poly_is_good := false
var ed_room_color := Color.orangered
var _room_points : PoolVector2Array = []

func _process(_delta: float) -> void:
	if needs_update:
		_room_points.resize(0)
		
		var lines := get_lines()
		
		for line in lines:
			var has_point_0 := false
			var has_point_1 := false
			for p in _room_points.size():
				if has_point_0:
					break
				has_point_0 = _room_points[p] == line.ed_vert_start
			for p in _room_points.size():
				if has_point_1:
					break
				has_point_1 = _room_points[p] == line.ed_vert_end
			if !has_point_0:
				_room_points.push_back(line.ed_vert_start)
			if !has_point_1:
				_room_points.push_back(line.ed_vert_end)
		update()
		poly_is_good = is_poly_good()
		print(poly_is_good)
		needs_update = false

func _draw() -> void:
	if poly_is_good:
		ed_room_color.a = 0.75
		draw_colored_polygon(_room_points, ed_room_color)

func is_poly_good() -> bool:
	var n := _room_points.size()
	if n < 3:
		return false
	
	var prev := 0.0
	var curr := 0.0
	for i in n:
		var v_0 : Vector2 = _room_points[i]
		var v_1 : Vector2 = _room_points[posmod(i+1, n)]
		var v_2 : Vector2 = _room_points[posmod(i+2, n)]
		curr = _z_cross(v_0, v_1, v_2)
		if curr != 0.0:
			if curr * prev < 0:
				return false
			else:
				prev = curr
	return true

func _z_cross(a : Vector2, b : Vector2, c : Vector2) -> float:
	var x1 := b.x - a.x
	var y1 := b.y - a.y
	var x2 := c.x - a.x
	var y2 := c.y - a.y
	return x1*y2 - y1*x2

func get_lines() -> Array:
	var arr := []
	for child in get_children():
			if child is Editor_Line:
				arr.push_back(child)
	return arr
