class_name Dialog
extends CanvasLayer
## 汎用ダイアログシステム。[DialogData]を用いて様々なパターンのダイアログを表示します。

signal option_selected(i: int) ## ボタンが押された時にそのボタンのindexを発行します

const SCALE: Vector2 = Vector2.ONE ## ダイアログ表示時の[member Control.scale]
const ANIMATION_SPEED: float = 0.1 ## ダイアログ表示切替アニメーションにかかる秒数

@onready var _background := %Background as ColorRect ## ダイアログ外部に表示されるマスク

@onready var _panel_container := %PanelContainer as PanelContainer ## ダイアログ本体
@onready var _border := %Border as Panel ## タイトルと本文の間に表示される線

@onready var _title_label := %Title as RichTextLabel ## タイトル
@onready var _text_label := %Text as RichTextLabel ## 本文
@onready var _button_container := %ButtonContainer as HBoxContainer ## ボタンを複数格納できるコンテナ

var _local_stylebox: StyleBoxFlat ## テーマ上書き用StyleBox
var _has_title: bool ## ダイアログタイトルの有無

func _ready() -> void:
	_local_stylebox = _panel_container.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_panel_container.add_theme_stylebox_override("panel", _local_stylebox)

## [DialogData]を引数としてダイアログを作成し表示します。
## 表示は自動で行われますが、非表示は[method Dialog.hide_dialog]で明示的に行う必要があります。
func set_dialog(data: DialogData) -> int:
	# タイトルがなければ不要なノードを隠す
	if data.title.is_empty():
		_has_title = false
		_title_label.hide()
		_border.hide()
	else:
		_has_title = true
		_title_label.text = data.title
		_title_label.show()
		_border.show()
	
	_text_label.text = data.text
	
	if _local_stylebox:
		_local_stylebox.bg_color = data.dialog_color
		_local_stylebox.border_color = data.dialog_border_color
	# borderは色しか変更しないためself_modulateで対応
	_border.self_modulate = data.dialog_border_color
	
	for i in data.button_text.size():
		var button: GameButton
		if i >= _button_container.get_child_count():
			button = Global.game_button.instantiate() as GameButton
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.button_up.connect(option_selected.emit.bind(i))
			_button_container.add_child(button)
		else:
			button = _button_container.get_child(i) as GameButton
		
		button.text = data.button_text[i]
		if data.button_color and i < data.button_color.size(): # ボタンの色指定があれば
			button.color = data.button_color[i]
		
		button.show()
	
	if not visible:
		_show_dialog()
	
	## 押されたボタンのindex
	var selected_index: int = (await option_selected) as int
	return selected_index

## ダイアログを表示します
func _show_dialog() -> void:
	var title: String = _title_label.text
	if _has_title:
		_title_label.text = " " # コンテナの構造が崩れないように空白を入れておく
	
	show()
	var tween := _panel_container.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_panel_container, "scale:x", SCALE.x, ANIMATION_SPEED)
	tween.tween_property(_panel_container, "scale:y", SCALE.y, ANIMATION_SPEED)
	await tween.finished
	
	#_title_label.show() show_dialog関数内で個別設定するため不要
	_text_label.show()
	_button_container.show()
	
	if _has_title:
		_title_label.text = title

## ダイアログを非表示にします
func hide_dialog() -> void:
	_text_label.hide()
	_button_container.hide()
	if _has_title:
		_title_label.text = " " # コンテナの構造が崩れないように空白を入れておく
	
	var tween := _panel_container.create_tween()
	tween.tween_property(_panel_container, "scale:y", 0.1, ANIMATION_SPEED)
	tween.tween_property(_panel_container, "scale:x", 0, ANIMATION_SPEED)
	await tween.finished
	hide()
	
	for child in _button_container.get_children():
		(child as Button).hide()
