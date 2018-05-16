shader_type canvas_item;

uniform bool depth_on;

uniform float wave_speed : hint_range(0.1, 10);
uniform float refraction_strength : hint_range(0.0, 0.6);
uniform float wave_density : hint_range(0.1, 10);
uniform float wave_sway : hint_range(0.0, 14.5); 

uniform sampler2D normal_texture;
uniform float normal_offset : hint_range(0.0, 1.0); // a value of 0.45 seems to work well for this

uniform float highlight_size : hint_range(0.0, 0.25);
uniform float highlight_strength : hint_range(0.0, 1.0);
uniform float shadow_size : hint_range(-0.25, 0.25);
uniform float shadow_strength : hint_range(0.0, 1.0);

uniform vec3 sun_direction;

vec4 getFlow(vec4 flow_uv, float time) {
	// dampen the effects
	//flow_uv *= 0.5;
	
	// reverse x to get waves going to right direction
	//flow_uv.x = -flow_uv.x;
	float adjusted_sway = 15.0 - wave_sway;
	flow_uv -= 0.5;
	//flow_uv *= 0.1;
	
	vec4 dual_flow = vec4(flow_uv.xy, flow_uv.xy);
	
	if (abs(dual_flow.x) > 0.05) {
		// we have x movement, so add some y variance to create waves
		dual_flow.y += dual_flow.x / adjusted_sway;
		dual_flow.a -= dual_flow.x / adjusted_sway;
	}
	
	if (abs(dual_flow.y) > 0.05) {
		// we have y movement, so add some x variance to create waves
		dual_flow.x += dual_flow.y / adjusted_sway;
		dual_flow.z -= dual_flow.y / adjusted_sway;
	}
	
	if (abs(dual_flow.x) < 0.05 && abs(dual_flow.y) < 0.05) {
		// simulate some slight water motion for calm water
		dual_flow.x = 0.02;
		dual_flow.z = -0.02;
		
		dual_flow.y = 0.02;
		dual_flow.z = -0.02;
	}
	
	return dual_flow * time;
}

vec3 getNormal(vec2 coord, float wave_density_1, float wave_density_2, vec4 flow, float time) {
	// this is the waves moving under the texture
    vec2 textureOffset = vec2(time * 0.02, time * -0.01);
	textureOffset.xy = vec2(0.0, 0.0);
	
	//textureOffset *= flow.x;
    vec2 waveOne_uv = coord.xy + flow.xy + textureOffset;
	waveOne_uv *= wave_density_1;
    waveOne_uv = mod(waveOne_uv, 1.0);
	
    vec4 sampleOne = texture(normal_texture, waveOne_uv);
	//return sampleOne.xyz;
	//return vec3(flow.x, 0.0, 0.0);
	//sampleOne *= 0.0;
        
    //textureOffset = time * 0.01;
	//textureOffset *= flow.x;
    vec2 waveTwo_uv = coord.xy + flow.za;
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
		if (!depth_on) {
			depth.x = 0.0;
		}
		vec4 flow = texture(NORMAL_TEXTURE, UV); // Use this if the normal map is set to a flow map
		if (depth_on) {
			flow = vec4(0.5, 0.5, 0.5, 0.5);
		}
		vec4 flow_vec = getFlow(flow, TIME * wave_speed);
		vec3 normal = getNormal(UV, wave_density, wave_density * 1.3, flow_vec, TIME * wave_speed);
		vec2 tex_sample_offset = normal.xy - vec2(normal_offset, normal_offset);
		tex_sample_offset *= refraction_strength;
		//tex_sample_offset -= tex_sample_offset / 2.0;
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
		//COLOR = vec4(normal, 1);
		//COLOR = depth;
	} else {
		COLOR = vec4(TIME / 5.0, TIME / 5.0, TIME / 5.0, 0.0);
	}
}