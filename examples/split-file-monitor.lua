obs       = obslua
file_name = ""

function file_changed_cb(params)
	print(params)
	file_name = obs.calldata_string(params, "next_file")
	print(file_name)
end

function frontend_event_cb(event)
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		local r = obs.obs_frontend_get_recording_output()
		local d = obs.obs_output_get_settings(r)
		file_name = obs.obs_data_get_string(d, "path")
		print(file_name)
		obs.obs_data_release(d)

		obs.signal_handler_connect(obs.obs_output_get_signal_handler(r), "file_changed", file_changed_cb)

		obs.obs_output_release(r)
	end
end

function script_load(settings)
	obs.obs_frontend_add_event_callback(frontend_event_cb)
end
