shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 枠線の色 (デフォルトは黒)
uniform float outline_width : hint_range(0.0, 10.0) = 5.0; // 枠線の太さ

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0)); // テクスチャのサイズを取得
	float outline = 0.0; // アウトラインを描画するかどうかのフラグ

	// 上下左右のピクセルをチェック
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0, outline_width) / size).a);
	outline = max(outline, texture(TEXTURE, UV - vec2(0.0, outline_width) / size).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(outline_width, 0.0) / size).a);
	outline = max(outline, texture(TEXTURE, UV - vec2(outline_width, 0.0) / size).a);
	// 斜めもチェックすると、より綺麗になる (任意)
	outline = max(outline, texture(TEXTURE, UV + vec2( outline_width, outline_width) / size).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-outline_width, outline_width) / size).a);
	outline = max(outline, texture(TEXTURE, UV + vec2( outline_width,-outline_width) / size).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-outline_width,-outline_width) / size).a);

	// 元のテクスチャの色を取得
	vec4 color = texture(TEXTURE, UV);

	// もし元の色が透明に近くて、周りに色があれば、アウトラインの色を描画
	COLOR = mix(color, outline_color, outline - color.a);
}