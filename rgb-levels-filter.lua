-- SPDX-License-Identifier: GPL-2.0-or-later
-- RGB levels filter
-- Shader part was originally made by Tony.
--   https://github.com/petrifiedpenguin/obs-rgb-levels-filter
-- Lua script part was originally made by khaver.
--   https://obsproject.com/forum/resources/color-curves.1540/
-- Integrated above parts by Norihiro Kamae

obs = obslua

source_info = {}
source_info.id = 'rgb_levels_filter'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER
source_info.output_flags = obs.OBS_SOURCE_VIDEO

function script_description()
	return [[A simple OBS Studio filter to adjust RGB levels.]]
end

function script_properties(settings)
	return nil
end

function set_render_size(filter)
	target = obs.obs_filter_get_target(filter.source)

	local width, height
	if target == nil then
		width = 0
		height = 0
	else
		width = obs.obs_source_get_base_width(target)
		height = obs.obs_source_get_base_height(target)
	end

	filter.width = width
	filter.height = height
end

function script_load(settings)
	obs.obs_register_source(source_info)
end

source_info.get_name = function()
	return "RGB Levels"
end

source_info.create = function(settings, source)
	local filter = {}
	filter.source = source
	set_render_size(filter)

	obs.obs_enter_graphics()

	filter.effect = obs.gs_effect_create(shader, nil, nil)

	if filter.effect ~= nil then
		filter.params = {}
		filter.params.min_r = obs.gs_effect_get_param_by_name(filter.effect, 'min_r')
		filter.params.min_g = obs.gs_effect_get_param_by_name(filter.effect, 'min_g')
		filter.params.min_b = obs.gs_effect_get_param_by_name(filter.effect, 'min_b')
		filter.params.scale_r = obs.gs_effect_get_param_by_name(filter.effect, 'scale_r')
		filter.params.scale_g = obs.gs_effect_get_param_by_name(filter.effect, 'scale_g')
		filter.params.scale_b = obs.gs_effect_get_param_by_name(filter.effect, 'scale_b')
	end

	obs.obs_leave_graphics()

	if filter.effect == nil then
		source_info.destroy(filter)
		return nil
	end

	source_info.update(filter, settings)
	return filter
end

source_info.destroy = function(filter)
	if filter.effect ~= nil then
		obs.obs_enter_graphics()
		obs.gs_effect_destroy(filter.effect)
		obs.obs_leave_graphics()
	end
	filter = nil
end

source_info.get_width = function(filter)
	return filter.width
end

source_info.get_height = function(filter)
	return filter.height
end

source_info.get_properties = function(settings)
	props = obs.obs_properties_create()

	obs.obs_properties_add_float_slider(props, "min_r", "Red min", 0.0, 254.0, 1.0)
	obs.obs_properties_add_float_slider(props, "max_r", "Red max", 1.0, 255.0, 1.0)
	obs.obs_properties_add_float_slider(props, "min_g", "Green min", 0.0, 254.0, 1.0)
	obs.obs_properties_add_float_slider(props, "max_g", "Green max", 1.0, 255.0, 1.0)
	obs.obs_properties_add_float_slider(props, "min_b", "Blue min", 0.0, 254.0, 1.0)
	obs.obs_properties_add_float_slider(props, "max_b", "Blue max", 1.0, 255.0, 1.0)

	return props
end

source_info.get_defaults = function(settings)
	obs.obs_data_set_default_double(settings, "min_r", 0.0)
	obs.obs_data_set_default_double(settings, "max_r", 255.0)
	obs.obs_data_set_default_double(settings, "min_g", 0.0)
	obs.obs_data_set_default_double(settings, "max_g", 255.0)
	obs.obs_data_set_default_double(settings, "min_b", 0.0)
	obs.obs_data_set_default_double(settings, "max_b", 255.0)
end

source_info.update = function(filter, settings)
	min_r = obs.obs_data_get_double(settings, "min_r")
	min_g = obs.obs_data_get_double(settings, "min_g")
	min_b = obs.obs_data_get_double(settings, "min_b")

	max_r = math.max(min_r + 1.0, obs.obs_data_get_double(settings, "max_r"))
	max_g = math.max(min_g + 1.0, obs.obs_data_get_double(settings, "max_g"))
	max_b = math.max(min_b + 1.0, obs.obs_data_get_double(settings, "max_b"))

	filter.min_r = min_r / 255.0
	filter.min_g = min_g / 255.0
	filter.min_b = min_b / 255.0
	filter.scale_r = 255.0 / (max_r - min_r)
	filter.scale_g = 255.0 / (max_g - min_g)
	filter.scale_b = 255.0 / (max_b - min_b)
end

source_info.video_render = function(filter)

	if not obs.obs_source_process_filter_begin(filter.source, obs.GS_RGBA, obs.OBS_ALLOW_DIRECT_RENDERING) then
		obs.obs_source_skip_video_filter(filter.source)
		return
	end

	obs.gs_effect_set_float(filter.params.min_r, filter.min_r)
	obs.gs_effect_set_float(filter.params.min_g, filter.min_g)
	obs.gs_effect_set_float(filter.params.min_b, filter.min_b)
	obs.gs_effect_set_float(filter.params.scale_r, filter.scale_r)
	obs.gs_effect_set_float(filter.params.scale_g, filter.scale_g)
	obs.gs_effect_set_float(filter.params.scale_b, filter.scale_b)

	obs.obs_source_process_filter_end(filter.source, filter.effect, filter.width, filter.height)
end

source_info.video_tick = function(filter, seconds)
	set_render_size(filter)
end

shader = [[
uniform float4x4 ViewProj;
uniform texture2d image;

uniform float min_r;
uniform float min_g;
uniform float min_b;
uniform float scale_r;
uniform float scale_g;
uniform float scale_b;

sampler_state textureSampler {
	Filter    = Linear;
	AddressU  = Clamp;
	AddressV  = Clamp;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

VertData VSDefault(VertData v_in)
{
	VertData vert_out;
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.uv  = v_in.uv;
	return vert_out;
}

float4 PSLevel(VertData v_in) : TARGET
{
	float4 rgba = image.Sample(textureSampler, v_in.uv);

	float3 leveled = saturate((rgba.rgb - float3(min_r, min_g, min_b)) * float3(scale_r, scale_g, scale_b));
	return float4(leveled, rgba.a);
}

technique Draw
{
	pass
	{
		vertex_shader = VSDefault(v_in);
		pixel_shader  = PSLevel(v_in);
	}
}
]]
