class_name BlinkEffect
extends RichTextEffect

# このエフェクトのBBCodeタグ名。ここでは[blink]として使う。
var bbcode = "blink"

# エフェクトを処理するメインの関数
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# 経過時間（ミリ秒）を取得
	var time = Time.get_ticks_msec() / 1000.0
	
	# 0.5秒ごとに表示・非表示を切り替える
	# sin波を使って滑らかに点滅させることもできるよ
	var alpha = 1.0 if fmod(time, 1.0) < 0.5 else 0.0
	
	# 文字の色（char_fx.color）のアルファ値（透明度）を変更する
	char_fx.color.a = alpha
	
	# trueを返して、エフェクトが適用されたことを伝える
	return true
