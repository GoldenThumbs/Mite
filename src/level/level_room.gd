extends Reference
class_name Level_Room

var room_floor : float = 0.0
var room_height : float = 2.0
var room_tex_floor : String = ""
var room_tex_ceiling : String = ""
var room_lines := []
var room_walls := []

func add_line(v_0 : Vector2, v_1 : Vector2) -> void:
	var line : Level_Line = Level_Line.new(v_0, v_1)
	room_lines.push_back(line)

func add_wall(v_0 : Vector2, v_1 : Vector2, tex := "") -> void:
	var line : Level_Line = Level_Line.new(v_0, v_1)
	room_lines.push_back(line)
	
	var wall : Level_Wall = Level_Wall.new(room_lines.size()-1, tex)
	room_walls.push_back(wall)

func get_line(idx : int) -> Level_Line:
	var line : Level_Line = null
	if _check_valid_index_line(idx):
		line = room_lines[idx]
	return line

func get_wall(idx : int) -> Level_Wall:
	var wall : Level_Wall = null
	if _check_valid_index_wall(idx):
		wall = room_walls[idx]
	return wall

func edit_line_verts(idx : int, v_0 : Vector2, v_1 : Vector2) -> void:
	if _check_valid_index_line(idx):
		var line : Level_Line = room_lines[idx]
		line.vert_start = v_0
		line.vert_end = v_1
		room_lines[idx] = line

func edit_wall_verts(idx : int, v_0 : Vector2, v_1 : Vector2) -> void:
	if _check_valid_index_wall(idx):
		var wall : Level_Wall = room_walls[idx]
		edit_line_verts(wall.line_idx, v_0, v_1)

func edit_wall_tex(idx : int, tex := "") -> void:
	if _check_valid_index_wall(idx):
		var wall : Level_Wall = room_walls[idx]
		wall.tex_main = tex
		room_walls[idx] = wall

func check_line_has_wall(idx : int) -> bool:
	var has_wall := false
	
	if _check_valid_index_line(idx):
		for wall in room_walls:
			if wall.line_idx == idx:
				has_wall = true
				break
	
	return has_wall

func del_line(idx : int) -> void:
	if _check_valid_index_line(idx):
		room_lines.remove(idx)
		check_and_update_wall_indices(idx)

func del_wall(idx : int) -> void:
	if _check_valid_index_wall(idx):
		room_walls.remove(idx)

func check_and_update_wall_indices(del_line_idx : int) -> void:
	for wall in room_walls:
		if wall.line_idx < del_line_idx:
			continue
		
		if wall.line_idx == del_line_idx:
			room_walls.erase(wall)
		else:
			wall.line_idx -= 1

func _check_valid_index_line(idx : int) -> bool:
	var check := idx < room_lines.size() && idx > -1
	if !check:
		print("ERROR: Line index [" + var2str(idx) + "] out of range!")
	return check

func _check_valid_index_wall(idx : int) -> bool:
	var check := idx < room_walls.size() && idx > -1
	if !check:
		print("ERROR: Wall index [" + var2str(idx) + "] out of range!")
	return check

func gen_room_mesh(subdivide := false) -> ArrayMesh:
	var msh := ArrayMesh.new()
	
	for i in room_walls.size():
		var wall : Level_Wall = room_walls[i]
		if wall == null:
			continue
		
		var line : Level_Line = room_lines[wall.line_idx]
		
		var room_vp : PoolVector3Array = []
		var room_vn : PoolVector3Array = []
		var room_vt : PoolVector2Array = []
		var room_id : PoolIntArray = []
		
		var wall_res := _get_poly_wall(line, subdivide)
		room_vp = wall_res[0]
		room_id = wall_res[1]
		
		room_vn = _gen_mesh_normals(room_vp, room_id)
		room_vt = _gen_mesh_texcoords(room_vp, room_vn)
		
		var arr := []
		arr.resize(ArrayMesh.ARRAY_MAX)
		arr[ArrayMesh.ARRAY_VERTEX] = room_vp
		arr[ArrayMesh.ARRAY_NORMAL] = room_vn
		arr[ArrayMesh.ARRAY_TEX_UV] = room_vt
		arr[ArrayMesh.ARRAY_INDEX] = room_id
		msh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		
		var srf_mat : SpatialMaterial = null
		if !wall.tex_main.empty() && MatImport.ed_materials.has(wall.tex_main):
			srf_mat = MatImport.ed_materials[wall.tex_main]
		
		var srf_id = msh.get_surface_count() - 1
		if srf_id > -1:
			msh.surface_set_material(srf_id, srf_mat)
	
	var points_2d := get_poly_array()
	var center := Vector2.ZERO
	for point in points_2d:
		center += point
	center /= points_2d.size()
	
	var verts_2d : PoolVector2Array = PoolVector2Array([center]) + points_2d
	
	var n := verts_2d.size()
	if n > 3:
		var vp_f : PoolVector3Array = []
		var vn_f : PoolVector3Array = []
		var id_f : PoolIntArray = []
		
		var vp_c : PoolVector3Array = []
		var vn_c : PoolVector3Array = []
		var id_c : PoolIntArray = []
		
		var min_vp : Vector2 = Vector2.ONE * INF
		var max_vp : Vector2 = Vector2.ZERO
	
		for i in n:
			var vert := verts_2d[i]
			
			min_vp.x = min(min_vp.x, vert.x)
			min_vp.y = min(min_vp.y, vert.y)
			
			max_vp.x = max(max_vp.x, vert.x)
			max_vp.y = max(max_vp.y, vert.y)
			
			var vp_floor := Vector3(vert.x, room_floor, vert.y)
			vp_f.push_back(vp_floor)
		id_f = _gen_mesh_indices(n)
		
		if subdivide:
			var area := min_vp.distance_squared_to((max_vp))
			var tes_area := int(min(2, floor(area / 256)))
		
			var t_res := tesselate_iterate(vp_f, id_f, tes_area)
			vp_f = t_res[0]
			id_f = t_res[1]
		
		vn_f = _gen_mesh_normals(vp_f, id_f)
		
		vp_c = vp_f
		vn_c = vn_f
		id_c = id_f
		for i in vp_c.size():
			vp_c[i].y += room_height
			vn_c[i] *= -1.0
		id_c.invert()
		
		var arr := []
		arr.resize(ArrayMesh.ARRAY_MAX)
		arr[ArrayMesh.ARRAY_VERTEX] = vp_f
		arr[ArrayMesh.ARRAY_NORMAL] = vn_f
		arr[ArrayMesh.ARRAY_TEX_UV] = _gen_mesh_texcoords(vp_f, vn_f)
		arr[ArrayMesh.ARRAY_INDEX] = id_f
		msh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		
		var srf_mat : SpatialMaterial = null
		if !room_tex_floor.empty() && MatImport.ed_materials.has(room_tex_floor):
			srf_mat = MatImport.ed_materials[room_tex_floor]
		
		var srf_id = msh.get_surface_count() - 1
		if srf_id > -1:
			msh.surface_set_material(srf_id, srf_mat)
		
		arr[ArrayMesh.ARRAY_VERTEX] = vp_c
		arr[ArrayMesh.ARRAY_NORMAL] = vn_c
		arr[ArrayMesh.ARRAY_TEX_UV] = _gen_mesh_texcoords(vp_c, vn_c)
		arr[ArrayMesh.ARRAY_INDEX] = id_c
		msh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		
		if !room_tex_ceiling.empty() && MatImport.ed_materials.has(room_tex_ceiling):
			srf_mat = MatImport.ed_materials[room_tex_ceiling]
		
		srf_id = msh.get_surface_count() - 1
		if srf_id > -1:
			msh.surface_set_material(srf_id, srf_mat)
	
	return msh

func _gen_mesh_indices(vert_array_size : int) -> PoolIntArray:
	var id : PoolIntArray = []
	for i in range(0, vert_array_size-2):
		id.append_array([0, i+1, i+2])
	id.append_array([0, vert_array_size-1, 1])
	return id

func _gen_mesh_normals(vert_array : PoolVector3Array, index_array : PoolIntArray) -> PoolVector3Array:
	var vn : PoolVector3Array = []
	vn.resize(vert_array.size())
	var base_idx := 0
	while base_idx < index_array.size():
		var idx_0 := index_array[base_idx+0]
		var idx_1 := index_array[base_idx+1]
		var idx_2 := index_array[base_idx+2]
		
		var v_0 := vert_array[idx_0]
		var v_1 := vert_array[idx_1]
		var v_2 := vert_array[idx_2]
		
		var delta_0 := v_1 - v_0
		var delta_1 := v_2 - v_0
		
		var normal := delta_1.cross(delta_0)
		
		var a_0 := (v_1 - v_0).normalized().angle_to((v_2 - v_0).normalized())
		var a_1 := (v_2 - v_1).normalized().angle_to((v_0 - v_1).normalized())
		var a_2 := (v_0 - v_2).normalized().angle_to((v_1 - v_2).normalized())
		
		vn[idx_0] += normal * a_0
		vn[idx_1] += normal * a_1
		vn[idx_2] += normal * a_2
		
		base_idx += 3
	
	for i in vn.size():
		vn[i] = vn[i].normalized()
	return vn

func _gen_mesh_texcoords(vert_array : PoolVector3Array, norm_array : PoolVector3Array) -> PoolVector2Array:
	var vt : PoolVector2Array = []
	vt.resize(vert_array.size())
	for i in vert_array.size():
		var texc := Vector2.ZERO
		
		var vrt := vert_array[i]
		var nrm := norm_array[i]
		
		var axis := abs(nrm.dot(Vector3.UP))
		var rot := Transform.IDENTITY
		if axis <= 0.5:
			rot = rot.looking_at(nrm, Vector3.DOWN).inverse()
		else:
			rot = rot.looking_at(nrm, Vector3.BACK).inverse()
		var vec := rot.basis.xform(vrt)
		texc.x = vec.x
		texc.y = vec.y
		
		vt[i] = texc * 0.5
	return vt

func tesselate_iterate(vert_array : PoolVector3Array, index_array : PoolIntArray, loops : int) -> Array:
	var vp : PoolVector3Array = vert_array
	var id : PoolIntArray = index_array
	
	for i in loops:
		var tmp := _tesselate(vp, id)
		vp = tmp[0]
		id = tmp[1]
	
	return [vp, id]

func _tesselate(vert_array : PoolVector3Array, index_array : PoolIntArray) -> Array:
	var vp : PoolVector3Array = vert_array
	var id : PoolIntArray = []
	
	var verts := {}
	
	var base_idx := 0
	while base_idx < index_array.size():
		var idx_0 := index_array[base_idx+0]
		var idx_1 := index_array[base_idx+1]
		var idx_2 := index_array[base_idx+2]
		
		var v_0 := vert_array[idx_0]
		var v_1 := vert_array[idx_1]
		var v_2 := vert_array[idx_2]
		
		var nv_0 : Vector3 = lerp(v_0, v_1, 0.5)
		var nv_1 : Vector3 = lerp(v_1, v_2, 0.5)
		var nv_2 : Vector3 = lerp(v_2, v_0, 0.5)
		
		var tmp_v : PoolVector3Array = [nv_0, nv_1, nv_2]
		var v_id : PoolIntArray = []
		for i in 3:
			var v := tmp_v[i]
			if !verts.has(v):
				verts[v] = vp.size()
				vp.push_back(v)
			v_id.push_back(verts[v])
		var tmp_id : PoolIntArray = [idx_0,v_id[0],v_id[2],  v_id[0],idx_1,v_id[1],  v_id[2],v_id[1],idx_2, v_id[0],v_id[1],v_id[2]]
		
		id.append_array(tmp_id)
		
		base_idx += 3
	
	return [vp, id]

func _get_poly_wall(line : Level_Line, subdivide := false) -> Array:
	var vp_arr : PoolVector3Array = []
	var id_arr : PoolIntArray = []
	
	if line == null:
		return [vp_arr, id_arr]
	
	var vp := Vector3.ZERO
	
	var sp := Vector3(line.vert_start.x, room_floor, line.vert_start.y)
	var gp := Vector3(line.vert_end.x, room_floor + room_height, line.vert_end.y)
	
	var res_x := 1
	var res_y := 1
	
	if subdivide:
		res_x = int(floor(line.vert_start.distance_to(line.vert_end) * 0.5))
		res_y = int(floor(room_height * 0.5))
	
	var subd_x = int(max(1, res_x)) + 1
	var subd_y = int(max(1, res_y)) + 1
	
	for y in subd_y:
		var fy = float(y) * (1.0 / float(subd_y-1))
		vp.y = lerp(sp.y, gp.y, fy)
		for x in subd_x:
			var fx = float(x) * (1.0 / float(subd_x-1))
			vp.x = lerp(sp.x, gp.x, fx)
			vp.z = lerp(sp.z, gp.z, fx)
			
			vp_arr.push_back(vp)
	
	for y in subd_y - 1:
		for x in subd_x - 1:
			id_arr.push_back(x + (y * subd_x))
			id_arr.push_back(x + (y * subd_x) + subd_x)
			id_arr.push_back(x + (y * subd_x) + subd_x + 1)
			
			id_arr.push_back(x + (y * subd_x))
			id_arr.push_back(x + (y * subd_x) + subd_x + 1)
			id_arr.push_back(x + (y * subd_x) + 1)
	return [vp_arr, id_arr]

func get_poly_array() -> PoolVector2Array:
	var room_points : PoolVector2Array = []
	
	for line in room_lines:
		var has_point_0 := false
		var has_point_1 := false
		
		for point in room_points:
			if has_point_0:
				break
			has_point_0 = point == line.vert_start
		
		for point in room_points:
			if has_point_1:
				break
			has_point_1 = point == line.vert_end
		
		if !has_point_0:
			room_points.push_back(line.vert_start)
		if !has_point_1:
			room_points.push_back(line.vert_end)
	if room_points.size() >= 3:
		room_points = _order_polygon(room_points)
		room_points = _gen_hull_2(room_points)
	return room_points

func _gen_hull_2(points : PoolVector2Array) -> PoolVector2Array:
	var lower : PoolVector2Array = []
	for point in points:
		while lower.size() >= 2 && (lower[lower.size()-1] - lower[lower.size()-2]).cross(point - lower[lower.size()-2]) <= 0:
			lower.remove(lower.size()-1)
		lower.push_back(point)
	
	points.invert()
	var upper : PoolVector2Array = []
	for point in points:
		while upper.size() >= 2 && (upper[upper.size()-1] - upper[upper.size()-2]).cross(point - upper[upper.size()-2]) <= 0:
			upper.remove(upper.size()-1)
		upper.push_back(point)
	
	lower.remove(lower.size()-1)
	upper.remove(upper.size()-1)
	return lower + upper

func _gen_hull(points : PoolVector2Array) -> PoolVector2Array:
	var hull : PoolVector2Array = _find_hull_verts(points, 1)
	return hull

func _find_hull_verts(points : PoolVector2Array, curr : int) -> PoolVector2Array:
	var hull := points
	if curr == 0:
		return hull
	var n := hull.size()
	var prev := posmod(curr-1, n)
	var next := posmod(curr+1, n)
	
	if _is_clockwise(hull[prev], hull[curr], hull[next]) != 2:
		hull.remove(curr)
		hull = _find_hull_verts(hull, prev)
	else:
		hull = _find_hull_verts(hull, next)
	
	return hull

func _order_polygon(points : PoolVector2Array) -> PoolVector2Array:
	var n := points.size()
	var min_idx := 0
	var min_len := points[min_idx].length()
	for i in range(1, n):
		var point := points[i]
		var dp := point.dot(Vector2.ONE)
		if min_len > dp:
			min_len = dp
			min_idx = i
	var cached_array : PoolVector2Array = [points[min_idx]]
	points.remove(min_idx)
	cached_array += points
	var ordered : PoolVector2Array = []
	
	for i in n:
		var j := ordered.size() - 1
		if i == 0 || _compare(cached_array[i], ordered[j], cached_array[0]):
			ordered.push_back(cached_array[i])
		else:
			var k := 0
			while k < ordered.size():
				if !_compare(cached_array[i], ordered[k], cached_array[0]):
					var _err := ordered.insert(k, cached_array[i])
					break
				k += 1
	return ordered

func _compare(a : Vector2, b : Vector2, center : Vector2) -> bool:
	var o := _is_clockwise(a, b, center)
	if o == 0:
		if center.distance_squared_to(b) >= center.distance_squared_to(a):
			return false
		else:
			return true
	else:
		if o == 2:
			return false
		else:
			return true

func _is_clockwise(a : Vector2, b : Vector2, center : Vector2) -> int:
	var angle := (b - center).cross(a - center)
	if is_zero_approx(angle):
		return 0 # Collinear.
	elif angle > 0.0:
		return 1 # Clock-Wise?
	else:
		return 2 # Counter-Clock-Wise?
