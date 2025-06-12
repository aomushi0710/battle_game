extends Control

const action_button = preload("res://技セレクトボタン.tscn")
var now_showing: int # 0:main 1:action 2:item 3:status 4:target
var monster: BattleMonster
var selected_action_button: Button
var button_index: int
var selected_action: Action
var tween: Tween


func _on_tree_entered() -> void: # 初期値
	now_showing = 0
	$change.texture_normal = Global.deck1.monster[0].image

## メインのactionが押された時
func _on_action_button_up() -> void:
	await hide_main_button()
	show_action_button()

## 技の対象を選ぶ必要がある時に表示されるボタンを生成する関数
func _on_action_button_selected(i: int) -> void:
	$"戻る".disabled = true
	selected_action_button = $action.get_child(i)
	button_index = i
	var instance = action_button.instantiate()
	selected_action = selected_action_button.action # 選ばれた技を登録
	instance.name = "selected"
	instance.action = selected_action
	instance.position = Vector2(132, 485 + 40 * i)
	instance.size = selected_action_button.size
	instance.add_theme_font_size_override("font_size", 25)
	add_child(instance)
	
	await hide_action_button()
	tween = get_tree().create_tween() # ボタン移動アニメーション
	tween.tween_property(instance, "position:y", 483, 0.5)\
	.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	
	match selected_action.range:
		1, 3, 6: # ターゲットを選ぶ必要のある技の時
			await show_target_button()
			$"戻る".disabled = false
			tween = get_tree().create_tween() # ボタン点滅アニメーション
			tween.set_loops()
			tween.tween_property(instance, "modulate:a", 0, 0.5)
			tween.tween_property(instance, "modulate:a", 1, 0.5)
		5:
			target_button_up(monster.index) # 自分のindex
		_:
			target_button_up(-1) # 引数-1:index指定なし


func _on_item_button_up() -> void:
	now_showing = 2
	hide_main_button()


func _on_status_button_up() -> void:
	now_showing = 3
	hide_main_button()

## メインボタン出現アニメーション
func show_main_button() -> void:
	$"戻る".disabled = true # まず戻るボタンを無効化し、エラーを回避
	now_showing = 0
	for button: Button in $main.get_children():
		button.show()
	tween = get_tree().create_tween() # ボタン出現アニメーション
	tween.tween_property($main, "position:y", 523, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	# メインボタンのため戻るボタンを有効化する必要なし

## メインボタン消失アニメーション
func hide_main_button() -> void:
	for button: Button in $main.get_children():
		button.disabled = true # 戻るボタンを押した後に入力を受け付けない
	tween = get_tree().create_tween() 
	tween.tween_property($main, "position:y", 648, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for button: Button in $main.get_children():
		button.hide()
	$"戻る".disabled = false

## action出現アニメーション
func show_action_button() -> void:
	now_showing = 1
	for child in $action.get_children():
		child.modulate.a = 0
	$action.show() # 透明にしてから表示
	tween = get_tree().create_tween() # 順番にアニメーションするためにcreate_tween()を外に出す
	for child in $action.get_children():
		tween.tween_property(child, "modulate:a", 1, 0.2)
	for button: Button in $action.get_children():
		button.disabled = false
	$"戻る".disabled = false

## action消滅アニメーション
func hide_action_button() -> void:
	for button: Button in $action.get_children():
		button.disabled = true
	tween = get_tree().create_tween()
	tween.tween_property($action, "modulate:a", 0, 0.2)
	await tween.finished
	$action.hide()
	$action.modulate.a = 1 # 初期化

## target出現アニメーション
func show_target_button() -> void:
	now_showing = 4
	var death_list: Array[bool] = \
	[Global.e1_death, Global.e2_death, Global.e3_death, \
	Global.p1_death, Global.p2_death, Global.p3_death] # for文用真理値配列
	var target_list: Array[TextureButton] = \
	[$target/target1, $target/target2, $target/target3] # for文用ノード配列
	match selected_action.range: # 攻撃対象ごとに生成する画像が違う
		1, 6: # 敵単体・敵散開
			for i in range(3):
				if death_list[i] == true:
					target_list[i].texture_normal = load("res://お墓.PNG")
				else:
					target_list[i].texture_normal = Global.enemy_deck.monster[i].image
		3: # 味方単体
			for i in range(3):
				if death_list[i + 3] == true:
					target_list[i].texture_normal = load("res://お墓.PNG")
				else:
					target_list[i].texture_normal = Global.deck1.monster[i].image
	$target.show()
	tween = get_tree().create_tween()
	tween.tween_property($target, "position:y", 523, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for child in $target.get_children(): # 最後にボタンを使用可能にするが、死体は使用不可にする
		if child is TextureButton:
			if child.texture_normal == load("res://お墓.PNG"):
				child.disabled = true
			else:
				child.disabled = false

## target消滅アニメーション
func hide_target_button() -> void:
	for child in $target.get_children():
		if child is TextureButton:
			child.disabled = true
		elif child is Button:
			child.queue_free()
	# ボタン出現アニメーション　ツリーのポーズを無視
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($target, "position:y", 648, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	$target.hide()

## 戻るボタンが押された場合の、各種状態での挙動
func _on_戻る_button_up() -> void: # 戻る連打によるバグの発生をdisacleで阻止
	match now_showing:
		1: # action消滅アニメーション
			$"戻る".disabled = true
			# TODO 現在は仮の文章　後々、デフォルトのものを挿入できるようにする
			$dialogtab.tab_list[0] = ["This is test message with animation!\n" + 
			"[color=red][b]BBcode is available.[/b][/color]"]
			$dialogtab._on_tab_changed(0)
			await hide_action_button()
			show_main_button()
			for button: Button in $main.get_children(): # 戻るボタンの時だけ利用可能に
				button.disabled = false
		2, 3:
			$"戻る".disabled = true
			show_main_button()
			for button: Button in $main.get_children(): # 戻るボタンの時だけ利用可能に
				button.disabled = false
		4: # 戻る ターゲット選択 -> 技選択
			$"戻る".disabled = true
			if tween and tween.is_running(): # ボタン点滅アニメーション停止
				tween.kill()
			for child in get_children():
				if child.name == "selected": # selectedノードのみ消す
					tween = get_tree().create_tween() # ボタン消滅アニメーション
					tween.tween_property(child, "modulate:a", 0, 0.2)
					await tween.finished
					child.queue_free()
			await hide_target_button()
			show_action_button()


func _on_escape_button_up() -> void: # 逃げるボタン処理 TODO 逃げられないバトル用の処理なども作る
	$"../確認メッセージ".title = "バトル終了"
	$"../確認メッセージ".dialog_text = "バトルに敗北したことになりますが、本当に逃げますか？"
	$"../確認メッセージ".popup_centered()


func _on_確認メッセージ_confirmed() -> void: # バトル終了初期化処理
	Global.p1_death = false
	Global.p2_death = false
	Global.p3_death = false
	Global.e1_death = false
	Global.e2_death = false
	Global.e3_death = false
	get_tree().paused = false
	for i in range(3):
		Global.deck1.monster[i] = Global.deck1.monster_dict[i][0]
		Global.deck1.effect[i].clear()
		
		for j: int in len(Global.deck1.action[i]):
			var e := 0 # evolution用index
			var m := 0 # middle_evolution湯index
			match Global.deck1.action[i][j].id:
				10002: # 進化Ⅱが残っている場合
					Global.deck1.action[i][j] = Global.deck1.evolution[i][e] # 元に戻す
					e += 1
				10001: # 進化Ⅰが残っている場合
					Global.deck1.action[i][j] = Global.deck1.middle_evolution[i][m]
					m += 1
	
	for i in range(3):
		Global.enemy_deck.monster[i] = Global.enemy_deck.monster_dict[i][0]
		Global.enemy_deck.effect[i].clear()
	Global.deck_creator(Global.enemy_deck) # 敵デッキ生成
	get_tree().change_scene_to_packed(Global.deck_scene)


func _on_target_1_button_up() -> void:
	target_button_up(0)

func _on_target_2_button_up() -> void:
	target_button_up(1)

func _on_target_3_button_up() -> void:
	target_button_up(2)

## 発動する技とそのターゲットが確定した時、各種情報をまとめて引数を渡す関数
func target_button_up(i: int) -> void:
	$"戻る".disabled = true
	tween = get_tree().create_tween() # 選ばれた技ボタン消滅アニメーション
	tween.tween_property($selected, "modulate:a", 0, 0.5)
	await tween.finished
	$selected.queue_free()
	
	get_parent().command_selected(true, monster, selected_action, i)
	
	if $target.visible == true: # target画面が見えてるなら隠す
		await hide_target_button()
	show_main_button() # 最初の表示に戻す ボタンは利用不可のまま
	
	$action.remove_child(selected_action_button) # 選ばれた技ボタンを最後に消す
	selected_action_button.queue_free()
	monster.picked_action.remove_at(button_index) # モンスターの技一覧から消す
