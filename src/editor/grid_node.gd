extends Node2D
class_name GridNode

var grid : int = 32

var color_0 := Color.darkgray
var color_1 := Color.darkslategray
var color_2 := Color.darkred

var camera : Camera2D

func _ready() -> void:
	if get_parent() is Camera2D:
		camera = get_parent()
	else:
		camera = get_parent().get_node("Camera2D")

func _process(_delta: float) -> void:
	if self.visible && camera != null:
		update()

func _draw() -> void:
	if self.visible && camera != null:
		var size := get_viewport_rect().size * camera.zoom
		var pos := camera.position
		var h_size := size * 0.5
		var amnt_x := ceil(size.x / grid)
		var amnt_y := ceil(size.y / grid)
		var h_amnt := Vector2(amnt_x, amnt_y) * 0.5
		
		var vrts_0 : PoolVector2Array = []
		var vrts_1 : PoolVector2Array = []
		for x in range(-int(h_amnt.x + 0.5), int(h_amnt.x + 0.5)):
			var fx := wrapf(x * grid - pos.x, -h_amnt.x * grid, h_amnt.x * grid)
			#var fx := x * grid - pos.x
			
			if self.to_global(Vector2(fx, 0.0)).x == 0.0:
				vrts_0.push_back(Vector2(fx,-h_size.y))
				vrts_0.push_back(Vector2(fx, h_size.y))
			else:
				vrts_1.push_back(Vector2(fx,-h_size.y))
				vrts_1.push_back(Vector2(fx, h_size.y))
		
		for y in range(-int(h_amnt.y + 0.5), int(h_amnt.y + 0.5)):
			var fy :=  wrapf(y * grid - pos.y, -h_amnt.y * grid, h_amnt.y * grid)
			#var fy := y * grid - pos.y
			
			if self.to_global(Vector2(0.0, fy)).y == 0.0:
				vrts_0.push_back(Vector2(-h_size.x, fy))
				vrts_0.push_back(Vector2( h_size.x, fy))
			else:
				vrts_1.push_back(Vector2(-h_size.x, fy))
				vrts_1.push_back(Vector2( h_size.x, fy))
		
		draw_multiline(vrts_1, color_1)
		if vrts_0.size() > 0:
			draw_multiline(vrts_0, color_0)
		
		var v_0 := Vector2(-2048,-2048) - pos
		var v_1 := Vector2(-2048, 2048) - pos
		var v_2 := Vector2( 2048, 2048) - pos
		var v_3 := Vector2( 2048,-2048) - pos
		
		draw_line(v_0, v_1, color_2, 8.0)
		draw_line(v_3, v_2, color_2, 8.0)
		draw_line(v_0, v_3, color_2, 8.0)
		draw_line(v_1, v_2, color_2, 8.0)
