shader_type canvas_item;
render_mode unshaded;

group_uniforms Alpha;
/**
 * Alpha cut-off threshold.
 * This is the opacity cut-off threshold. Every value below the cut-off threshold becomes 0 (full transparency) while every value above the cut-off threshold becomes 1 (full opacity).
 * [b]Note[/b]: due to the way the cut-off works, in order to ensure complete transparency, you need to go slightly above 1.
 */
uniform float cutoff : hint_range(-0.001, 1.001) = 0.0;

/**
 * Smoothing window.
 * This applies a smoothstep to the cut-off threshold. Every value in the range between the cut-off threshold and the cut-off threshold plus the smoothing window gets interpolated between 0 and 1. Values outside that range either become 0 if they lie below the range or 1 if they lie above the range. So, if Smoothing Window = 0, the transition is hard-edged (binary alpha). A small value (e.g., 0.05) creates soft edges.
 */
uniform float smoothing_window : hint_range(0.0, 1.0) = 0.0;

/**
 * Invert colors.
 * If [code]true[/code] this turns the texture into its negative.
 */
uniform bool invert_color = false;

/**
 * Invert alpha.
 * If [code]true[/code] opacity becomes transparency.
 */
uniform bool invert_alpha = false;

group_uniforms;

group_uniforms UV_Transform;
/**
 * Translation. This shifts the texture origin.
 */
uniform vec2 position = vec2(0.0);

/**
 * Rotation (in degrees).
 * Useful for rotating CurveTexture and GradientTexture1D by multiples of 90°.
 */
uniform float rotation = 0.0;

/**
 * Scaling.
 * Use non-uniform scaling for stretching and reflecting textures.
 */
uniform vec2 scale = vec2(1.0);

/**
 * Shear.
 */
uniform vec2 shear = vec2(0.0);

group_uniforms;

group_uniforms Mask;
/**
 * Texture channel.
 * This selects which texture channel will be used: R (default), G, B, A. This way, you can even pack multiple textures in a single file in separate channels.
 */
uniform int channel : hint_enum("R", "G", "B", "A") = 0;

/**
 * Centered mode.
 * If [code]true[/code] centers the mask texture.
 */
uniform bool centered = true;

/**
 * Texture [url=https://docs.godotengine.org/en/stable/classes/class_texturerect.html#enum-texturerect-stretchmode]StretchMode[/url]. This tells the shader how the texture will be adapted to the curtain size. Available modes:
 * [b]Scale[/b]: scale to fit the curtain.
 * [b]Keep Aspect[/b]: scale the texture to fit the curtain, but maintain the texture's aspect ratio.
 * [b]Keep Aspect Covered[/b]: scale the texture so that the shorter side fits the curtain. The other side clips to the curtain's limits.
 */
uniform int stretch_mode : hint_enum("Scale", "Keep Aspect", "Keep Aspect Covered");

/**
 * Windowboxing.
 * If [code]true[/code] enables black bars around the texture.
 */
uniform bool windowbox = false;

/**
 * Texture repeat.
 * If [code]true[/code] enables texture repeat.
 */
uniform bool repeat = false;

/**
 * Texture.
 * This is the texture that will be used in the transition for alpha value sampling.
 */
uniform sampler2D mask;

/**
 * Curtain size.
 * Ignore.
 */
uniform vec2 curtain_size = vec2(16.0, 9.0);

group_uniforms;

const vec2 uv_center = vec2(.5);

// 2D Transformations
vec2 transform(vec2 uv) {
	float r = radians(rotation);
	float s = sin(r);
	float c = cos(r);
	float o = centered ? 1.0 : 0.0;

	vec3 nc = vec3(uv - o * uv_center, 1.0);
	mat3 I = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
	mat3 T = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(position, 1.0));
	mat3 R = mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0));
	mat3 S = mat3(vec3(1.0 / scale.x, 0, 0.0), vec3(0.0, 1.0 / scale.y, 1.0), vec3(0.0, 0.0, 1.0));
	mat3 Z = mat3(vec3(1.0 + shear.x * shear.y, shear.y, 0.0), vec3(shear.x, 1.0, 0.0), vec3(0.0, 0.0, 1.0));

	// UV stretch
	// Curtain aspect ratio
	float ar_c = curtain_size.x / curtain_size.y;
	// Mask texture aspect ratio
	vec2 mask_size = vec2(textureSize(mask, 0));
	float ar_t = mask_size.x / mask_size.y;
	mat3 P;
	mat3 Q;

	switch (stretch_mode) {
		case 0: // Stretch Scale
			P = I;
			Q = I;
			break;
		case 1: // Stretch Keep Aspect Centered
			P = mat3(vec3(ar_c, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
			Q = mat3(vec3(1.0 / ar_t, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
			break;
		case 2: // Stretch Keep Aspect Covered
			P = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0 / ar_c, 0.0), vec3(0.0, 0.0, 1.0));
			Q = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, ar_t, 0.0), vec3(0.0, 0.0, 1.0));
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
	if (a == b) {
		return step(a, c);
	}
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
	if (!windowbox && (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)) {
		discard; // a = 0;
	}
	// Invert alpha if needed
	a = invert_alpha ? 1.0 - a : a;

	COLOR = vec4(COLOR.rgb, a);
}
