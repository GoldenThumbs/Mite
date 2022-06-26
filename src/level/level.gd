extends Reference
class_name Level

var lvl_name : String
var lvl_tex_path : String
var lvl_rooms := []

func _init(name := "Untitled", tex_path := "textures") -> void:
	self.lvl_name = name
	self.lvl_tex_path = tex_path

func create_empty_room(tex_f := "", tex_c := "") -> void:
	var room := Level_Room.new()
	room.room_tex_floor = tex_f
	room.room_tex_ceiling = tex_c
	
	lvl_rooms.push_back(room)

func create_box_no_walls(center := Vector2.ZERO, size := Vector2.ONE, tex_f := "", tex_c := "") -> void:
	var h_size := size * 0.5
	var room_verts : PoolVector2Array = []
	room_verts.resize(4)
	
	room_verts[0] = center + Vector2(-h_size.x, h_size.y)
	room_verts[1] = center + Vector2( h_size.x, h_size.y)
	room_verts[2] = center + Vector2( h_size.x,-h_size.y)
	room_verts[3] = center + Vector2(-h_size.x,-h_size.y)
	
	var room := Level_Room.new()
	for i in 4:
		var idx_0 = i
		var idx_1 = posmod(i+1, 4)
		room.add_line(room_verts[idx_0], room_verts[idx_1])
	room.room_tex_floor = tex_f
	room.room_tex_ceiling = tex_c
	
	lvl_rooms.push_back(room)

func create_box(center := Vector2.ZERO, size := Vector2.ONE, tex_w := "", tex_f := "", tex_c := "") -> void:
	var h_size := size * 0.5
	var room_verts : PoolVector2Array = []
	room_verts.resize(4)
	
	room_verts[0] = center + Vector2(-h_size.x, h_size.y)
	room_verts[1] = center + Vector2( h_size.x, h_size.y)
	room_verts[2] = center + Vector2( h_size.x,-h_size.y)
	room_verts[3] = center + Vector2(-h_size.x,-h_size.y)
	
	var room := Level_Room.new()
	for i in 4:
		var idx_0 = i
		var idx_1 = posmod(i+1, 4)
		room.add_wall(room_verts[idx_0], room_verts[idx_1], tex_w)
	room.room_tex_floor = tex_f
	room.room_tex_ceiling = tex_c
	
	lvl_rooms.push_back(room)

func create_room(center := Vector2.ZERO, size := 6.0, res := 8, tex_w := "", tex_f := "", tex_c := "") -> void:
	res = int(max(3, res))
	var rad := size * 0.5
	var room_verts : PoolVector2Array = []
	room_verts.resize(res)
	
	for i in res:
		var angle = float(i+1) / float(res) * TAU
		var vec := Vector2(rad, rad)
		vec.x *= cos(angle)
		vec.y *= sin(angle)
		room_verts[i] = center + vec
	
	var room := Level_Room.new()
	for i in res:
		var idx_0 = i
		var idx_1 = posmod(i+1, res)
		room.add_wall(room_verts[idx_0], room_verts[idx_1], tex_w)
	room.room_tex_floor = tex_f
	room.room_tex_ceiling = tex_c
	
	lvl_rooms.push_back(room)

func get_room(idx : int) -> Level_Room:
	var room : Level_Room = null
	if _check_valid_index_room(idx):
		room = lvl_rooms[idx]
	return room

func del_room(idx : int) -> void:
	if _check_valid_index_room(idx):
		lvl_rooms.remove(idx)

func _check_valid_index_room(idx : int) -> bool:
	var check := idx < lvl_rooms.size() && idx > -1
	if !check:
		print("ERROR: Room index [" + var2str(idx) + "] out of range!")
	return check
