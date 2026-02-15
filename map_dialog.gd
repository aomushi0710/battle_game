extends Control

@onready var hboxcontainer := $TextBox/MarginContainer/HBoxContainer
@onready var label := $TextBox/MarginContainer/HBoxContainer/Text
@onready var texture := $TextBox/MarginContainer/HBoxContainer/Image
@onready var name_plate := $NamePlate
@onready var name_panel := $NamePlate/Panel
@onready var name_label := $NamePlate/Panel/Text
@onready var name_plate_right := $NamePlate/Right
@onready var buttons := $Buttons
var text_tween: Tween
var text_speed: float = 0.04
var now_id: int ## 現在表示中の[class DialogData]の[code]id[/code]

signal dialog_opened ## ダイアログが開かれる時に発行されるシグナル
signal dialog_closed ## ダイアログが閉じられる時に発行されるシグナル
signal paging
signal button_chosen(id: int) ## ボタンが押された時にIDと同時に発行されるシグナル
signal battle_started ## バトル開始シグナル
signal battle_finished ## バトル終了シグナル


func _ready() -> void:
	hide()

## ダイアログボックスを開き、[signal dialog_opened]シグナルを発行します。
func dialog_open() -> void:
	show()
	battle_started.connect(func(): )
	dialog_opened.emit()

## ダイアログボックスを閉じ、[signal dialog_closed]シグナルを発行します。
func dialog_close() -> void:
	hide()
	dialog_closed.emit()

## [param datas]から、indexを指定して順番に
##[code]display_dialog()[/code]関数を呼び出していく関数。
## ダイアログの開閉[code]dialog_open()[/code][code]dialog_close()[/code]
##もまとめて行われます。
func dialog_manager(datas: Array[DialogData]) -> void:
	dialog_open()
	
	var redirect_id: int = 0 ## 次に表示したい[class DialogData]のID
	while redirect_id >= 0: # IDが-1になるまでダイアログ表示を繰り返す
		if datas[redirect_id]:
			redirect_id = await display_dialog(datas[redirect_id])
		else:
			printerr("対応するindexのDialogDataが見つかりませんでした。" + 
			"ダイアログ表示を中断します。")
			redirect_id = -1
	
	dialog_close()

## [DialogData]型の[param data]を引数として、ダイアログにテキストを表示する関数。
## [br]awaitを付けてページ送りまたはボタンが押されるまで待った後、
##次に表示されるデータのindexを返します
func display_dialog(data: DialogData) -> int:
	if visible == false:
		printerr("ダイアログボックスは表示されていません。" + 
		"事前にdialog_open()で表示させてください。")
	
	label.visible_characters = 0
	label.text = data.text
	for child in buttons.get_children():
		child.queue_free()
	
	# 名前テキスト表示処理
	name_label.text = data.name_text
	if data.name_text:
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
	
	# 画像表示処理
	texture.texture = data.image
	if data.image:
		hboxcontainer.add_theme_constant_override("separation", 55)
	else:
		hboxcontainer.add_theme_constant_override("separation", 0)
	
	# ボタン表示処理
	if data.button_text:
		for i in len(data.button_text):
			var button = Global.game_button.instantiate()
			if i == 0:
				button.call_deferred("grab_focus")
			button.text = data.button_text[i]
			button.pressed.connect(
				button_chosen.emit.bind(data.button_redirect_id[i]))
			buttons.add_child(button)
		buttons.show()
	else:
		buttons.hide()
	
	text_tween = get_tree().create_tween().bind_node(label)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	text_tween.tween_property(label, "visible_characters", \
	len(label.text), text_speed * len(label.text))
	
	# ボタン表示があるかどうかによって待つ処理を変える
	if data.button_text:
		## 次に表示したいDialogDataのID[br]ボタンがある場合に、動的にIDを変えるための枠
		var redirect_id: int = await button_chosen
		return redirect_id
	elif not data.battle_redirect_id.is_empty():
		await paging
		var is_victory := await _transition_to_battle()
		if is_victory:
			return data.battle_redirect_id[0]
		else:
			return data.battle_redirect_id[1]
	else:
		await paging
		return data.redirect_id

## バトルに移行する関数。[br]勝利すると[code]true[/code]を返します。
## ALERT バトル開始前に、モンスターがいるかどうかチェックする必要あり
func _transition_to_battle() -> bool:
	var battle_scene: Node2D = load(Global.battle_scene).instantiate()
	get_tree().current_scene.add_child(battle_scene)
	battle_started.emit()
	var result: bool = await battle_scene.get_node("battle").battle_finished
	print("result: ", result)
	battle_finished.emit()
	battle_scene.queue_free()
	return result

## Enterキーが押された、またはクリックされた時の処理
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		on_paging()

## Enterキーが押された、またはクリックされた時に[signal paging]シグナルを送る関数
func on_paging() -> void:
	if text_tween and text_tween.is_running():
		text_tween.kill() # tweenがすでに動作しているならアニメーションスキップ
		label.visible_characters = -1 # 全表示
	else:
		paging.emit()
