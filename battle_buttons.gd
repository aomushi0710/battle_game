extends Control

const action_button = preload("res://技セレクトボタン.tscn")
const MONSTER_NAME_LIMIT: int = 8 ## statusに表示する上での、モンスターの名前の上限文字数
var now_showing: int ## 現在表示中のボタンメニュー[br]0:main 1:action 2:item 3:status 4:target 5:monsters
var now_player: bool ## true:現在playerの情報を表示 false:現在enemyの情報を表示
var monster: BattleMonster
var selected_action_button: Button
var button_index: int
var selected_action: Action
var tween: Tween
## チュートリアル用:ステータス表示の、playerかenemyかを選択するボタンが押された時のシグナル
signal player_or_enemy_button_pressed
## チュートリアル用:ステータスのテキストをページ送りされた時のシグナル
signal status_paging
## チュートリアル用:技説明テキストをページ送りされた時のシグナル
signal description_paging
## チュートリアル用:戻るボタンが押された時のシグナル
signal back

func _ready() -> void: # 初期値
	$"戻る".disabled = true
	now_showing = 0
	$change.texture_normal = Global.deck1.monster[0].image

## 技の対象を選ぶ必要がある時に表示されるボタンを生成する関数
func _on_action_button_selected(index: int) -> void:
	$"戻る".disabled = true
	selected_action_button = $action.get_child(index)
	button_index = index
	selected_action = selected_action_button.action # 選ばれた技を登録
	# 選ばれた技ボタンのアニメーション
	var instance = action_button.instantiate()
	instance.name = "selected"
	instance.texture_mode = preload("res://技セレクトボタン.gd").Mode.BATTLE
	instance.action = selected_action
	instance.position = Vector2(220, 841 + selected_action_button.position.y) # 選ばれたボタンの座標から取得
	instance.size = selected_action_button.size
	instance.add_theme_font_size_override("font_size", 40)
	add_child(instance)
	
	await hide_action_button()
	tween = get_tree().create_tween() # ボタン移動アニメーション
	tween.tween_property(instance, "position:y", 802, 0.5)\
	.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	
	await show_target_button()
	$"戻る".disabled = false
	tween = get_tree().create_tween() # ボタン点滅アニメーション
	tween.set_loops()
	tween.tween_property(instance, "modulate:a", 0, 0.5)
	tween.tween_property(instance, "modulate:a", 1, 0.5)
	# 技説明テキスト表示
	var descriptions: Array[String] = Global.action_description_creator(selected_action, true)
	var description_text = ["[i][u]%s[/u][/i]\n%s　　MP Cost:[color=aqua]%d[/color]\n" % 
		[selected_action.name, descriptions[0], selected_action.mp] + 
		"%s　　Power　:[color=red]%d[/color]" % [descriptions[1], selected_action.power]]
	for i in len(selected_action.ability):
		var ability_descriptions: Array = \
		Global.ability_description_creator(selected_action, 0, true)
		description_text.append("特殊効果:%s\n%s　　%s\n%s" % [ability_descriptions[0], 
		ability_descriptions[1], ability_descriptions[2], ability_descriptions[3]])
	if $"../".tutorial_mode == false:
		$dialogtab.text_setter(0, false, description_text)
	else:
		await $dialogtab.text_setter(0, true, description_text)
		description_paging.emit()
		

## メインのactionが押された時
func _on_action_button_up() -> void:
	await hide_main_button()
	show_action_button()

## メインのitemが押された時
func _on_item_button_up() -> void:
	now_showing = 2
	hide_main_button()
	$dialogtab.text_setter(0, false, ["未実装"])

## メインのstatusが押された時
func _on_status_button_up() -> void:
	await hide_main_button()
	show_player_or_enemy_button()

## メインボタン出現アニメーション
func show_main_button() -> void:
	$"戻る".disabled = true # まず戻るボタンを無効化し、エラーを回避
	now_showing = 0
	for button: Button in $main.get_children():
		button.show()
	tween = get_tree().create_tween() # ボタン出現アニメーション
	tween.tween_property($main, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	# メインボタンのため戻るボタンを有効化する必要なし

## メインボタン消失アニメーション
func hide_main_button() -> void:
	for button: Button in $main.get_children():
		button.disabled = true # 戻るボタンを押した後に入力を受け付けない
	tween = get_tree().create_tween() 
	tween.tween_property($main, "position:y", 1020, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for button: Button in $main.get_children():
		button.hide()
	if $"../".back_disabled == false:
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
		button.disabled = $"../".tutorial_mode
	if $"../".back_disabled == false:
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
	match selected_action.range: # 攻撃対象ごとに生成する画像が違う
		1, 2, 6: # 敵単体・敵散開
			for i in range(3):
				if $"../".tutorial_mode == true:
					match i: # 0体目をカカシに、1,2体目を隠す
						0:
							$target.get_child(i).texture_normal = \
							load("res://image/monster/カカシスライム.PNG")
						1, 2:
							$target.get_child(i).texture_normal = \
							load("res://null.PNG")
				else:
					if death_list[i] == true:
						$target.get_child(i).texture_normal = load("res://お墓.PNG")
					else:
						$target.get_child(i).texture_normal = Global.enemy_deck.monster[i].image
		3, 4: # 味方単体
			for i in range(3):
				if death_list[i + 3] == true:
					$target.get_child(i).texture_normal = load("res://お墓.PNG")
				else:
					$target.get_child(i).texture_normal = Global.deck1.monster[i].image
		5: # 自分
			for i in range(3):
				if i == monster.index:
					$target.get_child(i).texture_normal = monster.monster.image
				else :
					$target.get_child(i).texture_normal = load("res://null.PNG")
			
	$target.show()
	tween = get_tree().create_tween()
	tween.tween_property($target, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	if $"../".tutorial_mode == true:
		for child in $target.get_children(): # いかなるボタンも使用不可
			if child is TextureButton:
				child.disabled = true
	else:
		for child in $target.get_children(): # 最後にボタンを使用可能にするが、死体は使用不可にする
			if child is TextureButton:
				if child.texture_normal == load("res://お墓.PNG") or \
				   child.texture_normal == load("res://null.PNG"):
					child.disabled = true
				else:
					child.disabled = false

## target消滅アニメーション
func hide_target_button() -> void:
	if tween and tween.is_running(): # ボタン点滅アニメーション停止
		tween.kill()
	for child in $target.get_children():
		if child is TextureButton:
			child.disabled = true
		elif child is Button:
			child.queue_free()
	# ボタン消滅アニメーション　ツリーのポーズを無視
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($target, "position:y", 1020, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	$target.hide()

## 味方か相手を選択させるボタン出現アニメーション
func show_player_or_enemy_button() -> void:
	now_showing = 3
	for i in range(2):
		var button = Button.new()
		button.size = Vector2(200, 200)
		button.disabled = true
		if i == 0:
			button.name = "player"
			button.text = "Player\nStatus"
			button.position = Vector2(220, 1020)
			button.button_up.connect(func(): # ラムダ関数で次のボタン遷移処理
				await hide_player_or_enemy_button()
				show_monsters_button(true)
				player_or_enemy_button_pressed.emit())
			
		else:
			button.name = "enemy"
			button.text = "Enemy\nStatus"
			button.position = Vector2(430, 1020)
			button.button_up.connect(func():
				await hide_player_or_enemy_button()
				show_monsters_button(false))
		add_child(button)
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($player, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($enemy, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	$player.disabled = false
	if $"../".tutorial_mode == false:
		$enemy.disabled = false
	if $"../".back_disabled == false:
		$"戻る".disabled = false

## 味方か相手を選択させるボタン消滅アニメーション
func hide_player_or_enemy_button() -> void:
	$"戻る".disabled = true
	$player.disabled = true
	$enemy.disabled = true
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($player, "position:y", 1020, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($enemy, "position:y", 1020, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	$player.queue_free()
	$enemy.queue_free()

## デッキモンスター一覧ボタン出現アニメーション
func show_monsters_button(player: bool) -> void:
	now_showing = 5
	now_player = player
	var deck: Deck
	if player == true:
		deck = Global.deck1
	else:
		deck = Global.enemy_deck
	for i in range(3):
		$target.get_child(i).texture_normal = deck.monster[i].image
	$target.show()
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($target, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	for child: TextureButton in $target.get_children():
		child.disabled = false
	if $"../".back_disabled == false:
		$"戻る".disabled = false

## デッキモンスター一覧ボタン消滅アニメーション
func hide_monsters_button() -> void:
	$"戻る".disabled = true
	for child: TextureButton in $target.get_children():
		child.disabled = true
	tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($target, "position:y", 1020, 0.5)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	$target.hide()

## 戻るボタンが押された場合の、各種状態での挙動
func _on_戻る_button_up() -> void: # 戻る連打によるバグの発生をdisacleで阻止
	$"戻る".disabled = true
	match now_showing:
		-1: # バトル終了後、デッキセレクトに戻る
			battle_finished() # 初期化処理を呼ぶ
		1:
			if $"../".tutorial_mode == false:
				$dialogtab.flavor_text_setter($dialogtab.now_flavor_text)
			await hide_action_button()
			show_main_button()
			for button: Button in $main.get_children(): # 戻るボタンの時だけ利用可能に
				button.disabled = false
		2:
			show_main_button()
			for button: Button in $main.get_children(): # 戻るボタンの時だけ利用可能に
				button.disabled = false
		3: # 戻る 味方か相手選択 -> メイン
			if $"../".tutorial_mode == false:
				$dialogtab.flavor_text_setter($dialogtab.now_flavor_text)
			await hide_player_or_enemy_button()
			show_main_button()
			for button: Button in $main.get_children(): # 戻るボタンの時だけ利用可能に
				button.disabled = false
		4: # 戻る ターゲット選択 -> 技選択
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
		5: # 戻る モンスター一覧 -> 味方か相手選択
			await hide_monsters_button()
			show_player_or_enemy_button()
	if $"../".tutorial_mode == true:
		back.emit()


func _on_escape_button_up() -> void: # 逃げるボタン処理 TODO 逃げられないバトル用の処理なども作る
	if $"../".tutorial_mode == true:
		$"../確認メッセージ".title = "チュートリアル終了"
		$"../確認メッセージ".dialog_text = "チュートリアルを終わりますか？\nチュートリアルはいつでもプレイ可能です。"
	else:
		$"../確認メッセージ".title = "バトル終了"
		$"../確認メッセージ".dialog_text = "バトルに敗北したことになりますが、本当に逃げますか？"
	$"../確認メッセージ".popup_centered()


func battle_finished() -> void: # バトル終了初期化処理
	if tween and tween.is_running(): # ボタン点滅アニメーション停止
		tween.kill()
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
	Global.battle_stage = Global.Stage.PLAIN # とりあえず草原ステージ
	await $dialogtab.battle_finished()
	await $"../../background".battle_finished()
	get_tree().change_scene_to_packed(Global.deck_scene)


func _on_target_1_button_up() -> void:
	if now_showing == 4: # 技の対象を選んだ時の動作
		target_button_up(0)
	elif now_showing == 5:
		status_dialog(0)

func _on_target_2_button_up() -> void:
	if now_showing == 4:
		target_button_up(1)
	elif now_showing == 5:
		status_dialog(1)

func _on_target_3_button_up() -> void:
	if now_showing == 4:
		target_button_up(2)
	elif now_showing == 5:
		status_dialog(2)

## 発動する技とそのターゲットが確定した時、各種情報をまとめて引数を渡す関数
func target_button_up(i: int) -> void:
	if tween and tween.is_running(): # ボタン点滅アニメーション停止
		tween.kill()
	$"戻る".disabled = true
	for child in $target.get_children():
		child.disabled = true
	tween = get_tree().create_tween() # 選ばれた技ボタン消滅アニメーション
	tween.tween_property($selected, "modulate:a", 0, 0.5)
	await tween.finished
	if $selected:
		$selected.queue_free()
	
	get_parent().command_selected(true, monster, selected_action, i)
	
	if $target.visible == true: # target画面が見えてるなら隠す
		await hide_target_button()
	show_main_button() # 最初の表示に戻す ボタンは利用不可のまま
	
	$action.remove_child(selected_action_button) # 選ばれた技ボタンを最後に消す
	if selected_action_button:
		selected_action_button.queue_free()
	monster.picked_action.remove_at(button_index) # モンスターの技一覧から消す

## モンスターのステータスをダイアログにセットして表示する関数
func status_dialog(i: int) -> void:
	var status_monster: Monster
	if now_player == true:
		status_monster = Global.deck1.monster[i]
	else:
		status_monster = Global.enemy_deck.monster[i]
	
	var monster_name: String = status_monster.name
	if len(monster_name) > MONSTER_NAME_LIMIT: # 10文字より多ければ
		monster_name = monster_name.substr(0, MONSTER_NAME_LIMIT) # 無理やり10文字にする
	else:
		for j in MONSTER_NAME_LIMIT - len(monster_name): # 空白を増やして10文字に
			monster_name += "　" # 空白は全角である
	
	# チュートリアル中は、ページ送りを待つ
	if $"../".tutorial_mode == true:
		await $dialogtab.text_setter(1, $"../".tutorial_mode, [
		"%s[color=coral]HP :%3d[/color]   [color=green]SPD:%3d[/color]\n" % 
		[monster_name, status_monster.maxHP, status_monster.SPD] + 
		"[color=aqua]MP :%3d / %3d[/color]   " % 
		[status_monster.supplyMP, status_monster.maxMP] + 
		"[color=red]ATK:%3d[/color]   [color=light_blue]DEF:%3d[/color]\n" % 
		[status_monster.ATK, status_monster.DEF] + "[color=aqua](supply / max)[/color]  " + 
		"[color=dodger_blue]MAG:%3d[/color]   [color=violet]RES:%3d[/color]" % 
		[status_monster.MAG, status_monster.RES]])
		status_paging.emit()
	else:
		$dialogtab.text_setter(1, $"../".tutorial_mode, [
		"%s[color=coral]HP :%3d[/color]   [color=green]SPD:%3d[/color]\n" % 
		[monster_name, status_monster.maxHP, status_monster.SPD] + 
		"[color=aqua]MP :%3d / %3d[/color]   " % 
		[status_monster.supplyMP, status_monster.maxMP] + 
		"[color=red]ATK:%3d[/color]   [color=light_blue]DEF:%3d[/color]\n" % 
		[status_monster.ATK, status_monster.DEF] + "[color=aqua](supply / max)[/color]  " + 
		"[color=dodger_blue]MAG:%3d[/color]   [color=violet]RES:%3d[/color]" % 
		[status_monster.MAG, status_monster.RES]])
