extends Control

@onready var label := $TextBox/MarginContainer/HBoxContainer/Text
@onready var texture := $TextBox/MarginContainer/HBoxContainer/Image
@onready var name_plate := $NamePlate
@onready var name_panel := $NamePlate/Panel
@onready var name_label := $NamePlate/Panel/Text
@onready var name_plate_right := $NamePlate/Right
var text_tween: Tween
var text_speed: float = 0.04

enum Mode { ## ダイアログの形式
	TEXT_ONLY, ## テキストのみを表示します。
	SHOW_NAME, ## キャラクターの名前を枠の上部に表示します。
	SHOW_IMAGE = 2, ## 追加で画像をテキストの左に表示します。
	SHOW_BUTTON = 4, ## 選択肢のボタンを表示します。
}

signal dialog_opened ## ダイアログが開かれる時に発行されるシグナル
signal dialog_closed ## ダイアログが閉じられる時に発行されるシグナル
signal paging


func _ready() -> void:
	hide()

## ダイアログボックスを開き、[signal dialog_opened]シグナルを発行します。
func dialog_open() -> void:
	show()
	dialog_opened.emit()

## ダイアログボックスを閉じ、[signal dialog_closed]シグナルを発行します。
func dialog_close() -> void:
	hide()
	dialog_closed.emit()

## [class DialogData]型の[param data]を引数として、ダイアログにテキストを表示する関数。
## [br]基本的にはawaitを付けて、ページ送りやボタンが押されるまで待ちます。
func display_dialog(data: DialogData) -> void:
	if visible == false:
		print("ダイアログボックスは表示されていません。" + 
		"事前にdialog_open()で表示させてください。")
	
	label.visible_characters = 0
	label.text = data.text
	
	# 名前テキスト処理
	name_label.text = data.name_text
	if data.name_text != "":
		## 文字数に応じたネームプレートの長さ
		var plate_size: int = name_label.get_content_width() + 200
		# 各種サイズ変更
		name_label.size.x = plate_size
		name_panel.size.x = plate_size
		name_plate_right.position.x = plate_size + name_panel.position.x
		# 色変更
		name_panel.texture.gradient.colors[0] = data.name_color
		
		name_plate.show()
	else:
		name_plate.hide()
	
	text_tween = get_tree().create_tween().bind_node(label)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # テキストアニメーション再生
	text_tween.tween_property(label, "visible_characters", \
	len(label.text), text_speed * len(label.text))
	
	await paging

## Enterキーが押された、またはクリックされた時の処理
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		on_paging()
		get_viewport().set_input_as_handled() # inputを止める

## Enterキーが押された、またはクリックされた時に[code]paging[/code]シグナルを送る関数
func on_paging() -> void:
	if text_tween and text_tween.is_running(): # tweenがすでに動作しているならアニメーションスキップ
		text_tween.kill()
		label.visible_characters = -1 # 全表示
	else:
		paging.emit()
