extends ConfirmationDialog

@onready var label := $text ## メッセージ表示領域に重ねられたrichtextlabel
@onready var font: Font = label.get_theme_font("normal_font")
@onready var font_size: int = label.get_theme_font_size("normal_font_size")
var embed_color: Color = Color.BLACK: ## ダイアログのテキスト表示領域[b]外[/b]の背景色
	set(color):
		var style: StyleBoxFlat = get_theme_stylebox("embedded_border")
		style.bg_color = color
var panel_color: Color = Color.MIDNIGHT_BLUE: ## ダイアログのテキスト表示領域の背景色
	set(color):
		var style: StyleBoxFlat = get_theme_stylebox("panel")
		style.bg_color = color

## 画面にacceptdialogとしてメッセージを表示する関数[br][br]
## [param text]で本文、[param title_text]でタイトル、
##[param ok_text]でOKボタンの文字、[param cancel_text]でCancelボタンの文字を適用します。
func display_dialog(text: String, title_text: String = "⚠️ERROR⚠️", 
ok_text: String = "OK", cancel_text: String = "Cancel") -> void:
	title = title_text
	label.text = text
	ok_button_text = ok_text
	cancel_button_text = cancel_text
	
	## bbcodeタグを除いた本文の長さだけ表示領域を確保
	var label_size = font.get_multiline_string_size(
		Global.strip_bbcode(text), 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size) + Vector2(100, 200) # ちょっと余白
	size = label_size
	label.size = label_size
	popup_centered()


func reset() -> void:
	embed_color = Color.BLACK
	panel_color = Color.MIDNIGHT_BLUE
