shader_type canvas_item;
render_mode unshaded;

// HD-2D style screen pass: tilt-shift depth of field, bloom, chromatic
// aberration, colour grading, vignette, film grain and a flash overlay.
// Runs on a full-screen ColorRect placed above the world and below the UI.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D noise_tex : filter_nearest, repeat_enable;

uniform float tilt_amount : hint_range(0.0, 1.0) = 0.6;
uniform float focus_center : hint_range(0.0, 1.0) = 0.55;
uniform float focus_width : hint_range(0.0, 1.0) = 0.22;
uniform float blur_px : hint_range(0.0, 12.0) = 3.5;

uniform float bloom_amount : hint_range(0.0, 3.0) = 0.5;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float bloom_radius : hint_range(0.0, 40.0) = 9.0;

uniform float aberration : hint_range(0.0, 4.0) = 0.8;
uniform float exposure : hint_range(0.0, 3.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.06;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 lift : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.45;
uniform float grain : hint_range(0.0, 0.3) = 0.035;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);

const vec2 DISK[12] = {
	vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
	vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893),
	vec2(0.507, 0.064), vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598)
};

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;

	// --- tilt-shift depth of field --------------------------------------
	float dist = abs(uv.y - focus_center);
	float blur = smoothstep(focus_width, focus_width + 0.3, dist) * tilt_amount;
	vec3 col;
	if (blur > 0.02) {
		float r = blur * blur_px;
		vec3 acc = texture(screen_tex, uv).rgb;
		for (int i = 0; i < 12; i++) {
			acc += texture(screen_tex, uv + DISK[i] * px * r).rgb;
		}
		col = acc / 13.0;
	} else {
		col = texture(screen_tex, uv).rgb;
	}

	// --- chromatic aberration towards the screen edges -------------------
	vec2 dir = uv - vec2(0.5);
	float edge = dot(dir, dir) * 4.0;
	if (aberration > 0.0) {
		vec2 off = dir * px * aberration * 6.0 * edge;
		col.r = mix(col.r, texture(screen_tex, uv + off).r, 0.75);
		col.b = mix(col.b, texture(screen_tex, uv - off).b, 0.75);
	}

	// --- bloom -------------------------------------------------------------
	if (bloom_amount > 0.0) {
		vec3 bl = vec3(0.0);
		for (int i = 0; i < 12; i++) {
			vec3 s1 = texture(screen_tex, uv + DISK[i] * px * bloom_radius).rgb;
			vec3 s2 = texture(screen_tex, uv + DISK[i].yx * px * bloom_radius * 2.2).rgb;
			bl += max(s1 - vec3(bloom_threshold), vec3(0.0));
			bl += max(s2 - vec3(bloom_threshold), vec3(0.0)) * 0.6;
		}
		col += bl / 19.2 * bloom_amount * 2.5;
	}

	// --- colour grading ------------------------------------------------------
	col *= exposure;
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(luma(col)), col, saturation);
	col = col * tint.rgb + lift.rgb * (1.0 - col);

	// --- vignette -------------------------------------------------------------
	vec2 v = dir * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float vig = smoothstep(0.95, 0.25, length(v) * 1.15);
	col *= mix(1.0, vig, vignette);

	// --- grain ----------------------------------------------------------------
	vec2 nuv = uv / px / 64.0 + vec2(fract(TIME * 7.3) * 13.0, fract(TIME * 3.1) * 7.0);
	float n = texture(noise_tex, nuv).r - 0.5;
	col += n * grain;

	col = mix(col, flash_color.rgb, flash_color.a);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
