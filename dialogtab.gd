extends TabContainer
@onready var sign = $"../next_sign"
@onready var sign_pos = sign.position
var tween: Tween
var next_sign_tween: Tween
var dialog_expand_tween: Tween
var text_speed: float = 0.04 ## テキストアニメーションの1文字あたりの再生速度
var now_flavor_text: Array ## 現在表示中のflavor_textを保持
var flavor_text: Array ## 待機中に表示されるテキストArray[Array[string]]
var global_flavor_text: Array ## ステージに関係なく表示されるフレーバーテキスト
var stage_flavor_text: Array ## ステージ固定のフレーバーテキスト
var main_text: Array[String] ## メインに表示するテキストのリスト
var status_text: Array[String] ## 1要素につき1ページ、全角19文字が3行まで
var battle_log_text: Array[String] ## NOTE 変更の可能性あり
var tab_list = [main_text, status_text, battle_log_text] ## tabの位置通りに上記変数を格納する配列
var current_page: int = 0 ## 現在のページ
var next_sign: bool = false ## 最終ページでのメッセージ送りボタンの有無

signal paging ## ダイアログボックスのテキストをメッセージ送りした時に発行されるシグナル


func _ready() -> void:
	global_flavor_text = [["これは...なんとも作りが粗い。\nテストプレイの気配がする。"]]
	tab_list[0] = [""] # test
	tab_list[1] = ["Status ボタンから味方と相手の\nステータスを確認できます！"]
	tab_list[2] = ""
	current_tab = 0
	_on_tab_changed(current_tab) # 初期値タブのテキストをアニメーション

## ダイアログボックスに表示するフレーバーテキストの専用setter
func flavor_text_setter(text: Array) -> void:
	if tween:
		tween.kill()
	if text == []: # array要素の型不明の時
		text = [""] # string型に修正
	next_sign = false
	tab_list[0] = text
	_on_tab_changed(0)

## ダイアログボックスに表示するテキストのsetter[br]tab:タブのindex text:配列の要素1つで1ページ分[br]
## wait true:awaitでメッセージ送りを待つ false:待たない
func text_setter(tab: int, wait: bool, text: Array) -> void:
	if tween:
		tween.kill()
	if text == []: # array要素の型不明の時
		text = [""] # string型に修正
	next_sign = wait
	tab_list[tab] = text
	_on_tab_changed(tab)
	if wait == true:
		await paging # 最後のページがメッセージ送りされてからこの関数の処理を終える
	# これによって、この関数をawaitで待ちながら呼んだ元の関数を再開させることができる

## タブが切り替えられた時、ページ数を0にリセットしてtext_animationを呼ぶ関数
func _on_tab_changed(tab: int) -> void:
	if tab != 2:
		get_child(tab).get_child(0).text = "" # 一旦削除してからアニメーション
		if $"../../".enemy_monster != null: # 元に戻す
			$"../../".enemy_monster.get_node("effect").mouse_filter = MouseFilter.MOUSE_FILTER_STOP
		if size.y != 270: # 拡大されてた時に戻すアニメーション
			var duration = (size.y - 270) / 1448 # 現在サイズからアニメーション秒数を逆算(最大0.5)
			dialog_expand_tween = get_tree().create_tween().bind_node(self)\
			.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			dialog_expand_tween.tween_property(self, "size:y", 270, duration)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			dialog_expand_tween.parallel().tween_property(self, "position:y", 
			800, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			dialog_expand_tween.parallel().tween_property(sign, "modulate:a", 1, duration)
			await dialog_expand_tween.finished
		current_tab = tab
		current_page = 0
		text_animation(tab, 0)
	else: # バトルログ表示処理
		get_child(tab).get_child(0).text = "" # 初期化
		current_tab = tab
		for child in get_children(): # マウスカーソルをデフォルトに
			child.mouse_default_cursor_shape = Control.CURSOR_ARROW
			for c in child.get_children():
				c.mouse_default_cursor_shape = Control.CURSOR_ARROW
		dialog_expand_tween = get_tree().create_tween().bind_node(self)\
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		dialog_expand_tween.tween_property(self, "size:y", 994, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		dialog_expand_tween.parallel().tween_property(self, "position:y", 76, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		dialog_expand_tween.parallel().tween_property(sign, "modulate:a", 0, 0.5)
		await dialog_expand_tween.finished
		if $"../../".enemy_monster != null: # スクロールの邪魔にならないように一旦操作受付を止める
			$"../../".enemy_monster.get_node("effect").mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
		text_animation(tab, -1) # ページはない

## _inputもしくはlabel_gui_inputから、次のページを指定してtext_animationを呼ぶ関数
func text_change_next() -> void:
	if tween and tween.is_running(): # tweenがすでに動作しているならアニメーションスキップ
		tween.kill()
		get_child(current_tab).get_child(0).visible_characters = len(get_child(current_tab).get_child(0).text) # 全表示
	else:
		if len(tab_list[current_tab]) - 1 > current_page: # まだ次のページが存在する場合
			current_page += 1
			text_animation(current_tab, current_page)
		else: # 最後のページの時、処理を進める
			next_sign_off()
			paging.emit()

## Enterキーが押された時、ページ変更ボタンか押された時と同様に振る舞う
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		text_change_next()

## labelの範囲内で左クリックされた時、ページ変更ボタンか押された時と同様に振る舞う
func label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and \
	event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		text_change_next()

## タブのindex、ページ数を引数としてテキストをアニメーション表示させる関数
func text_animation(tab: int, page: int) -> void:
	if tween: # tweenがすでに動作しているなら停止
		tween.kill()
	var label: RichTextLabel = get_child(tab).get_child(0) # タブのラベル取得
	if tab == 2:
		label.text = tab_list[tab]
		label.get_v_scroll_bar().value = label.get_v_scroll_bar().max_value # 1番下でセット
		return
	label.visible_characters = 0 # 隠す
	label.text = tab_list[tab][page]
	tween = get_tree().create_tween().bind_node(label)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # テキストアニメーション再生
	tween.tween_property(label, "visible_characters", \
	len(label.text), text_speed * len(label.text))
	# 最後のページではない、もしくは最後のページだがプレイヤーの入力を待つとき
	if len(tab_list[current_tab]) - 1 > current_page or next_sign == true:
		next_sign_on()
	else:
		next_sign_off()

## メッセージ送りボタンアニメーション再生
func next_sign_on() -> void:
	if next_sign_tween and next_sign_tween.is_running():
		next_sign_tween.kill()
	for child in get_children(): # マウスカーソルを指差しに
		child.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for c in child.get_children():
			c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sign.modulate = Color(Color.WHITE) # 初期化
	sign.position.y = sign_pos.y
	next_sign_tween = get_tree().create_tween().bind_node(sign)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # 矢印アニメーション再生
	next_sign_tween.set_loops()
	next_sign_tween.tween_property(sign, "position:y", sign_pos.y - 25, 0.5)
	next_sign_tween.tween_property(sign, "position:y", sign_pos.y, 0.3)\
	.set_trans(Tween.TRANS_EXPO)
	next_sign_tween.tween_interval(0.5)

## メッセージ送りボタンアニメーション停止
func next_sign_off() -> void:
	if next_sign_tween and next_sign_tween.is_running():
		next_sign_tween.kill()
	for child in get_children(): # マウスカーソルをデフォルトに
		child.mouse_default_cursor_shape = Control.CURSOR_ARROW
		for c in child.get_children():
			c.mouse_default_cursor_shape = Control.CURSOR_ARROW
	sign.modulate = Color(Color.DIM_GRAY)
	next_sign_tween = get_tree().create_tween().bind_node(sign)\
	.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	next_sign_tween.tween_property(sign, "position:y", sign_pos.y, 0.5)\
	.set_trans(Tween.TRANS_EXPO)

func battle_finished() -> void:
	if tween and tween.is_running(): # ボタン点滅アニメーション停止
		tween.stop()
	if next_sign_tween and next_sign_tween.is_running():
		next_sign_tween.stop()
