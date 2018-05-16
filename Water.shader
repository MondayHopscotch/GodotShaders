shader_type canvas_item;

uniform float wave_speed : hint_range(0.1, 10);
uniform float refraction_strength : hint_range(0.0, 0.6);
uniform float wave_density : hint_range(0.1, 10);

uniform sampler2D normal_texture;
uniform float highlight_size : hint_range(0.0, 0.25);
uniform float highlight_strength : hint_range(0.0, 1.0);
uniform float shadow_size : hint_range(-0.25, 0.25);
uniform float shadow_strength : hint_range(0.0, 1.0);

uniform vec3 sun_direction;

vec2 getFlow(vec4 flow_uv, float time) {
	flow_uv -= 0.5;
	flow_uv *= 0.1;
	
	return vec2(time * flow_uv.x, time * flow_uv.y);
}

vec3 getNormal(vec2 coord, float wave_density_1, float wave_density_2, vec2 flow, float time) {
	// this is the waves moving under the texture
    vec2 textureOffset = vec2(time * 0.02, time * -0.01);
	
	//textureOffset *= flow.x;
    vec2 waveOne_uv = coord.xy + flow + textureOffset;
	waveOne_uv *= wave_density_1;
    waveOne_uv = mod(waveOne_uv, 1.0);
	
    vec4 sampleOne = texture(normal_texture, waveOne_uv);
	//return sampleOne.xyz;
	//return vec3(flow.x, 0.0, 0.0);
	//sampleOne *= 0.0;
        
    //textureOffset = time * 0.01;
	//textureOffset *= flow.x;
    vec2 waveTwo_uv = coord.xy + flow;
	waveTwo_uv *= wave_density_2;
	waveTwo_uv = mod(waveTwo_uv, 1.0);
	
    vec4 sampleTwo = texture(normal_texture, waveTwo_uv);
    //sampleTwo *= 0.0;
	
	vec3 avg = sampleOne.xyz + sampleTwo.xyz;
	avg * 2.0;
	
	avg.xyz = normalize(avg);
    return avg;
}

void fragment () {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.0) {
		vec4 depth = texture(NORMAL_TEXTURE, UV); // Use this if the normal map is set to a depth map
		depth.x = 0.0;
		vec4 flow = texture(NORMAL_TEXTURE, UV); // Use this if the normal map is set to a flow map
		vec2 flow_vec = getFlow(flow, TIME * wave_speed);
		vec3 normal = getNormal(UV, wave_density, wave_density * 1.3, flow_vec, TIME * wave_speed);
		vec3 mod_normal = normal.xyz - vec3(0.5, 0.5, 0.5);
		vec2 tex_sample_offset = vec2(mod_normal.r * refraction_strength, mod_normal.g * refraction_strength);
		//tex_sample_offset -= length(tex_sample_offset) / 2.0;
		//tex_sample_offset /= tex_sample_offset / 2.0;
		float depth_modifier = 1.0 - (depth.x / 1.0);
		tex_sample_offset *= depth_modifier;
		vec2 sample_loc = UV - tex_sample_offset;
		COLOR = texture(TEXTURE, sample_loc);
		if (COLOR.a < 0.1) {
			sample_loc = UV - tex_sample_offset;
			COLOR = texture(TEXTURE, sample_loc);
		}
		vec3 sun_dir = normalize(sun_direction);
		float sun_value = dot(normal.xyz, sun_dir);
		if (sun_value > highlight_size) {
			// Sun reflection highlights
			COLOR.xyz += highlight_strength;
		} else if (sun_value < shadow_size) {
			// Shadow
			COLOR *= (1.0 - shadow_strength);
		} else {
			//COLOR = vec4(1, 0, 0, 1.0);
		}
		//COLOR = vec4(sun_value, sun_value, sun_value, 1.0);
		//COLOR = texture(TEXTURE, UV);
		COLOR = vec4(normal, 1);
		//COLOR = depth;
	} else {
		COLOR = vec4(TIME / 5.0, TIME / 5.0, TIME / 5.0, 0.0);
	}
}