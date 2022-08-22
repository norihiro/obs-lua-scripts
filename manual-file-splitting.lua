obs       = obslua
hotkey_id = obs.OBS_INVALID_HOTKEY_ID

function manual_split()
	local split_file_enabled = obs.obs_frontend_recording_split_file();
	print("manual_split split_file_enabled="..tostring(split_file_enabled))
end

function manual_split_button(pressed)
	if not pressed then
		return
	end
	manual_split()
end

function manual_split_clicked(props, p)
	manual_split()
	return false
end

function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_button(props, "manual_split", "Manual split now", manual_split_clicked);
	return props
end

function script_description()
	return "Trigger obs_frontend_recording_split_file."
end

function script_save(settings)
	local hotkey_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "manual_split", hotkey_array)
	obs.obs_data_array_release(hotkey_array)
end

function script_load(settings)
	hotkey_id = obs.obs_hotkey_register_frontend("manual_split_key", "Manual split recording file", manual_split_button)
	local hotkey_array = obs.obs_data_get_array(settings, "manual_split")
	obs.obs_hotkey_load(hotkey_id, hotkey_array)
	obs.obs_data_array_release(hotkey_array)
end
