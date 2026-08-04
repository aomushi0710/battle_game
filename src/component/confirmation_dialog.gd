class_name ConfirmationDialogManager
extends ConfirmationDialog

const DIALOG_PADDING := Vector2(100, 200) ## 余白

var on_confirm_callable: Callable ## OKボタンが押された時の処理
var on_cancel_callable: Callable ## Cancelボタンが押された時の処理

var embed_color := Color.BLACK: ## ダイアログのテキスト表示領域[b]外[/b]の背景色
	set(color):
		var style: StyleBoxFlat = embedded_border.duplicate()
		style.bg_color = color
		add_theme_stylebox_override("embedded_border", style)

var panel_color := Color.MIDNIGHT_BLUE: ## ダイアログのテキスト表示領域の背景色
	set(color):
		var style: StyleBoxFlat = panel.duplicate()
		style.bg_color = color
		add_theme_stylebox_override("panel", style)

@onready var label := $text ## メッセージ表示領域に重ねられたrichtextlabel
@onready var font: Font = label.get_theme_font("normal_font")
@onready var font_size: int = label.get_theme_font_size("normal_font_size")
@onready var embedded_border := get_theme_stylebox("embedded_border")
@onready var panel := get_theme_stylebox("panel")


func _ready() -> void:
	confirmed.connect(self._on_internal_confirmed)
	canceled.connect(self._on_internal_canceled)

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
		font_size) + DIALOG_PADDING
	size = label_size
	label.size = label_size
	popup_centered()

## OKボタンが押された時の処理
func _on_internal_confirmed():
	if on_confirm_callable.is_valid():
		var callable_to_run = on_confirm_callable
		on_confirm_callable = Callable()
		callable_to_run.call()
	reset()

## ## Cancelボタンが押された時の処理
func _on_internal_canceled():
	if on_cancel_callable.is_valid():
		var callable_to_run = on_cancel_callable
		on_cancel_callable = Callable()
		callable_to_run.call()
	reset()


func reset() -> void:
	embed_color = Color.BLACK
	panel_color = Color.MIDNIGHT_BLUE
