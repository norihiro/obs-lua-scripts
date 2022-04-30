obs           = obslua
source_name   = ""
hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

function create_mediasource_centre()
	local scene_source = obs.obs_frontend_get_current_scene()
	if scene_source == nil then
		print("Error: There is no current scene.")
		return
	end

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

	obs.obs_enter_graphics();
	local item = obs.obs_scene_add(scene, source)
	local pos = obs.vec2()
	pos.x = obs.obs_source_get_width(scene_source)/2
	pos.y = obs.obs_source_get_height(scene_source)/2
	obs.obs_sceneitem_set_pos(item, pos)
	obs.obs_sceneitem_set_alignment(item, 0)
	obs.obs_leave_graphics();

	obs.obs_source_release(source)
	obs.obs_source_release(scene_source)
end

function create_mediasource_centre_button(pressed)
	if not pressed then
		return
	end
	create_mediasource_centre()
end

function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Media Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "ffmpeg_source" or source_id == "vlc_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	return props
end

function script_description()
	return "Add specified media source to current scene.\n\nHotkey 'Add Media Source' is available on Settings."
end

function script_update(settings)
	source_name = obs.obs_data_get_string(settings, "source")
end

function script_save(settings)
	local hotkey_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "create_mediasource_centre", hotkey_array)
	obs.obs_data_array_release(hotkey_array)
end

function script_load(settings)
	hotkey_id = obs.obs_hotkey_register_frontend("create_mediasource_centre_key", "Add Media Source", create_mediasource_centre_button)
	local hotkey_array = obs.obs_data_get_array(settings, "create_mediasource_centre")
	obs.obs_hotkey_load(hotkey_id, hotkey_array)
	obs.obs_data_array_release(hotkey_array)
end
