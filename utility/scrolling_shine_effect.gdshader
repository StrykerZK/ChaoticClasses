shader_type canvas_item;

uniform bool shine_active = false; // Toggle effect
uniform float time_speed = 3.0; // Speed of shine
uniform vec4 sheen_color = vec4(1.0, 1.0, 1.0, 1.0); // Shine color
uniform float sheen_width = 1.5; // Width of the shine
uniform float sheen_progress = 0.0; // Progress from 0 to 1
uniform float sheen_intensity = 1.0; // How strong the effect is

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);

    if (shine_active) {
        // Move sheen from fully left (-0.5) to fully right (1.5)
        float sheen_pos = mix(-0.5, 1.5, sheen_progress);
        float distance_from_sheen = abs(uv.x + uv.y - sheen_pos);

        // Create a sharper, more defined sheen
        float sheen = smoothstep(sheen_width, 0.0, distance_from_sheen);

        // Blend it properly to avoid over-brightening
        vec4 shine_effect = mix(tex_color, sheen_color, sheen * sheen_intensity * tex_color.a);
        COLOR = shine_effect;
    } else {
        COLOR = tex_color;
    }
}
