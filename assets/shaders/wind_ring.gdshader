shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 wind_color : source_color = vec4(0.8, 0.9, 1.0, 0.6);
uniform vec4 wind_color_edge : source_color = vec4(0.6, 0.8, 1.0, 0.3);
uniform float ring_thickness : hint_range(0.01, 0.5) = 0.15;
uniform float swirl_speed : hint_range(0.0, 20.0) = 8.0;
uniform float swirl_amount : hint_range(0.0, 1.0) = 0.3;
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;
uniform float fade_power : hint_range(0.5, 5.0) = 2.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    
    // Angle untuk swirl effect
    float angle = atan(uv.y, uv.x);
    
    // Swirl distortion
    float swirl = noise(vec2(angle * 3.0 + TIME * swirl_speed, dist * noise_scale)) * swirl_amount;
    float distorted_dist = dist + swirl * 0.1;
    
    // Ring shape - dari luar
    float ring_outer = 1.0;
    float ring_inner = 1.0 - ring_thickness;
    
    float ring = smoothstep(ring_outer, ring_outer - 0.05, distorted_dist) * 
                 smoothstep(ring_inner - 0.05, ring_inner, distorted_dist);
    
    // Wind streaks
    float streaks = noise(vec2(angle * 10.0 + TIME * swirl_speed * 2.0, dist * 5.0));
    streaks = smoothstep(0.4, 0.6, streaks);
    
    // Combine ring dengan streaks
    float final_ring = ring * (0.7 + streaks * 0.3);
    
    // Color gradient
    vec3 color = mix(wind_color_edge.rgb, wind_color.rgb, ring);
    
    // Alpha dengan fade
    float alpha = final_ring * pow(1.0 - dist, fade_power) * wind_color.a;
    alpha = clamp(alpha, 0.0, 1.0);
    
    ALBEDO = color;
    ALPHA = alpha;
    EMISSION = color * 0.5;
}
