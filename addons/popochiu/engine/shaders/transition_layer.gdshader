shader_type canvas_item;
render_mode unshaded;

group_uniforms Alpha;
// Alpha cutoff threshold
uniform float cutoff: hint_range(-0.001, 1.001) = 0.0;
// Threshold interval for interpolation
uniform float smoothing_window: hint_range(0.0, 1.0) = 0.0;
// invert_color: true = switches white and black
uniform bool invert_color = false;
// invert_alpha: for increasing cutoff: false = fade-in kind, true = fade-out kind
uniform bool invert_alpha = false;

group_uniforms UV_Transform;
// Translation
uniform vec2 position = vec2(0.0);
// Rotation. Useful for rotating CurveTexture and GradientTexture1D by multiples of 90°
uniform float rotation = 0.0;
// Non-uniform scale for zooming and reflecting
uniform vec2 scale = vec2(1.0);
// Shear
uniform vec2 shear = vec2(0.0);

group_uniforms Mask;
// Select channel
uniform int channel: hint_enum("R", "G", "B", "A") = 0;
// Center the mask texture
uniform bool centered = true;
// Textrue stretch mode
uniform int stretch_mode: hint_enum("Scale", "Keep Aspect", "Keep Aspect Covered");
// Enable/disable black bars around the texture
uniform bool windowbox = false;
// Texture repeat on/off
uniform bool repeat = false;
// Grayscale texture for alpha value sampling
uniform sampler2D mask;
// Curtain size: must be supplied for correct stretch mode management
uniform vec2 curtain_size = vec2(16.0, 9.0);

const vec2 uv_center = vec2(.5);

// 2D Transformations
vec2 transform(vec2 uv) {
	float r = radians(rotation);
	float s = sin(r);
	float c = cos(r);
	float o = centered ? 1.0 : 0.0;

	vec3 nc = vec3(uv - o*uv_center,1.0);
	mat3 I = mat3(vec3(1.0,0.0,0.0), vec3(0.0,1.0,0.0), vec3(0.0,0.0,1.0));
	mat3 T = mat3(vec3(1.0,0.0,0.0), vec3(0.0,1.0,0.0), vec3(position,1.0));
	mat3 R = mat3(vec3(c,s,0.0), vec3(-s,c,0.0), vec3(0.0,0.0,1.0));
	mat3 S = mat3(vec3(1.0/scale.x,0,0.0), vec3(0.0,1.0/scale.y,1.0), vec3(0.0,0.0,1.0));
	mat3 Z = mat3(vec3(1.0+shear.x*shear.y,shear.y,0.0), vec3(shear.x,1.0,0.0), vec3(0.0,0.0,1.0));

	// UV stretch
	// Curtain aspect ratio
	float ar_c = curtain_size.x / curtain_size.y;
	// Mask texture aspect ratio
	vec2 mask_size = vec2(textureSize(mask,0));
	float ar_t = mask_size.x / mask_size.y;
	mat3 P;
	mat3 Q;

	switch (stretch_mode) {
		case 0: // Stretch Scale
			P = I;
			Q = I;
			break;
		case 1: // Stretch Keep Aspect Centered
			P = mat3(vec3(ar_c,0.0,0.0), vec3(0.0,1.0,0.0), vec3(0.0,0.0,1.0));
			Q = mat3(vec3(1.0/ar_t,0.0,0.0), vec3(0.0,1.0,0.0), vec3(0.0,0.0,1.0));
			break;
		case 2: // Stretch Keep Aspect Covered
			P = mat3(vec3(1.0,0.0,0.0), vec3(0.0,1.0/ar_c,0.0), vec3(0.0,0.0,1.0));
			Q = mat3(vec3(1.0,0.0,0.0), vec3(0.0,ar_t,0.0), vec3(0.0,0.0,1.0));
			break;
		default:
			P = I;
			Q = I;
			break;
		}

	return (Q * Z * S * R * P * T * nc).xy + o * uv_center;
}


// Smoothstep with well-defined behaviour if a == b
float pstep(float a, float b, float c) {
	if (a == b)
		return step(a, c);
	return smoothstep(a, b, c);
}


void fragment() {
	vec2 uv = UV;
	// Stretch and transform UV coordinates
	uv = transform(uv);
	// Repeat the texture if needed
	uv = repeat ? uv = fract(uv) : uv;
	// Sample color from the mask texture
	float c = texture(mask, uv)[channel];
	// Invert color if needed
	c = invert_color ? 1.0 - c : c;
	// Alpha from color cutoff
	float a = pstep(cutoff, cutoff + smoothing_window, c);
	// Avoid windowbox around the mask if it's scaled to fit the curtain.
	// If the calculated uv are not in 0-1 range, set alpha to 0.
	if (!windowbox && (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0))
		discard; // a = 0;
	// Invert alpha if needed
	a = invert_alpha ? 1.0 - a : a;

	COLOR = vec4(COLOR.rgb, a);
}
