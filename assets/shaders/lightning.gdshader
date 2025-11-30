shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 lightning_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 3.0;
uniform float flicker_speed : hint_range(0.0, 50.0) = 25.0;
uniform float branch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

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
    vec2 uv = UV;
    
    // Flicker effect
    float flicker = 0.7 + 0.3 * sin((TIME + time_offset) * flicker_speed);
    flicker *= 0.8 + 0.2 * sin((TIME + time_offset) * flicker_speed * 1.7);
    
    // Lightning bolt shape - centered on UV.x = 0.5
    float center_dist = abs(uv.x - 0.5);
    
    // Add jagged noise untuk efek petir
    float jagged = noise(vec2(uv.y * 20.0, (TIME + time_offset) * 10.0)) * 0.15;
    jagged += noise(vec2(uv.y * 40.0, (TIME + time_offset) * 15.0)) * 0.08;
    
    // Core bolt
    float bolt_width = 0.08 + jagged * branch_intensity;
    float bolt = 1.0 - smoothstep(0.0, bolt_width, center_dist);
    
    // Glow around bolt
    float glow_width = 0.25 + jagged * 0.5;
    float glow = 1.0 - smoothstep(0.0, glow_width, center_dist);
    glow = pow(glow, 2.0);
    
    // Branches
    float branch1_offset = noise(vec2(uv.y * 10.0, 1.0)) * 0.3 - 0.15;
    float branch1_dist = abs(uv.x - 0.5 - branch1_offset);
    float branch1 = (1.0 - smoothstep(0.0, 0.03, branch1_dist)) * step(0.3, uv.y) * step(uv.y, 0.7);
    
    float branch2_offset = noise(vec2(uv.y * 8.0, 2.0)) * 0.4 - 0.2;
    float branch2_dist = abs(uv.x - 0.5 - branch2_offset);
    float branch2 = (1.0 - smoothstep(0.0, 0.02, branch2_dist)) * step(0.5, uv.y) * step(uv.y, 0.85);
    
    float branches = (branch1 + branch2) * branch_intensity;
    
    // Combine
    float final_bolt = bolt + branches;
    float final_glow = glow;
    
    // Color
    vec3 color = mix(lightning_color.rgb, core_color.rgb, final_bolt);
    color += lightning_color.rgb * final_glow * glow_intensity * 0.5;
    
    // Apply flicker
    float alpha = (final_bolt + final_glow * 0.5) * flicker;
    alpha = clamp(alpha, 0.0, 1.0);
    
    ALBEDO = color * flicker;
    ALPHA = alpha;
    EMISSION = color * glow_intensity * flicker;
}
