obs = obslua

description = [[
This script provides a filter that hides its applied source from the program.
This will be useful if you want to display something on the preview but not on the program.
<p/>
This filter will do these things.
<nl>
<li>- Overwrite rendering function so that nothing will be rendered if it is active.</li>
<li>- Hide an associated scene item.
<p/>Info: If you enable "Duplicate Scene" on the transition settings,
the source will be hidden from the program but still shown on the preview.
</li>
</nl>
<p/>
Known issue: If there are two or more scene-items showing the same source,
this filter cannot change the visibilities of all the scene-items.
]]

function script_description()
	return '<h3>Hide the source when it goes to live</h3>' .. description
end

filter_info = {}
filter_info.id = 'hide-from-program'
filter_info.type = obs.OBS_SOURCE_TYPE_FILTER
filter_info.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO, obs.OBS_SOURCE_CUSTOM_DRAW)

filter_info.get_name = function()
	return 'Hide from Program'
end

filter_info.create = function(settings, source)
	local f = {}
	f.source = source
	f.on_active = false
	return f
end

filter_info.destroy = function(f)
	f = nil
end

function remove_from_scene(f, src)
	local target = obs.obs_filter_get_target(f.source)

	local scene = obs.obs_scene_from_source(src)
	local item = obs.obs_scene_sceneitem_from_source(scene, target)
	obs.obs_sceneitem_set_visible(item, false)
	obs.obs_sceneitem_release(item)
end

function remove_from_scene_if_copied(f, scene)
	local c = obs.obs_frontend_get_current_scene()
	if c ~= scene then
		remove_from_scene(f, scene)
	end
	obs.obs_source_release(c)
end

function remove_from_program(f)
	local tran = obs.obs_get_output_source(0)
	local src = obs.obs_transition_get_source(tran, obs.OBS_TRANSITION_SOURCE_A)
	if src then
		remove_from_scene_if_copied(f, src)
		obs.obs_source_release(src)
	end
	local src = obs.obs_transition_get_source(tran, obs.OBS_TRANSITION_SOURCE_B)
	if src then
		remove_from_scene_if_copied(f, src)
		obs.obs_source_release(src)
	end
	obs.obs_source_release(tran)
end

filter_info.video_tick = function(f, second)
	local target = obs.obs_filter_get_target(f.source)

	f.width = obs.obs_source_get_base_width(target)
	f.height = obs.obs_source_get_base_height(target)

	if obs.obs_source_active(target) then
		remove_from_program(f)
	end
end

filter_info.get_width = function(f)
	return f.width
end

filter_info.get_height = function(f)
	return f.height
end

filter_info.video_render = function(f)
	local target = obs.obs_filter_get_target(f.source)
	if obs.obs_source_active(target) then
		return
	end
	obs.obs_source_skip_video_filter(f.source)
end

function script_load(settings)
	obs.obs_register_source(filter_info)
end
