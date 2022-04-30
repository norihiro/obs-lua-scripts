obs = obslua

max_sources = 16
n_sources = 1
source_name_array = {}
bounds_type_array = {}
blending_type_array = {}
hotkey_array = {}

function force_duplicate(source, new_name)
	local src_id = obs.obs_source_get_id(source)
	local settings = obs.obs_source_get_settings(source)
	local new_source = obs.obs_source_create(src_id, new_name, settings, nil)
	obs.obs_data_release(settings)
	-- TODO: apply other settings
	return new_source
end

function duplicate_source(source, name, force)
	i = 1
	local new_source = nil
	while new_source == nil do
		new_name = name.." "..i
		local existance = obs.obs_get_source_by_name(new_name)
		if existance == nil then
			if force then
				new_source = force_duplicate(source, new_name)
			else
				new_source = obs.obs_source_duplicate(source, new_name, false)
			end
		else
			obs.obs_source_release(existance)
		end
		i = i + 1
	end
	return new_source
end

function add_source_to_scene(scene_source, source_name, bounds_type, blending_type)
	local scene = obs.obs_scene_from_source(scene_source)
	if scene == nil then
		print("Error: obs_scene_from_souce: Failed to get the current scene.")
		obs.obs_source_release(scene_source)
		return
	end

	local source = obs.obs_get_source_by_name(source_name)
	if source == nil then
		print("Error: The source '" .. source_name .. "' is not found.")
		return
	end

	-- When media source is active, duplicate it so that the video start from the beginning.
	local source_id = obs.obs_source_get_unversioned_id(source)
	local is_media_src = source_id == "ffmpeg_source" or source_id == "vlc_source"
	if is_media_src and obs.obs_source_active(source) then
		local new_source = duplicate_source(source, source_name, is_media_src)
		if new_source then
			obs.obs_source_release(source)
			source = new_source
		end
	end

	local pos = obs.vec2()
	pos.x = obs.obs_source_get_width(scene_source)
	pos.y = obs.obs_source_get_height(scene_source)

	obs.obs_enter_graphics();
	local item = obs.obs_scene_add(scene, source)
	if bounds_type ~= nil and bounds_type ~= obs.OBS_BOUNDS_NONE then
		obs.obs_sceneitem_set_bounds_type(item, bounds_type)
		obs.obs_sceneitem_set_bounds(item, pos)
	end
	if blending_type ~= nil then
		obs.obs_sceneitem_set_blending_mode(item, blending_type)
	end
	pos.x = pos.x / 2
	pos.y = pos.y / 2
	obs.obs_sceneitem_set_pos(item, pos)
	obs.obs_sceneitem_set_alignment(item, 0)
	obs.obs_leave_graphics();

	obs.obs_source_release(source)
end

function create_source_centre(ix)
	print("create_source_centre(ix="..ix..")")
	if #(source_name_array) < ix or source_name_array[ix] == nil then
		print("Error: source name for "..ix.." is not defined.")
		return
	end

	local scene_source = obs.obs_frontend_get_current_scene()
	if scene_source == nil then
		print("Error: There is no current scene.")
		return
	end

	add_source_to_scene(
		scene_source,
		source_name_array[ix],
		bounds_type_array[ix],
		blending_type_array[ix] )

	obs.obs_source_release(scene_source)
end

function prop_source_init(prop)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local name = obs.obs_source_get_name(source)
			obs.obs_property_list_add_string(prop, name, name)
		end
	end
	obs.source_list_release(sources)
end

function get_group_name(ix)
	return "source_"..ix.."_group"
end

function get_hotkey_name(ix)
	return "create_source.source_"..ix.."_hotkey"
end

function prop_source_create(props, ix)
	local group = obs.obs_properties_create()
	obs.obs_properties_add_group(props, get_group_name(ix), "Source "..ix, obs.OBS_GROUP_NORMAL, group)
	local p = obs.obs_properties_add_list(group, "source_"..ix, "Source name", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	prop_source_init(p)

	local p = obs.obs_properties_add_list(group, "bounds_type_"..ix, "Bounds type", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
	obs.obs_property_list_add_int(p, "None", obs.OBS_BOUNDS_NONE)
	obs.obs_property_list_add_int(p, "Stretch", obs.OBS_BOUNDS_STRETCH)
	obs.obs_property_list_add_int(p, "Scale inner", obs.OBS_BOUNDS_SCALE_INNER)
	obs.obs_property_list_add_int(p, "Scale outer", obs.OBS_BOUNDS_SCALE_OUTER)
	obs.obs_property_list_add_int(p, "Scale to width", obs.OBS_BOUNDS_SCALE_TO_WIDTH)
	obs.obs_property_list_add_int(p, "Scale to height", obs.OBS_BOUNDS_SCALE_TO_HEIGHT)
	obs.obs_property_list_add_int(p, "Max only", obs.OBS_BOUNDS_MAX_ONLY)

	local p = obs.obs_properties_add_list(group, "blending_type_"..ix, "Blending type", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
	obs.obs_property_list_add_int(p, "Normal", obs.OBS_BLEND_NORMAL)
	obs.obs_property_list_add_int(p, "Additive", obs.OBS_BLEND_ADDITIVE)
	obs.obs_property_list_add_int(p, "Subtract", obs.OBS_BLEND_SUBTRACT)
	obs.obs_property_list_add_int(p, "Screen", obs.OBS_BLEND_SCREEN)
	obs.obs_property_list_add_int(p, "Multiply", obs.OBS_BLEND_MULTIPLY)
	obs.obs_property_list_add_int(p, "Lighten", obs.OBS_BLEND_LIGHTEN)
	obs.obs_property_list_add_int(p, "Darken", obs.OBS_BLEND_DARKEN)

end

function n_sources_changed(props, prop, settings)
	local n = n_sources -- obs.obs_data_get_int(settings, "n_sources")
	for i = 1, n, 1 do
		local p = obs.obs_properties_get(props, get_group_name(i))
		if p == nil then
			prop_source_create(props, i)
		end
	end
	for i = n+1, max_sources, 1 do
		obs.obs_properties_remove_by_name(props, get_group_name(i))
	end
	return true
end

function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_int(props, "n_sources", "Number of sources", 1, max_sources, 1)
	obs.obs_property_set_modified_callback(p, n_sources_changed)
	n_sources_changed(props, p, nil)

	return props
end

function script_description()
	return "Add specified source to current scene.\n\nHotkey 'Add Source' is available on Settings."
end

function register_hotkey(ix, settings)
	hotkey_array[ix] = obs.obs_hotkey_register_frontend(get_hotkey_name(ix), "Add Source "..ix,
		(function(pressed) if not pressed then return end create_source_centre(ix) end) )
	local hk = obs.obs_data_get_array(settings, get_hotkey_name(ix))
	obs.obs_hotkey_load(hotkey_array[ix], hk)
	obs.obs_data_array_release(hk)
end

function script_update(settings)
	n_sources = obs.obs_data_get_int(settings, "n_sources")
	for ix = 1, n_sources, 1 do
		source_name_array[ix] = obs.obs_data_get_string(settings, "source_"..ix)
		bounds_type_array[ix] = obs.obs_data_get_int(settings, "bounds_type_"..ix)
		blending_type_array[ix] = obs.obs_data_get_int(settings, "blending_type_"..ix)
		if #(hotkey_array) < ix or hotkey_array[ix] == nil or hotkey_array[ix] == obs.OBS_INVALID_HOTKEY_ID then
			register_hotkey(ix, settings)
		end
	end
end

function script_save(settings)
	for ix = 1, n_sources, 1 do
		if ix <= #(hotkey_array) and hotkey_array[ix] ~= nil and hotkey_array[ix] ~= obs.OBS_INVALID_HOTKEY_ID then
			local hk = obs.obs_hotkey_save(hotkey_array[ix])
			obs.obs_data_set_array(settings, get_hotkey_name(ix), hk)
			obs.obs_data_array_release(hk)
		end
	end
end
