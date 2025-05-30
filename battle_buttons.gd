extends Control

var now_showing: int # 0:main 1:action
var tween: Tween


func _on_tree_entered() -> void: # 初期値
	now_showing = 0
	$change.texture_normal = Global.deck1.monster[0].image


func _on_action_button_up() -> void:
	now_showing = 1
	hide_main_button()


func _on_item_button_up() -> void:
	now_showing = 2
	hide_main_button()


func _on_status_button_up() -> void:
	now_showing = 3
	hide_main_button()


func hide_main_button() -> void: # メインボタンを下に動かし消失させる
	for button: Button in $main.get_children():
		button.disabled = true
	tween = get_tree().create_tween() # ボタン消失アニメーション
	tween.tween_property($main, "position:y", 648, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for button: Button in $main.get_children():
		button.hide()
	$"戻る".disabled = false


func show_main_button() -> void: # メインボタンを上に動かし出現させる
	$"戻る".disabled = true
	for button: Button in $main.get_children():
		button.show()
	tween = get_tree().create_tween() # ボタン出現アニメーション
	tween.tween_property($main, "position:y", 523, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for button: Button in $main.get_children():
		button.disabled = false


func _on_戻る_button_up() -> void:
	match now_showing:
		0:
			pass
		1, 2, 3:
			show_main_button()


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
