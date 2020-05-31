shader_type spatial;
render_mode unshaded;

const float PI = 3.14159265358979323846;

uniform float fovx;

uniform int lens;
uniform int globe;
uniform vec2 camera_resolution;
uniform bool show_grid;

uniform sampler2D Grid;
uniform sampler2D Texture0 : hint_black;
uniform sampler2D Texture1 : hint_black;
uniform sampler2D Texture2 : hint_black;
uniform sampler2D Texture3 : hint_black;
uniform sampler2D Texture4 : hint_black;
uniform sampler2D Texture5 : hint_black;

// structs are not available yet in 3.2
/*
struct Plate {
	vec3 right;
	vec3 up;
	float fov;
};
*/


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

// The following globes are available:
// 0 = cube face
// 1 = cube edge
// 2 = cube corner
// Each globe plate is defined as a float array of length 7 (structs not available yet)
// plate = {forward(vec3), up(vec3), fov(float)}
int get_globe_plate(vec3 ray) {
	if (ray == vec3(0.0, 0.0, 0.0)) {
		return -1;
	}
	
	// standard cube plates (front, left, right, bottom, top, back)
	float plates[] = {0.0, 0.0, -1.0, 0.0, 1.0, 0.0, 90.0,
			-1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 90.0,
			1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 90.0,
			0.0, -1.0, 0.0, 0.0, 0.0, -1.0, 90.0,
			0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 90.0,
			0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 90.0};
	
	if (globe == 0) {
		int plate = 0;
		float min_dist = length(ray - vec3(plates[0], plates[1], plates[2]));
		for (int i = 1; i < 6; i++) {
			vec3 fwd = vec3(plates[7 * i], plates[7 * i + 1], plates[7 * i + 2]);
			float dist = length(ray - fwd);
			if (dist < min_dist) {
				plate = i;
				min_dist = dist;
			}
		}
		return plate;
	}
	else if (globe == 1) {
		for (int i = 0; i < 6; i++) {
			float x, y, z;
			float a = PI / 4.0;
			
			x = plates[7 * i];
			z = plates[7 * i + 2];
			plates[7 * i] = x * cos(a) - z * sin(a);
			plates[7 * i + 2] = x * sin(a) + z * cos(a);
			x = plates[7 * i + 3];
			z = plates[7 * i + 5];
			plates[7 * i + 3] = x * cos(a) - z * sin(a);
			plates[7 * i + 5] = x * sin(a) + z * cos(a);
		}
		int plate = 0;
		float min_dist = length(ray - vec3(plates[0], plates[1], plates[2]));
		for (int i = 1; i < 6; i++) {
			vec3 fwd = vec3(plates[7 * i], plates[7 * i + 1], plates[7 * i + 2]);
			float dist = length(ray - fwd);
			if (dist < min_dist) {
				plate = i;
				min_dist = dist;
			}
		}
		return plate;
	}
	else if (globe == 2) {
		for (int i = 0; i < 6; i++) {
			float x, y, z;
			float a = PI / 4.0;
			
			x = plates[7 * i];
			z = plates[7 * i + 2];
			plates[7 * i] = x * cos(a) - z * sin(a);
			plates[7 * i + 2] = x * sin(a) + z * cos(a);
			x = plates[7 * i + 3];
			z = plates[7 * i + 5];
			plates[7 * i + 3] = x * cos(a) - z * sin(a);
			plates[7 * i + 5] = x * sin(a) + z * cos(a);
			
			a = atan(1.0 / sqrt(2.0));
			y = plates[7 * i + 1];
			z = plates[7 * i + 2];
			plates[7 * i + 1] = y * cos(a) - z * sin(a);
			plates[7 * i + 2] = y * sin(a) + z * cos(a);
			y = plates[7 * i + 4];
			z = plates[7 * i + 5];
			plates[7 * i + 1] = y * cos(a) - z * sin(a);
			plates[7 * i + 2] = y * sin(a) + z * cos(a);
		}
		int plate = 0;
		float min_dist = length(ray - vec3(plates[0], plates[1], plates[2]));
		for (int i = 1; i < 6; i++) {
			vec3 fwd = vec3(plates[7 * i], plates[7 * i + 1], plates[7 * i + 2]);
			float dist = length(ray - fwd);
			if (dist < min_dist) {
				plate = i;
				min_dist = dist;
			}
		}
		return plate;
	}
	return -1;
}

vec2 ray_to_plate_uv(vec3 ray, int plate) {
	// structs or arrays are needed here
	return vec2(0.0, 0.0);
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
		pos = get_transformation(vec2(uv.x - 0.5 * view_ratio, uv.y - 0.5) * 1.0);
	}
	if (pos == vec3(0.0, 0.0, 0.0)) {
		ALBEDO = pos;
	} else {
		int plate_idx = get_globe_plate(pos);
		// Move uv out of switch, update by calling ray_to_plate_uv(pos, globe.plate[plate_idx])
		switch (plate_idx) {
			case 0:
				uv = vec2(0.5 * (vec2(pos.x / abs(pos.z), pos.y / abs(pos.z))) + 0.5);
				ALBEDO = texture(Texture0, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_front, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			case 1:
				uv = vec2(0.5 * (vec2(-pos.z / abs(pos.x), pos.y / abs(pos.x))) + 0.5);
				ALBEDO = texture(Texture1, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_left, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			case 2:
				uv = vec2(0.5 * (vec2(pos.z / abs(pos.x), pos.y / abs(pos.x))) + 0.5);
				ALBEDO = texture(Texture2, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_right, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			case 3:
				uv = vec2(0.5 * (vec2(pos.x / abs(pos.y), -pos.z / abs(pos.y))) + 0.5);
				ALBEDO = texture(Texture3, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_bottom, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			case 4:
				uv = vec2(0.5 * (vec2(pos.x / abs(pos.y), pos.z / abs(pos.y))) + 0.5);
				ALBEDO = texture(Texture4, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_top, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			case 5:
				uv = vec2(0.5 * (vec2(-pos.x / abs(pos.z), pos.y / abs(pos.z))) + 0.5);
				ALBEDO = texture(Texture5, uv).rgb;
				if (show_grid) {
					ALBEDO = mix(ALBEDO, ALBEDO * (vec4(color_back, 1.0) * texture(Grid, uv)).rgb, alpha);
				}
				break;
			default:
				ALBEDO = vec3(0.0, 0.0, 0.0);
				break;
		}
	}
	if (debug) {
		ALBEDO = vec3(uv.x, uv.y, 0.0); // debug UV display
		if (show_grid) {
			ALBEDO = ALBEDO * texture(Grid, uv).rgb;
		}
	}
}