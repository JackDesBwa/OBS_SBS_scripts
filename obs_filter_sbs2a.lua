-- Sbs2a Filter
-- This Lua script for OBS (Open Broadcaster Software) adds an effect
-- filter that can be applied to convert from side-by-side to anaglyph
-- presentation formats.
-- It is distributed under the MIT License

obs = obslua

EFFECT = [[
#define SamplerState sampler_state
#define Texture2D texture2d

uniform float4x4 ViewProj;
uniform Texture2D image;

uniform int matrix;
uniform bool half_width;
uniform bool swap;

float3x3 get_matrix(bool lr) {
  float3x3 m;
  if (matrix == 0) { // Gray GM
    m = lr ? float3x3( 0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114 );

  } else if (matrix == 1) { // Gray YB
    m = lr ? float3x3( 0.299, 0.587, 0.114,
                       0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114 );

  } else if (matrix == 2) { // Gray RC
    m = lr ? float3x3( 0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114,
                       0.299, 0.587, 0.114 );

  } else if (matrix == 3) { // HalfColors GM
    m = lr ? float3x3( 0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000 ) :
             float3x3( 1.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 1.000 );

  } else if (matrix == 4) { // HalfColors YB
    m = lr ? float3x3( 1.000, 0.000, 0.000,
                       0.000, 1.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.299, 0.587, 0.114 );

  } else if (matrix == 5) { // HalfColors RC
    m = lr ? float3x3( 0.299, 0.587, 0.114,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.000, 1.000, 0.000,
                       0.000, 0.000, 1.000 );

  } else if (matrix == 6) { // FullColors GM
    m = lr ? float3x3( 0.000, 0.000, 0.000,
                       0.000, 1.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 1.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 1.000 );

  } else if (matrix == 7) { // FullColors YB
    m = lr ? float3x3( 1.000, 0.000, 0.000,
                       0.000, 1.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 1.000 );

  } else if (matrix == 8) { // FullColors RC
    m = lr ? float3x3( 1.000, 0.000, 0.000,
                       0.000, 0.000, 0.000,
                       0.000, 0.000, 0.000 ) :
             float3x3( 0.000, 0.000, 0.000,
                       0.000, 1.000, 0.000,
                       0.000, 0.000, 1.000 );

  } else if (matrix == 9) { // Dubois GM
    m = lr ? float3x3( -0.062, -0.158, -0.039,
                       +0.284, +0.668, +0.143,
                       -0.015, -0.027, +0.021 ) :
             float3x3( +0.529, +0.705, +0.024,
                       -0.016, -0.015, -0.065,
                       +0.009, +0.075, +0.937 );

  } else if (matrix == 10) { // Dubois YB
    m = lr ? float3x3( +1.062, -0.205, +0.299,
                       -0.026, +0.908, +0.068,
                       -0.038, -0.173, +0.022 ) :
             float3x3( -0.016, -0.123, -0.017,
                       +0.006, +0.062, -0.017,
                       +0.094, +0.185, +0.911 );

  } else if (matrix == 11) { // Dubois RC
    m = lr ? float3x3( +0.456, +0.500, +0.176,
                       -0.040, -0.038, -0.016,
                       -0.015, -0.021, -0.005 ) :
             float3x3( -0.043, -0.088, -0.002,
                       +0.378, +0.734, -0.018,
                       -0.072, -0.113, +1.226 );
  }
  return transpose(m);
}

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
  float2 uv = float2(mod(pixel.uv.x, 0.5), pixel.uv.y);
  if (half_width) uv = float2(pixel.uv.x * 0.5, pixel.uv.y);

  float4 cl = image.Sample(sampler, uv);
  float4 cr = image.Sample(sampler, uv + float2(0.5, 0));

  if (swap) {
    float4 tmp = cl;
    cl = cr;
    cr = tmp;
  }

  float3x3 ml = get_matrix(true);
  float3x3 mr = get_matrix(false);
  float3 c = ml * cl.rgb + mr * cr.rgb;
  
  return float4(c, !half_width && pixel.uv.x > 0.5 ? 0. : 1.);
}

technique Draw {
  pass {
    vertex_shader = vertex_shader(vertex);
    pixel_shader  = pixel_shader(pixel);
  }
}
]]

source_info = {}
source_info.id = 'filter-sbs2a'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER
source_info.output_flags = obs.OBS_SOURCE_VIDEO

source_info.get_name = function()
  return "SBS => Anaglyph"
end

source_info.create = function(settings, source)
  local data = {}
  data.source = source
  data.width = 1
  data.height = 1

  obs.obs_enter_graphics()
  data.effect = obs.gs_effect_create(EFFECT, "sbs2a_effect_code", nil)
  obs.obs_leave_graphics()

  if data.effect == nil then
    obs.blog(obs.LOG_ERROR, "Effect compilation failed")
    source_info.destroy(data)
    return nil
  end

  data.uniforms = {}
  data.uniforms.matrix = obs.gs_effect_get_param_by_name(data.effect, "matrix")
  data.uniforms.half_width = obs.gs_effect_get_param_by_name(data.effect, "half_width")
  data.uniforms.swap = obs.gs_effect_get_param_by_name(data.effect, "swap")

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
  if data.half_width then
    return data.width
  end
  return data.width/2
end

source_info.get_height = function(data)
  return data.height
end

source_info.video_render = function(data)
  local parent = obs.obs_filter_get_parent(data.source)
  data.width = obs.obs_source_get_base_width(parent)
  data.height = obs.obs_source_get_base_height(parent)

  obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
  obs.gs_effect_set_int(data.uniforms.matrix, data.matrix)
  obs.gs_effect_set_bool(data.uniforms.half_width, data.half_width)
  obs.gs_effect_set_bool(data.uniforms.swap, data.swap)
  obs.obs_source_process_filter_end(data.source, data.effect, data.width, data.height)
end

source_info.get_defaults = function(settings)
  obs.obs_data_set_default_int(settings, "matrix", 5)
  obs.obs_data_set_default_bool(settings, "half_width", true)
  obs.obs_data_set_default_bool(settings, "swap", false)
end

source_info.get_properties = function(data)
  local props = obs.obs_properties_create()
  
  local matrices = obs.obs_properties_add_list(props, "matrix", "Matrix", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
  obs.obs_property_list_add_int(matrices, "Anaglyph Red/Cyan Gray", 2);
  obs.obs_property_list_add_int(matrices, "Anaglyph Red/Cyan Half Colors", 5);
  obs.obs_property_list_add_int(matrices, "Anaglyph Red/Cyan Full Colors", 8);
  obs.obs_property_list_add_int(matrices, "Anaglyph Red/Cyan Dubois", 11);
  obs.obs_property_list_add_int(matrices, "Anaglyph Yellow/Blue Gray", 1);
  obs.obs_property_list_add_int(matrices, "Anaglyph Yellow/Blue Half Colors", 4);
  obs.obs_property_list_add_int(matrices, "Anaglyph Yellow/Blue Full Colors", 7);
  obs.obs_property_list_add_int(matrices, "Anaglyph Yellow/Blue Dubois", 10);
  obs.obs_property_list_add_int(matrices, "Anaglyph Green/Magenta Gray", 0);
  obs.obs_property_list_add_int(matrices, "Anaglyph Green/Magenta Half Colors", 3);
  obs.obs_property_list_add_int(matrices, "Anaglyph Green/Magenta Full Colors", 6);
  obs.obs_property_list_add_int(matrices, "Anaglyph Green/Magenta Dubois", 9);
  
  obs.obs_properties_add_bool(props, "half_width", "Half width")
  obs.obs_properties_add_bool(props, "swap", "Swap")

  return props
end

source_info.update = function(data, settings)
  data.matrix = obs.obs_data_get_int(settings, "matrix")
  data.half_width = obs.obs_data_get_bool(settings, "half_width")
  data.swap = obs.obs_data_get_bool(settings, "swap")
end

function script_description()
  return [[<h2>Sbs2a Filter</h2>
  <p>This Lua script adds an effect filter that can be applied to
  convert from side-by-side to anaglyph presentation formats.</p>]]
end

function script_load(settings)
  obs.obs_register_source(source_info)
end
