extends Node2D
class_name Editor_Wall

var ed_wall_color := Color.red setget _set_wall_color
var ed_line_width := 4.0 setget _set_line_width
var ed_linedef : Editor_Line setget _set_line
var ed_normal_color := Color.yellow
var ed_show_normal := true

func do_redraw() -> void:
	update()

func _set_wall_color(new : Color) -> void:
	ed_wall_color = new
	update()

func _set_line_width(new : float) -> void:
	ed_line_width = new
	update()

func _set_line(new : Editor_Line) -> void:
	ed_linedef = new
	update()

func _draw() -> void:
	draw_line(ed_linedef.ed_vert_start, ed_linedef.ed_vert_end, ed_wall_color, ed_line_width)
	if ed_show_normal:
		var pos : Vector2 = lerp(ed_linedef.ed_vert_start, ed_linedef.ed_vert_end, 0.5)
		var nrm := get_wall_normal()
		draw_line(pos, pos + nrm * 20, ed_normal_color)

func get_wall_normal() -> Vector2:
	var nrm : Vector2 = ed_linedef.ed_vert_end - ed_linedef.ed_vert_start
	nrm = Vector2(-nrm.y, nrm.x).normalized()
	return nrm
