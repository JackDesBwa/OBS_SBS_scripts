-- SbsAdjust Filter
-- This Lua script for OBS (Open Broadcaster Software) adds an effect
-- filter that can be applied to make some adjustments on a
-- side-by-side image, like changing the window placement, fixing
-- vertical mislignment and cropping.
-- It is distributed under the MIT License

obs = obslua

EFFECT = [[
#define SamplerState sampler_state
#define Texture2D texture2d

uniform float4x4 ViewProj;
uniform Texture2D image;

uniform float window_position;
uniform bool window_crop;
uniform float vertical_align;
uniform float zoom;
uniform float hpos;
uniform float vpos;

SamplerState sampler {
  Filter    = Linear;
  AddressU  = Clamp;
  AddressV  = Clamp;
};

struct vertex_data {
  float4 pos : POSITION;
  float2 uv  : TEXCOORD0;
};

struct pixel_data {
  float4 pos : POSITION;
  float2 uv  : TEXCOORD0;
};

pixel_data vertex_shader(vertex_data vertex) {
  pixel_data pixel;
  pixel.pos = mul(float4(vertex.pos.xyz, 1.0), ViewProj);
  pixel.uv  = vertex.uv;
  return pixel;
}

float4 pixel_shader(pixel_data pixel) : TARGET {
  bool lr = pixel.uv.x < 0.5;
  float x = (mod(pixel.uv.x, 0.5) * 2 - 0.5) / zoom - hpos;
  float y = (pixel.uv.y - 0.5) / zoom - vpos;
  if (lr) {
    x = x + window_position;
    y = y + vertical_align;
  } else {
    x = x - window_position;
    y = y - vertical_align;
  }
  x = x + 0.5;
  y = y + 0.5;

  bool vxor = (lr && vertical_align > 0) || (!lr && vertical_align < 0);
  if (
    (x < 0) || (y < 0) || (x > 1) || (y > 1) ||
    ((x < window_position * 2) && lr && window_crop) || ((x > 1 - window_position * 2) && !lr && window_crop) ||
    ((y < abs(vertical_align) * 2) && vxor) || ((y > 1 - abs(vertical_align) * 2) && !vxor)
  ) return vec4(0, 0, 0, 0);
  if (!lr) x = x + 1;
  return image.Sample(sampler, vec2(x/2, y));
}

technique Draw {
  pass {
    vertex_shader = vertex_shader(vertex);
    pixel_shader  = pixel_shader(pixel);
  }
}
]]

source_info = {}
source_info.id = 'filter-sbsadjust'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER
source_info.output_flags = obs.OBS_SOURCE_VIDEO

source_info.get_name = function()
  return "SBS Adjust"
end

source_info.create = function(settings, source)
  local data = {}
  data.source = source
  data.width = 1
  data.height = 1

  obs.obs_enter_graphics()
  data.effect = obs.gs_effect_create(EFFECT, "sbsadjust_effect_code", nil)
  obs.obs_leave_graphics()

  if data.effect == nil then
    obs.blog(obs.LOG_ERROR, "Effect compilation failed")
    source_info.destroy(data)
    return nil
  end

  data.uniforms = {}
  data.uniforms.window_position = obs.gs_effect_get_param_by_name(data.effect, "window_position")
  data.uniforms.window_crop = obs.gs_effect_get_param_by_name(data.effect, "window_crop")
  data.uniforms.vertical_align = obs.gs_effect_get_param_by_name(data.effect, "vertical_align")
  data.uniforms.zoom = obs.gs_effect_get_param_by_name(data.effect, "zoom")
  data.uniforms.hpos = obs.gs_effect_get_param_by_name(data.effect, "hpos")
  data.uniforms.vpos = obs.gs_effect_get_param_by_name(data.effect, "vpos")
  source_info.update(data, settings)

  return data
end

source_info.destroy = function(data)
  if data.effect ~= nil then
    obs.obs_enter_graphics()
    obs.gs_effect_destroy(data.effect)
    data.effect = nil
    obs.obs_leave_graphics()
  end
end

source_info.get_width = function(data)
  return data.width
end

source_info.get_height = function(data)
  return data.height
end

source_info.video_render = function(data)
  local parent = obs.obs_filter_get_parent(data.source)
  data.width = obs.obs_source_get_base_width(parent)
  data.height = obs.obs_source_get_base_height(parent)

  obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
  obs.gs_effect_set_float(data.uniforms.window_position, data.window_position)
  obs.gs_effect_set_bool(data.uniforms.window_crop, data.window_crop)
  obs.gs_effect_set_float(data.uniforms.vertical_align, data.vertical_align)
  obs.gs_effect_set_float(data.uniforms.zoom, data.zoom)
  obs.gs_effect_set_float(data.uniforms.hpos, data.hpos)
  obs.gs_effect_set_float(data.uniforms.vpos, data.vpos)
  obs.obs_source_process_filter_end(data.source, data.effect, data.width, data.height)
end

source_info.get_defaults = function(settings)
  obs.obs_data_set_default_double(settings, "window_position", 0)
  obs.obs_data_set_default_bool(settings, "window_crop", true)
  obs.obs_data_set_default_double(settings, "vertical_align", 0)
  obs.obs_data_set_default_double(settings, "zoom", 1)
  obs.obs_data_set_default_double(settings, "hpos", 0)
  obs.obs_data_set_default_double(settings, "vpos", 0)
end

source_info.get_properties = function(data)
  local props = obs.obs_properties_create()
  obs.obs_properties_add_float_slider(props, "window_position", "Window", -1, 1, 0.001)
  obs.obs_properties_add_bool(props, "window_crop", "Crop window")
  obs.obs_properties_add_float_slider(props, "vertical_align", "Vertical alignment", -1, 1, 0.001)
  obs.obs_properties_add_float_slider(props, "zoom", "Zoom", 1, 5, 0.01)
  obs.obs_properties_add_float_slider(props, "hpos", "H. position", -1, 1, 0.001)
  obs.obs_properties_add_float_slider(props, "vpos", "V. position", -1, 1, 0.001)
  return props
end

source_info.update = function(data, settings)
  data.window_position = obs.obs_data_get_double(settings, "window_position")
  data.window_crop = obs.obs_data_get_bool(settings, "window_crop")
  data.vertical_align = obs.obs_data_get_double(settings, "vertical_align")
  data.zoom = obs.obs_data_get_double(settings, "zoom")
  data.hpos = obs.obs_data_get_double(settings, "hpos")
  data.vpos = obs.obs_data_get_double(settings, "vpos")
end

function script_description()
  return [[<h2>SbsAdjust Filter</h2>
  <p>This Lua script adds an effect filter that can be applied to make
  some adjustments on a side-by-side image, like changing the window
  placement, fixing vertical mislignment and cropping.</p>]]
end

function script_load(settings)
  obs.obs_register_source(source_info)
end
