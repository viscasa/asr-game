shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 fire_color_inner : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform vec4 fire_color_outer : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform vec4 fire_color_edge : source_color = vec4(0.8, 0.1, 0.0, 1.0);
uniform float fire_speed : hint_range(0.1, 5.0) = 2.0;
uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.3;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 3.0;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.15;

// Simplex 3D Noise
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289_4(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289_4(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * snoise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    
    // Pulse effect
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength;
    
    // Create noise untuk distorsi api
    vec3 noise_coord = vec3(uv * noise_scale, TIME * fire_speed);
    float noise1 = fbm(noise_coord);
    float noise2 = fbm(noise_coord + vec3(5.2, 1.3, 2.8));
    
    // Distorsi berdasarkan noise
    vec2 distorted_uv = uv + vec2(noise1, noise2) * distortion_strength;
    float distorted_dist = length(distorted_uv);
    
    // Fire shape dengan noise
    float fire_shape = 1.0 - smoothstep(0.0, 0.8 * pulse, distorted_dist);
    fire_shape *= 1.0 + noise1 * 0.5;
    
    // Flicker effect
    float flicker = 0.9 + 0.1 * sin(TIME * 15.0 + noise1 * 10.0);
    
    // Color gradient berdasarkan jarak dari center
    vec3 color = mix(fire_color_inner.rgb, fire_color_outer.rgb, smoothstep(0.0, 0.5, distorted_dist));
    color = mix(color, fire_color_edge.rgb, smoothstep(0.4, 0.8, distorted_dist));
    
    // Tambah brightness di tengah
    float core_glow = 1.0 - smoothstep(0.0, 0.3, dist);
    color += vec3(1.0, 1.0, 0.8) * core_glow * 0.5;
    
    // Apply flicker
    color *= flicker;
    
    // Alpha berdasarkan fire shape
    float alpha = fire_shape * smoothstep(1.0, 0.7, dist);
    alpha = clamp(alpha, 0.0, 1.0);
    
    // Soft edge
    alpha *= smoothstep(1.0, 1.0 - edge_softness, dist);
    
    ALBEDO = color;
    ALPHA = alpha;
    
    // Emission untuk glow effect
    EMISSION = color * 2.0 * fire_shape;
}
