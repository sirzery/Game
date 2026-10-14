shader_type canvas_item;
render_mode unshaded;

// Animated pixel-art sky: gradient, drifting banded clouds (ordered dither),
// stars, a moon with halo and lightning flashes.

uniform vec2 resolution = vec2(1280.0, 720.0);
uniform float pixel_size = 3.0;
uniform vec4 top_color : source_color = vec4(0.02, 0.02, 0.06, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.10, 0.08, 0.16, 1.0);
uniform vec4 cloud_dark : source_color = vec4(0.06, 0.06, 0.10, 1.0);
uniform vec4 cloud_light : source_color = vec4(0.22, 0.22, 0.30, 1.0);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.55;
uniform float cloud_scale = 3.0;
uniform vec2 cloud_speed = vec2(0.012, 0.002);
uniform float stars : hint_range(0.0, 1.0) = 0.0;
uniform vec2 moon_pos = vec2(0.78, 0.2);
uniform float moon_size = 0.05;
uniform vec4 moon_color : source_color = vec4(0.9, 0.92, 1.0, 1.0);
uniform float moon_visible : hint_range(0.0, 1.0) = 0.0;
uniform float lightning : hint_range(0.0, 1.0) = 0.0;
uniform vec2 scroll = vec2(0.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += vnoise(p) * a;
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[idx] / 16.0;
}

void fragment() {
	vec2 cell = floor(UV * resolution / pixel_size);
	vec2 uv = cell * pixel_size / resolution;
	float aspect = resolution.x / resolution.y;
	float dither = bayer4(cell) - 0.5;

	vec3 col = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, uv.y));

	if (stars > 0.0) {
		float s = hash(cell * 0.73);
		float tw = 0.6 + 0.4 * sin(TIME * 2.0 + s * 40.0);
		if (s > 0.996) {
			col += vec3(0.8, 0.85, 1.0) * stars * tw * (1.0 - uv.y);
		}
	}

	if (moon_visible > 0.0) {
		vec2 d = (uv - moon_pos) * vec2(aspect, 1.0);
		float r = length(d);
		col += moon_color.rgb * smoothstep(moon_size * 5.0, 0.0, r) * 0.18 * moon_visible;
		if (r < moon_size) {
			float crater = fbm((uv + 3.0) * 30.0);
			col = mix(col, moon_color.rgb * (0.82 + crater * 0.25), moon_visible);
		}
	}

	vec2 cp = uv * vec2(aspect, 1.0) * cloud_scale + TIME * cloud_speed + scroll;
	float n = fbm(cp + vec2(fbm(cp * 0.5 + TIME * 0.01), 0.0));
	float density = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.35, n + dither * 0.12);
	float band = floor(density * 4.0 + dither * 0.9) / 4.0;
	float lit = clamp(fbm(cp * 1.7 + 11.0) * 1.2 - 0.25 + dither * 0.15, 0.0, 1.0);
	vec3 cloud = mix(cloud_dark.rgb, cloud_light.rgb, floor(lit * 3.0) / 3.0);
	col = mix(col, cloud, clamp(band, 0.0, 1.0));

	col += vec3(0.75, 0.8, 1.0) * lightning * (0.35 + density * 0.9);
	COLOR = vec4(col, 1.0);
}
