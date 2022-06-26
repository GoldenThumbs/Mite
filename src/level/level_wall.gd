extends Reference
class_name Level_Wall

var line_idx : int
var tex_main : String

func _init(line : int, tex := "") -> void:
	line_idx = line
	tex_main = tex
