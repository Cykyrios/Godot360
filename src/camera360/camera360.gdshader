shader_type spatial;
render_mode unshaded, cull_front;

uniform float subcamera_fov = 100.0;
uniform float fovx;

uniform int lens;
uniform vec2 camera_resolution;
uniform bool show_grid;

uniform sampler2D Grid;
uniform sampler2D Texture0 : hint_default_black;
uniform sampler2D Texture1 : hint_default_black;
uniform sampler2D Texture2 : hint_default_black;
uniform sampler2D Texture3 : hint_default_black;
uniform sampler2D Texture4 : hint_default_black;
uniform sampler2D Texture5 : hint_default_black;


vec3 latlon_to_ray(vec2 latlon) {
	float lat = latlon.x;
	float lon = latlon.y;
	return vec3(sin(lon) * cos(lat), sin(lat), -cos(lon) * cos(lat));
}

vec3 rectilinear_inverse(vec2 p) {
	float r = sqrt(p.x * p.x + p.y * p.y);
	float theta = atan(r);
	float s = sin(theta);
	return vec3(p.x / r * s, p.y / r * s, -cos(theta));
}
vec2 rectilinear_forward(vec2 latlon) {
	vec3 ray = latlon_to_ray(latlon);
	float theta = acos(-ray.z);
	float r = tan(theta);
	float c = r / length(ray.xy);
	return vec2(ray.x * c, ray.y * c);
}
vec3 rectilinear_ray(vec2 p) {
	float scale = rectilinear_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return rectilinear_inverse(p * scale);
}

vec3 panini_inverse(vec2 p) {
	float d = 1.0;
	float k = p.x * p.x / ((d + 1.0) * (d + 1.0));
	float dscr = k * k * d * d - (k + 1.0) * (k * d * d - 1.0);
	float clon = (-k * d + sqrt(dscr)) / (k + 1.0);
	float s = (d + 1.0) / (d + clon);
	float lon = atan(p.x, (s * clon));
	float lat = atan(p.y, s);
	return latlon_to_ray(vec2(lat, lon));
}
vec2 panini_forward(vec2 latlon) {
	float d = 1.0;
	float s = (d + 1.0) / (d + cos(latlon.y));
	float x = s * sin(latlon.y);
	float y = s * tan(latlon.x);
	return vec2(x, y);
}
vec3 panini_ray(vec2 p) {
	float scale = panini_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return panini_inverse(p * scale);
}

vec3 fisheye_inverse(vec2 p) {
	float r = sqrt(p.x * p.x + p.y * p.y);

	if (r > PI) {
		return vec3(0.0, 0.0, 0.0);
	}
	else {
		float theta = r;
		float s = sin(theta);
		return vec3(p.x / r * s, p.y / r * s, -cos(theta));
	}
}
vec2 fisheye_forward(vec2 latlon) {
	vec3 ray = latlon_to_ray(latlon);
	float theta = acos(-ray.z);
	float r = theta;
	float c = r / length(ray.xy);
	return vec2(ray.x * c, ray.y * c);
}
vec3 fisheye_ray(vec2 p) {
	float scale = fisheye_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return fisheye_inverse(p * scale);
}

vec3 stereographic_inverse(vec2 p) {
	float scale = 0.5;
	float r = sqrt(p.x * p.x + p.y * p.y);
	float theta = atan(r) / scale;
	float s = sin(theta);
	return vec3(p.x / r * s, p.y / r * s, -cos(theta));
}
vec2 stereographic_forward(vec2 latlon) {
	vec3 ray = latlon_to_ray(latlon);
	float theta = acos(-ray.z);
	float scale = 0.5;
	float r = tan(theta * scale);
	float c = r / length(ray.xy);
	return vec2(ray.x * c, ray.y * c);
}
vec3 stereographic_ray(vec2 p) {
	float scale = stereographic_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return stereographic_inverse(p * scale);
}

vec3 cylindrical_inverse(vec2 p) {
	if (abs(p.x) > PI) {
		return vec3(0.0, 0.0, 0.0);
	} else {
		float lon = p.x;
		float lat = atan(p.y);
		return latlon_to_ray(vec2(lat, lon));
	}
}
vec2 cylindrical_forward(vec2 latlon) {
	return(vec2(latlon.y, tan(latlon.x)));
}
vec3 cylindrical_ray(vec2 p) {
	float scale = cylindrical_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return cylindrical_inverse(p * scale);
}

vec3 equirectangular_inverse(vec2 p) {
	if (abs(p.y) > PI / 2.0 || abs(p.x) > PI) {
		return vec3(0.0, 0.0, 0.0);
	} else {
		float lon = p.x;
		float lat = p.y;
		return latlon_to_ray(vec2(lat, lon));
	}
}
vec2 equirectangular_forward(vec2 latlon) {
	return vec2(latlon.y, latlon.x);
}
vec3 equirectangular_ray(vec2 p) {
	float scale = equirectangular_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return equirectangular_inverse(p * scale);
}

vec3 mercator_inverse(vec2 p) {
	if (abs(p.x) > PI) {
		return vec3(0.0, 0.0, 0.0);
	} else {
		float lon = p.x;
		float lat = atan(sinh(p.y));
		return latlon_to_ray(vec2(lat, lon));
	}
}
vec2 mercator_forward(vec2 latlon) {
	return vec2(latlon.y, log(tan(PI / 4.0 + latlon.x / 2.0)));
}
vec3 mercator_ray(vec2 p) {
	float scale = mercator_forward(vec2(0.0, radians(fovx) / 2.0)).x;
	return mercator_inverse(p * scale);
}

vec3 get_transformation(vec2 uv) {
	switch (lens) {
		case 0: return(rectilinear_ray(uv));
		case 1: return(panini_ray(uv));
		case 2: return(fisheye_ray(uv));
		case 3: return(stereographic_ray(uv));
		case 4: return(cylindrical_ray(uv));
		case 5: return(equirectangular_ray(uv));
		case 6: return(mercator_ray(uv));
	}
}

vec3 srgb_to_linear(vec3 color) {
	return color * (color * (color * 0.305306011 + 0.682171111) + 0.012522878);
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	bool debug = false;

	vec3 color_front = vec3(1.0, 1.0, 1.0);
	vec3 color_back = vec3(1.0, 1.0, 0.0);
	vec3 color_left = vec3(1.0, 0.0, 0.0);
	vec3 color_right = vec3(1.0, 0.2, 0.0);
	vec3 color_bottom = vec3(0.0, 1.0, 0.0);
	vec3 color_top = vec3(0.0, 0.0, 1.0);
	float alpha = 0.5;

	float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 uv = FRAGCOORD.xy / min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y);
	vec3 pos = vec3(0.0, 0.0, 0.0);
	if (view_ratio > 1.0) {
		pos = get_transformation(vec2(uv.x - 0.5 * view_ratio, uv.y - 0.5) * 1.0);
	} else {
		pos = get_transformation(vec2(uv.x - 0.5, uv.y - 0.5 * view_ratio) * 1.0);
	}
	if (pos == vec3(0.0, 0.0, 0.0)) {
		ALBEDO = pos;
	} else {
		float ax = abs(pos.x);
		float ay = abs(pos.y);
		float az = abs(pos.z);

		float fov_fix = 1.0 / tan(radians(subcamera_fov / 2.0));
		if (az >= ax && az >= ay) {
			if (pos.z < 0.0) {
				uv = vec2(fov_fix * 0.5 * (vec2(pos.x / az, pos.y / az)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture0, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_front, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			} else {
				uv = vec2(fov_fix * 0.5 * (vec2(-pos.x / az, pos.y / az)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture5, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_back, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			}
		} else if (ax >= ay && ax >= az) {
			if (pos.x < 0.0) {
				uv = vec2(fov_fix * 0.5 * (vec2(-pos.z / ax, pos.y / ax)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture1, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_left, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			} else {
				ALBEDO = color_right;
				uv = vec2(fov_fix * 0.5 * (vec2(pos.z / ax, pos.y / ax)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture2, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_right, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			}
		} else if (ay >= ax && ay >= az) {
			if (pos.y > 0.0) {
				uv = vec2(fov_fix * 0.5 * (vec2(pos.x / ay, pos.z / ay)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture3, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_bottom, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			} else {
				uv = vec2(fov_fix * 0.5 * (vec2(pos.x / ay, -pos.z / ay)) + 0.5);
				ALBEDO = srgb_to_linear(texture(Texture4, uv).rgb);
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_top, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
			}
		} else {
			ALBEDO = vec3(0.0, 0.0, 0.0);
		}
	}
	if (debug) {
		ALBEDO = vec3(uv.x, uv.y, 0.0); // debug UV display
		if (show_grid) {
			ALBEDO = ALBEDO * texture(Grid, uv).rgb;
		}
	}
}
