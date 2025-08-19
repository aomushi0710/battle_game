extends AcceptDialog

@onready var label := $text ## メッセージ表示領域に重ねられたrichtextlabel
@onready var font: Font = label.get_theme_font("normal_font")
@onready var font_size: int = label.get_theme_font_size("normal_font_size")

## 画面にacceptdialogとしてメッセージを表示する関数[br][br]
## [param text]は本文に、[param title_text]はタイトルに、[param ok_text]はボタンの文字になります。
func display_dialog(text: String, title_text: String = "⚠️ERROR⚠️", ok_text: String = "OK") -> void:
	title = title_text
	label.text = text
	ok_button_text = ok_text
	## bbcodeタグを除いた本文の長さだけ表示領域を確保
	var label_size = font.get_multiline_string_size(
		strip_bbcode(text), 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size) + Vector2(100, 200) # ちょっと余白
	size = label_size
	label.size = label_size
	popup_centered()

## BBcodeのタグ[]を含む[param text]を平文に戻して返す関数
func strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)
