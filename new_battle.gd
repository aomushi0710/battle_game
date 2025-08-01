extends Control

const monster_scene = preload("res://battle_monster.tscn")
const action_button = preload("res://技セレクトボタン.tscn")
@onready var dialog = $button/dialogtab
var tween: Tween
var player_next_index: int = 0 # 次にチェンジするモンスターのindex
var enemy_next_index: int = 0
var player_deck: Array[BattleMonster]
var enemy_deck: Array[BattleMonster]
var player_monster: BattleMonster
var enemy_monster: BattleMonster
var tutorial_mode: bool = false ## true:チュートリアル
var back_disabled: bool = false ## 全ての戻るボタンが true:使用不可 false:使用可能
## 死亡時に交代するモンスターが選ばれるまで待つawait用シグナル
signal changed
## チュートリアル用:バトル開始カットイン完了シグナル
signal cutin_ended
## チュートリアル用:プレイヤーモンスター行動可能シグナル
signal player_ready
## チュートリアル用:モンスター行動完了シグナル
signal command_ended

# 味方と敵のデッキを準備
func _ready() -> void:
	await battle_start_animation()
	await get_tree().process_frame # 1フレーム待つ
	for deck in [Global.deck1, Global.enemy_deck]:
		for i: int in len(deck.monster):
			var monster: BattleMonster = monster_scene.instantiate()
			monster.index = i
			monster.setup(deck.monster_dict[i], deck.monster[i], deck.action[i], 
			deck.middle_evolution[i], deck.evolution[i], deck.chance[i])
			monster.text_setter_callback = Callable(dialog, "text_setter")
			match deck:
				Global.deck1:
					monster.player = true
					monster.name = "player%d" % (i + 1)
					if i == 0:
						player_monster = monster
						monster.position = Vector2(-256, 350)
						add_child(monster)
						await get_tree().process_frame # 1フレーム待つ
						monster.get_node("SPD").set_process(true)
						monster.get_node("HP/text").show()
						monster.get_node("MP/text").show()
					else:
						$player_deck/player_deck.add_child(monster)
						await get_tree().process_frame # 1フレーム待つ
						monster.get_node("SPD").set_process(false)
						monster.get_node("HP/text").hide()
						monster.get_node("MP/text").hide()
						monster.get_node("SPD").hide()
					player_deck.append(monster)
					monster.button_up.connect(func():monster_button_up(monster.index))
				Global.enemy_deck:
					monster.player = false
					monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
					monster.name = "enemy%d" % (i + 1)
					if i == 0:
						enemy_monster = monster
						monster.position = Vector2(1664, 350)
						self.add_child(monster)
						await get_tree().process_frame # 1フレーム待つ
						if tutorial_mode == false:
							monster.get_node("SPD").set_process(true)
						else:
							monster.get_node("SPD").set_process(false)
						monster.get_node("HP/text").show()
						monster.get_node("MP/text").show()
					else:
						$enemy_deck/enemy_deck.add_child(monster)
						await get_tree().process_frame # 1フレーム待つ
						monster.get_node("SPD").set_process(false)
						monster.get_node("HP/text").hide()
						monster.get_node("MP/text").hide()
						monster.get_node("SPD").hide()
					enemy_deck.append(monster)
			monster.parent_getter()
			monster.show()
			# シグナル接続
			# モンスター行動可能通知シグナル
			monster.monster_ready.connect(func():monster_ready(monster.player))
	
	player_next_index = 2
	_on_change_button_up()
	# シーン遷移アニメーション
	tween = get_tree().create_tween() # monster出現アニメーション
	tween.tween_property($player1, "position:x", 500, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($enemy1, "position:x", 1164, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($player_deck, "position:x", 0, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($enemy_deck, "position:x", 1170, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_callback(func():
		if tutorial_mode == true:
			cutin_ended.emit())

## バトル開始カットインのアニメーション
func battle_start_animation() -> void:
	$"../fade".color.a = 1
	$"../fade".show()
	$"../result_rect".hide()
	$"../result_rect/win".hide()
	$"../result_rect/lose".hide()
	$button/next_sign.hide()
	$button/escape.disabled = true
	$"button/戻る".disabled = true
	$button/escape.modulate.a = 0
	$"button/戻る".modulate.a = 0
	$button/dialogtab.modulate.a = 0
	$button/next_sign.modulate.a = 0
	$button/change.modulate.a = 0
	$button/main.position.y = 1080
	dialog.set_tab_disabled(1, true)
	dialog.set_tab_disabled(2, true)
	for button: Button in $button/main.get_children():
			button.disabled = true
	
	tween = get_tree().create_tween()
	tween.tween_property($"../fade", "color:a", 0, 1)
	tween.tween_interval(1)
	tween.tween_callback(func(): 
		$"../fade".hide()
		$"../battlestart".modulate.a = 1
		$"../battlestart".show())
	tween.tween_property($"../battlestart", "scale", Vector2(1.2, 1.2), 0.4)
	tween.tween_property($"../battlestart", "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property($"../battlestart", "modulate:a", 0, 0.5)
	tween.tween_callback(func(): 
		$"../battlestart".scale = Vector2(0, 0)
		$"../battlestart".hide())
	tween.tween_interval(0.5)
	tween.tween_property($button/escape, "modulate:a", 1, 0.5)
	tween.parallel().tween_property($"button/戻る", "modulate:a", 1, 0.5)
	tween.parallel().tween_property($button/dialogtab, "modulate:a", 1, 0.5)
	tween.parallel().tween_property($button/change, "modulate:a", 1, 0.5)
	tween.parallel().tween_property($button/main, "position:y", 865, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	
	$button/escape.disabled = false
	$button/next_sign.show()
	if tutorial_mode == false:
		dialog.now_flavor_text = ["ついにこの戦いが始まった。"]
		dialog.text_setter(0, false, dialog.now_flavor_text)

# spdgaugeが溜まり行動可能になった時
func monster_ready(player: bool) -> void:
	# spdゲージ停止
	player_monster.get_node("SPD").set_process(false)
	enemy_monster.get_node("SPD").set_process(false)
	if player_monster.get_node("SPD").value == enemy_monster.get_node("SPD").value:
		enemy_monster.get_node("SPD").value -= 10
	if player == true: # プレイヤーが行動可能になった時
		dialog.set_tab_disabled(1, false)
		dialog.set_tab_disabled(2, false)
		$button.monster = player_monster # 現在フィールドにいるモンスターを渡す
		var original_mp: int = player_monster.monster.MP ## MP回復前の値を保持しておく 
		player_monster.mp_setter(player_monster.monster.supplyMP, false) # mp回復
		
		for button in $button/action.get_children(): # 全てのボタンを一旦削除
			button.queue_free()
		# 抽選された技をactionコンテナに追加
		for i in len(player_monster.picked_action):
			var instance = action_button.instantiate()
			instance.texture_mode = preload("res://技セレクトボタン.gd").Mode.BATTLE
			instance.action = player_monster.picked_action[i]
			instance.text = player_monster.picked_action[i].name
			instance.button_up.connect(func():select_command(i))
			$button/action.add_child(instance)
		
		# 全てのボタン有効化
		for button: Button in $button/main.get_children():
			button.disabled = false
		# dialog更新
		if tutorial_mode == false:
			var text: Array[String] = set_ready_text(player_monster, original_mp)
			dialog.text_setter(0, false, text) # 味方の時はコマンド選択を待つ
		else:
			player_ready.emit()
	else:
		var original_mp: int = enemy_monster.monster.MP ## MP回復前の値を保持しておく
		enemy_monster.mp_setter(enemy_monster.monster.supplyMP, false)
		
		enemy_next_index = random_index(false) # 相手側の次に行動するモンスターをランダムにチェンジ
		
		var text: Array[String] = set_ready_text(enemy_monster, original_mp)
		await dialog.text_setter(0, true, text)
		
		var button_index = randi() % 4 # 味方モンスターと同じ変数名を使用
		var action: Action = enemy_monster.picked_action[button_index]
		var action_index: int
		match action.range:
			1, 6: # 敵単体・敵散開
				action_index = random_index(true)
			3: # 味方単体
				action_index = random_index(false)
			5: # 自分
				action_index = enemy_monster.index
			_:
				action_index = -1
		command_selected(false, enemy_monster, action, action_index)
		enemy_monster.picked_action.remove_at(button_index)

## 死亡フラグを考慮してindexをランダムに指定する関数[br]true:味方index false:敵index
func random_index(player: bool) -> int:
	var death_list: Array[bool] = [
		Global.p1_death, Global.p2_death, Global.p3_death, 
		Global.e1_death, Global.e2_death, Global.e3_death]
	var index: int
	if player == true:
		while  true:
			index = randi() % 3
			if death_list[index] == false: # 生きていれば終了
				break
	else:
		while  true:
			index = randi() % 3
			if death_list[index + 3] == false:
				break
	
	return index

## モンスターを引数として、そのモンスターが行動可能になった時に表示されるテキストを返す関数
## 引数mpは、mpが自動回復する前に保持されていたmp。比較用に利用する
func set_ready_text(monster: BattleMonster, mp: int) -> Array[String]:
	var mp_text: String = "" ## 自動MP回復によるテキスト
	if mp < monster.monster.maxMP: # MPが満タンでない時
		if (monster.monster.maxMP - mp) < monster.monster.supplyMP: # MP回復量が最大MPを越してしまう時
			mp_text = "%s は[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % \
			[monster.monster.name, monster.monster.maxMP - mp]
		else: # supplyMPだけ全て回復しても問題ない時
			mp_text = "%s は[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % \
			[monster.monster.name, monster.monster.supplyMP]
	
	var text: String ## 敵か味方かで変わるテキスト
	if monster.player == true:
		text = "[color=yellow]%s は指示を待っている...[/color]" % monster.monster.name
	else:
		text = "[color=yellow]相手の %s の行動！[/color]" % monster.monster.name
	
	
	return ["%s が行動可能になった。\n%s\n%s" % [monster.monster.name, mp_text, text]]

## ターン終了後にフィールドに立つモンスターのindexと画像を設定します
func _on_change_button_up() -> void:
	if ( # 全員死んでるなら無視
		player_deck[0].death == true and 
		player_deck[1].death == true and 
		player_deck[2].death == true):
		return
	
	while true: # 生きているモンスターになるまで自動で繰り返す
		match player_next_index:
			0, 1:
				player_next_index += 1
			2:
				player_next_index = 0
		if player_deck[player_next_index].death == false:
			break
	$button/change.texture_normal = Global.deck1.monster[player_next_index].image
	if player_monster.index != player_next_index:
		changed.emit()

## モンスターのボタンを押して、ターン終了後にフィールドに立つモンスターのindexと画像を設定します
func monster_button_up(i: int) -> void:
	if player_deck[i].death == false: # 生きてたら
		player_next_index = i
		if player_monster.index != player_next_index:
			$button/change.texture_normal = Global.deck1.monster[player_next_index].image
			changed.emit()

## buttonスクリプト接続用関数
func select_command(i: int) -> void:
	$button._on_action_button_selected(i)

## 技発動関数[br]player:trueなら味方の行動、falseなら相手の行動
func command_selected(player: bool, monster: BattleMonster, action: Action, index: int)\
 -> void:
	dialog.set_tab_disabled(1, true)
	dialog.set_tab_disabled(2, true)
	var dialog_text: Array[String] # ダイアログに表示するテキストを収納する
	# 何らかの理由で発動できない技の場合に中断する処理
	# 第1形態から最終形態にスキップするのを防止
	if len(monster.monster_dict) == 3 \
	and monster.monster.form == 0 and action.id == 10002:
		await dialog.text_setter(0, true, [
		"[color=yellow]%s はまだ最終形態には進化できない！[/color]\n先に第2形態に進化してください！" % 
		monster.monster.name])
	# mpが足りない場合
	elif monster.monster.MP < action.mp:
		await dialog.text_setter(0, true, [
		"%s の %s！\n[color=yellow]しかし、[color=aqua]MP[/color]が足りない！[/color]" % 
		[monster.monster.name, action.name]])
	else:
		var target_list: Array[BattleMonster] = target_setting(player, action, index)
		
		if action.mp != 0: # mp消費処理
			dialog_text = monster.mp_setter(-action.mp, true)
		dialog_text.append("%s の %s！" % [monster.monster.name, action.name])
		await dialog.text_setter(0, true, dialog_text)
		
		if action.id == 10001 or action.id == 10002:
			dialog_text = monster.evolution(action.id)
			await dialog.text_setter(0, true, dialog_text)
		
		for i in len(action.ability): # 全ての特殊能力について順番に処理
			if randi() % 100 + 1 > action.ability_chance[i]: # 確率範囲外ならその効果の処理スキップ
				continue
			var ability = action.ability[i]
			var ability_target_list: Array[BattleMonster] = \
			ability_target_setting(player, action, index, i, monster)
			
			for target in ability_target_list: # 全ての対象について順番に処理
				match ability.category:
					1: # 状態異常 TODO 未実装
						pass
					2, 3: # バフ or デバフ
						if ability.effect in target.effect_dict: # 既に発動中ならターン延長
							target.effect_dict[ability.effect] += action.ability_power[i]
						else:
							target.effect_dict[ability.effect] = action.ability_power[i]
						target.effect_icon()
						await dialog.text_setter(0, true, [
						"%s %s" % [target.monster.name, ability.effect.log]])
						# もし自分に与えるエフェクトだった場合、発動時にも1ターン減るので付け足す
						if monster == target:
							target.effect_dict[ability.effect] += 1
						match ability.category:
							2: # バフ効果音
								$"../SoundEffects/buff".play()
							3: # デバフ効果音
								$"../SoundEffects/debuff".play()
					4: # 回復
						var heal: int # 回復量
						match ability.healing:
							1: # ステータス参照HP回復
								match action.damage_type:
									1: # 物理 
										heal = monster.monster.ATK * \
										(float(action.ability_power[i]) / 100)
									2: # 魔法 
										heal = monster.monster.MAG * \
										(float(action.ability_power[i]) / 100)
							2: # 定数HP回復
								heal = action.ability_power[i]
						dialog_text = target.hp_setter(heal, true)
						await dialog.text_setter(0, true, dialog_text)
		
		if action.power != 0:
			for target: BattleMonster in target_list: # 対象にダメージをあたえる
				var damage_array = damage_calc(action, monster, target)
				dialog_text = [] # 初期化
				var text: Array[String] = target.hp_setter(-damage_array[0], true)
				for t: String in text: # Array[String]から要素を抜き出す
					t += "\n%s" % damage_array[1] # ダメージ相性のテキストを追加
					dialog_text.append(t)
			await dialog.text_setter(0, true, dialog_text)
		
		for target: BattleMonster in target_list:
			if target.monster.HP <= 0: # 死亡時処理
				await target.dead(player_monster, enemy_monster)
	
	turn_end(player, monster)


func item_selected(player: bool, monster: BattleMonster, item: Item, index: int) -> void:
	dialog.set_tab_disabled(1, true)
	dialog.set_tab_disabled(2, true)
	# アイテム名10文字以下なら1行で表示可能
	await dialog.text_setter(0, true, ["%s Lv.%dを使った！" % [item.name, item.get_level()]])
	var target_list: Array[BattleMonster] = target_setting(player, item, index)
	for target: BattleMonster in target_list:
		match item.id:
			1: # ライフポーション
				await item_animation(item, target)
				var text: Array[String] = target.hp_setter( # 最終的には小数点切り捨て
					target.monster.maxHP * (item.get_power(item.get_level()) / 100.0), true)
				await dialog.text_setter(0, true, text)
			2: # マナポーション
				await item_animation(item, target)
				var text: Array[String] = target.mp_setter( # 最終的には小数点切り捨て
					target.monster.maxMP * (item.get_power(item.get_level()) / 100.0), true)
				await dialog.text_setter(0, true, text)
	
	turn_end(player, monster)

## アイテム使用時のアニメーションを再生する関数
func item_animation(item: Item, monster: BattleMonster) -> void:
	match item.id:
		1, 2: # ライフポーション、マナポーション
			# ポーションを投げてモンスターに当てるアニメーション
			var item_node = TextureRect.new()
			item_node.texture = item.image
			item_node.position = Vector2(500, 350)
			item_node.pivot_offset = item_node.size / 2
			add_child(item_node)
			var item_tween: Tween = item_node.create_tween()
			item_tween.tween_property(item_node, "rotation_degrees", 360, 0.5)
			item_tween.parallel().tween_property(item_node, "position:y", 222, 0.5)
			item_tween.parallel().tween_property(item_node, "scale", Vector2(0.8, 0.8), 0.5)
			item_tween.parallel().tween_property(item_node, "modulate:a", 0.8, 0.5)
			item_tween.tween_callback(func(): item_node.rotation_degrees = -360)
			item_tween.tween_property(item_node, "rotation_degrees", 360, 1)
			item_tween.parallel().tween_property(item_node, "position", monster.position, 1)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
			item_tween.parallel().tween_property(item_node, "scale", Vector2(0.4, 0.4), 1)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
			item_tween.parallel().tween_property(item_node, "modulate:a", 0, 1)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
			await item_tween.finished
			item_node.queue_free()

## モンスターの行動終了時の処理
func turn_end(player: bool, monster: BattleMonster) -> void:
	# 相手全滅
	if Global.e1_death == true and Global.e2_death == true and Global.e3_death == true:
		return
	# 味方全滅
	elif Global.p1_death == true and Global.p2_death == true and Global.p3_death == true:
		return
	
	monster.get_node("SPD").value = 0
	for effect in monster.effect_dict: # エフェクトを1ターン縮める
		monster.effect_dict[effect] -= 1
		if monster.effect_dict[effect] == 0:
			monster.effect_dict.erase(effect)
	monster.effect_icon()
	
	# モンスター交代
	if player == true and player_monster != player_deck[player_next_index]:
		player_monster.bench_set() # フィールドのモンスターをベンチに
		player_monster = player_deck[player_next_index]
		player_monster.field_set() # 次に指定されたモンスターをフィールドに
	elif player == false and enemy_monster != enemy_deck[enemy_next_index]:
		enemy_monster.bench_set()
		enemy_monster = enemy_deck[enemy_next_index]
		enemy_monster.field_set()
	
	# 死んでなきゃSPDゲージ再開
	if player_monster.death == false:
		player_monster.get_node("SPD").set_process(true)
	if tutorial_mode == false:
		if enemy_monster.death == false:
			enemy_monster.get_node("SPD").set_process(true)
	
	if player == true: # 味方モンスターが動いた後にフレーバーテキスト更新
		
		var result = randi() % 4 ## 50%:ステージ 25%:味方モンスター 25%:相手モンスター
		var matching: bool = false ## false:フレーバーテキスト一覧が空
		match result:
			0, 1:
				if len(dialog.stage_flavor_text) != 0: # フレーバーテキストがあれば
					dialog.now_flavor_text = \
					dialog.stage_flavor_text[randi() % len(dialog.stage_flavor_text)]
					matching = true
			2:
				if len(player_monster.monster.flavor_text) != 0: # フレーバーテキストがあれば
					dialog.now_flavor_text = \
					[player_monster.monster.flavor_text[randi() % len(player_monster.monster.flavor_text)]]
					matching = true
			3:
				if len(enemy_monster.monster.flavor_text) != 0: # フレーバーテキストがあれば
					dialog.now_flavor_text = \
					[enemy_monster.monster.flavor_text[randi() % len(enemy_monster.monster.flavor_text)]]
					matching = true
		if matching == false: # なければグローバルフレーバーテキスト
			dialog.now_flavor_text = \
			dialog.global_flavor_text[randi() % len(dialog.global_flavor_text)]
	# flavor_text一覧更新
	if tutorial_mode == false:
		dialog.flavor_text_setter(dialog.now_flavor_text) # フレーバーテキスト設定
	else:
		command_ended.emit()

## バトル終了処理 win true:勝利 false:敗北
func battle_finish(win: bool) -> void:
	$button.now_showing = -1
	$"../result_rect".show()
	if win == true:
		var coins: int = 0 ## 合計コイン枚数
		for i in range(3): # コイン獲得
			coins += enemy_deck[i].monster.coin
		Global.coin_setter(coins)
		$"../result_rect/win".show()
		dialog.text_setter(0, false, [
		"[b][color=red]勝利！[/color][/b]\n" + \
		"[color=gold]%dコイン[/color]を手に入れた！\n" % coins + \
		"左下の戻るボタンを押してバトルを終了"])
		
	else:
		$"../result_rect/lose".show()
		dialog.text_setter(0, false, [
		"[b][color=dodger_blue]敗北...[/color][/b]\n\n左下の戻るボタンを押してバトルを終了 "])

## 技の発動先targetを設定する関数 actionにはAction型かItem型が入る
func target_setting(player: bool, action, index: int) -> Array[BattleMonster]:
	var target_list: Array[BattleMonster] # 技の発動対象
	if player == true:
		match action.range:
			1, 6: # 敵単体 or 敵散開
				target_list.append(enemy_deck[index])
			3, 5: # 味方単体 or 自分
				target_list.append(player_deck[index])
			2: # 敵全体
				for mon in enemy_deck:
					target_list.append(mon)
			4: # 味方全体
				for mon in player_deck:
					target_list.append(mon)
	else:
		match action.range:
			1, 6: # 敵単体 or 敵散開
				target_list.append(player_deck[index])
			3, 5: # 味方単体 or 自分
				target_list.append(enemy_deck[index])
			2: # 敵全体
				for mon in player_deck:
					target_list.append(mon)
			4: # 味方全体
				for mon in enemy_deck:
					target_list.append(mon)
	return target_list

## 特殊効果の発動先targetを設定する関数[br]i:繰り返し回数 monster:対象が自分の時用
func ability_target_setting(player: bool, action: Action, index: int, i: int, \
monster: BattleMonster) -> Array[BattleMonster]:
	var target_list: Array[BattleMonster] # 特殊効果の発動対象
	if action.ability_range[i] == 0:
		target_list = target_setting(player, action, index) # actionのものと同期
	elif player == true:
		match action.ability_range[i]:
			1: # 敵単体
				target_list.append(enemy_deck[index])
			2: # 敵全体
				for mon in enemy_deck:
					target_list.append(mon)
			3: # 味方単体
				target_list.append(player_deck[index])
			4: # 味方全体
				for mon in player_deck:
					target_list.append(mon)
			5: # 自分
				target_list.append(monster)
	else:
		match action.ability_range[i]:
			1: # 敵単体
				target_list.append(player_deck[index])
			2: # 敵全体
				for mon in player_deck:
					target_list.append(mon)
			3: # 味方単体
				target_list.append(enemy_deck[index])
			4: # 味方全体
				for mon in enemy_deck:
					target_list.append(mon)
			5: # 自分
				target_list.append(monster)
	return target_list

## 属性倍率計算機(1属性)
func attribute(o: int,d: int):
	if ( # 0:無 1:火 2:水 3:雷 4:土 5:風 6:氷 7:光 8:闇
			(o == 2 and d == 1) or (o == 3 and d == 2) or (o == 4 and d == 3) or 
			(o == 5 and d == 4) or (o == 6 and d == 5) or (o == 1 and d == 6) or 
			(o == 7 and d == 8) or (o == 8 and d == 7)):
		return 2.0 # 弱点を突いたときダメージ2倍
	elif o == d and o != 0:
		return 0.5 # 同じ属性の技を受けた時ダメージ0.5倍
	elif o == 0 and d != 0:
		return 0.8 # 無属性でない敵に無属性の技で攻撃する際の軽減倍率0.8倍
	else:
		return 1.0 # その他等倍

## 属性倍率計算機(反復)
func attribute_setup(action: Action, monster: Monster) -> float:
	var magnification: float = 1.0 # 最終的な属性相性倍率
	for act_element: Element in action.element:
		for monster_element: Element in monster.element:
			magnification *= attribute(act_element.id, monster_element.id)
	return magnification

## ダメージ計算機[br]戻り値array[ダメージ(int), 属性相性テキスト(string)]
func damage_calc(action: Action, offense: BattleMonster, defense: BattleMonster)\
 -> Array:
	if action.power == 0: # powerが0なら不要なので中断
		return [0, ""]
	
	var status: Array[float] = [0, 0] # ステータス値
	var type: Array[int] = [0, 0] # 0:なし 1:ATK 2:DEF 3:MAG 4:RES
	match action.damage_type: # 必要なステータス参照
		0:
			pass
		1:
			status[0] = float(offense.monster.ATK)
			status[1] = float(defense.monster.DEF)
			type[0] = 1
			type[1] = 2
		2:
			status[0] = float(offense.monster.MAG)
			status[1] = float(defense.monster.RES)
			type[0] = 3
			type[1] = 4
		_:
			print("ERROR:damage_typeが検知できません")
	
	# エフェクトをステータスに対応させる処理
	var effects_list = [offense.effect_dict.keys(), defense.effect_dict.keys()]
	for i in range(2): # i=0:攻撃側ステータスについて i=1:守備側ステータスについて
		for effect: Effect in effects_list[i]:
			match effect.category:
				2: # バフ
					if effect.buff == type[i]:
						status[i] *= effect.power
				3: # デバフ
					if effect.buff == type[i]:
						status[i] /= effect.power
	
	var magnification: float = attribute_setup(action, defense.monster)
	var magnification_text: String = ""
	if magnification < 1.0:
		magnification_text = "[color=light_blue]耐性があるようだ...[/color]"
	elif magnification > 1.0:
		magnification_text = "[color=red]弱点をついた！[/color]"
	# power * ((攻撃側ステータス / 守備側ステータス) ** ステータス乖離ボーナス(1.2) * 属性相性
	var damage = action.power * ((status[0] / status[1]) ** 1.2) * magnification
	# モンスターと技の属性一致倍率を乗算
	var break_mode: bool = false # 2回目のbreak用
	for i: Element in action.element:
		for j: Element in offense.monster.element:
			if i == j:
				damage *= 1.5
				break_mode = true
				break
		if break_mode == true:
			break	
	return [int(damage), magnification_text]
