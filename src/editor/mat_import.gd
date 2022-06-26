extends Node

var ed_materials := {}
var ed_path := "textures/textures.tres"

func _ready() -> void:
	reload_materials()
	print(ed_materials)

func reload_materials() -> void:
	ed_materials.clear()
	ed_materials = _load_all_materials(ed_path)

func _load_all_materials(path : String) -> Dictionary:
	if path.empty():
		return {}
	
	var _file := File.new()
	var err := _file.open(path, File.READ)
	if err != OK:
		_file.close()
		return {}
	
	var base_path := path.get_base_dir()
	var data := {}
	
	while !_file.eof_reached():
		var f_line := _file.get_line()
		if f_line.empty():
			continue
		
		var m_data := _load_texture_materials(base_path, f_line)
		for key in m_data.keys():
			if !data.has(key):
				data[key] = m_data[key]
	
	return data

func _load_texture_materials(base_path : String, cfg_name := "default.tres") -> Dictionary:
	if cfg_name.empty() || base_path.empty():
		return {}
	
	var data := {}
	var cfg := ConfigFile.new()
	var err := cfg.load(base_path + "/" + cfg_name)
	if err != OK:
		return {}
	for mat_name in cfg.get_sections():
		var mat := SpatialMaterial.new()
		var cfg_dif : String = cfg.get_value(mat_name, "albedo", "")
		var cfg_nrm : String = cfg.get_value(mat_name, "normal", "")
		var cfg_orm : String = cfg.get_value(mat_name, "orm", "")
		var cfg_r : float = cfg.get_value(mat_name, "r", 1.0)
		var cfg_m : float = cfg.get_value(mat_name, "m", 0.0)
		
		mat.roughness = cfg_r
		mat.metallic = cfg_m
		
		if !cfg_dif.empty():
			mat.albedo_texture = _check_and_load_tex(base_path, cfg_dif)
		if !cfg_nrm.empty():
			mat.normal_texture = _check_and_load_tex(base_path, cfg_nrm)
		if !cfg_orm.empty():
			var input := _check_and_load_tex(base_path, cfg_nrm)
			
			mat.ao_texture = input
			mat.roughness_texture = input
			mat.metallic_texture = input
			
			mat.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
			mat.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
			mat.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		data[mat_name] = mat
	return data

func _check_and_load_tex(base_tex_path : String, tex_name : String) -> Texture:
	var tex_result : Texture = null
	if !tex_name.empty():
		var tex_path := base_tex_path + "/" + tex_name
		if ResourceLoader.exists(tex_path, "Texture"):
			tex_result = ResourceLoader.load(tex_path, "Texture")
		else:
			print("ERROR: Texture at path [" + tex_path + "] does not exist!")
	return tex_result
