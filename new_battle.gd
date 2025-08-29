extends Control

const monster_scene = preload("res://battle_monster.tscn")
@onready var sound_effect := $"../SoundEffects"
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
	tween = get_tree().create_tween().bind_node(self) # monster出現アニメーション
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
	
	tween = get_tree().create_tween().bind_node(self)
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
			var instance = Global.action_button.instantiate()
			instance.action = player_monster.picked_action[i]
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
		match action.target:
			Global.Target.近接:
				action_index = player_monster.index
			
			Global.Target.遠隔:
				action_index = random_index(true)
			
			Global.Target.自分:
				action_index = enemy_monster.index
			
			Global.Target.味方単体:
				action_index = random_index(false)
			
			Global.Target.敵全体, Global.Target.味方全体, Global.Target.敵味方全体:
				action_index = -1
		
		command_selected(enemy_monster, action, action_index)
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

## [param monster]が[param action]を発動する関数[br]
## 発動対象は[param monster]が味方か敵かどうかと[param index]によって、
## [code]target_setting[/code]関数を用いて決定される。[br][br]
## この関数が特殊効果[code]AbilityExtra[/code]によって呼ばれる場合、
## [param extra]は[code]true[/code]で呼ぶ。(デフォルトは[code]false[/code])
func command_selected(monster: BattleMonster, action: Action, index: int, 
extra: AbilityExtra = null) -> void:
	dialog.set_tab_disabled(1, true)
	dialog.set_tab_disabled(2, true)
	# 発動可能な技かどうかチェック
	if await action_checker(monster, action) == false:
		turn_end(monster)
		return
	
	var dialog_text: Array[String] ## ダイアログに表示するテキストを収納する
	
	 # mp消費処理
	if action.mp != 0:
		dialog_text = monster.mp_setter(-action.mp, true)
	# AbilityExtraによって発動した技かどうかで表示メッセージを変える
	if extra == null:
		dialog_text.append("%s の %s！" % [monster.monster.name, action.name])
	else:
		dialog_text.append(extra.battle_log_message)
	
	await dialog.text_setter(0, true, dialog_text)
	
	# 進化技の時
	if action.id == 10001 or action.id == 10002:
		dialog_text = monster.evolution(action.id)
		await dialog.text_setter(0, true, dialog_text)
	
	# 全ての特殊能力について順番に処理
	for i in len(action.ability):
		if action.ability[i].timing == Ability.Timing.前:
			await execute_ability(monster, action.ability[i], index)
	
	# 攻撃をする技なら
	if action.power != 0:
		var target_list: Array[BattleMonster] = target_setting(
			monster.player, action, index)
		
		for target: BattleMonster in target_list: # 対象にダメージをあたえる
			var damage_array = damage_calc(action, monster, target)
			dialog_text = [] # 初期化
			var text: Array[String] = target.hp_setter(-damage_array[0], true)
			for t: String in text: # Array[String]から要素を抜き出す
				t += "\n%s" % damage_array[1] # ダメージ相性のテキストを追加
				dialog_text.append(t)
			await dialog.text_setter(0, true, dialog_text)
	
			if target.monster.HP <= 0: # 死亡時処理
				await target.dead(player_monster, enemy_monster)
	
	# 全ての特殊能力について順番に処理
	for i in len(action.ability):
		if action.ability[i].timing == Ability.Timing.後:
			await execute_ability(monster, action.ability[i], index)
	
	# AbilityExtraによって発動した技ならばそのまま元の処理に戻り、そうでないならターン終了
	if extra == null:
		turn_end(monster)

## [param monster]と[param action]を基に何らかの理由で発動できない技の場合に中断する関数。[br]
## 発動可能な技の場合[code]true[/code]を返し、発動不可な技の場合[code]false[/code]を返す。
func action_checker(monster: BattleMonster, action: Action) -> bool:
	# 第1形態から最終形態にスキップするのを防止
	if len(monster.monster_dict) == 3 \
	and monster.monster.form == 0 and action.id == 10002:
		await dialog.text_setter(0, true, [
		"[color=yellow]%s はまだ最終形態には進化できない！[/color]\n先に第2形態に進化してください！" % 
		monster.monster.name])
		return false
	# mpが足りない場合
	if monster.monster.MP < action.mp:
		await dialog.text_setter(0, true, [
		"%s の %s！\n[color=yellow]しかし、[color=aqua]MP[/color]が足りない！[/color]" % 
		[monster.monster.name, action.name]])
		return false
	
	return true

## 特殊効果[param ability]を発動する関数[br]
## [param monster]はその技を発動したモンスター[br]
## [param index]でどの敵が対象かを割り出す[code]target_setting[/code]関数を呼び出す
func execute_ability(monster: BattleMonster, ability: Ability, index: int) -> void:
	if randi() % 100 + 1 > ability.chance: # 確率範囲外ならその効果の処理スキップ
		return
	
	var target_list := target_setting(monster.player, ability, index)
	
	for target: BattleMonster in target_list: # 全ての対象について順番に処理
		if ability is AbilityEffect: # 状態異常 TODO 未実装
			pass
		
		elif ability is AbilityBuff or ability is AbilityDebuff: # バフ or デバフ
			## abilityを基に作られた、モンスターに付与されるエフェクト
			var monster_effect = MonsterEffect.new(ability)
			var found_effect: bool = false ## 同じエフェクトが見つかったかどうかを確認する
			
			if monster == target: # 自分で自分にエフェクトを付けたそのターン数を減らさないために
				monster_effect.turn += 1
			
			for me: MonsterEffect in target.effect_list: # 既に対象が持つエフェクトに対して
				if monster_effect.effect == me.effect: # 同じものが見つかれば
					me.turn += monster_effect.turn # ターン数を延長する
					found_effect = true
					break
			if found_effect == false: # 同じエフェクトが見つからなかった時、新たに追加
				target.add_effect(monster_effect)
			
			var damage_text = Global.damage_text.instantiate()
			damage_text.text = "[font_size=50][b][i]%s[/i][/b][/font_size]" % \
			ability.bbcode_name.replace(" ", "\n")
			target.add_child(damage_text)
			
			if ability is AbilityBuff: # バフ効果音
				sound_effect.buff.play()
			elif ability is AbilityDebuff: # デバフ効果音
				sound_effect.debuff.play()
			
			var text: String
			if ability.battle_log_message == "":
				text = "これは...どうやら開発者がメッセージを\n入れ忘れているらしい。" + \
				"\nそれでも特殊効果は発動した！"
			else:
				text = ability.battle_log_message % target.monster.name
			await dialog.text_setter(0, true, [text])
		
		elif ability is AbilityHealing: # 回復
			var heal: int ## 回復量
			match ability.amount_type:
				AbilityHealing.AmountType.定数:
					heal = ability.amount
				
				AbilityHealing.AmountType.MAG:
					heal = monster.monster.MAG * ability.amount
				
				_:
					print("不明な列挙型AbilityHealing -> AmountType。0を返します。")
					heal = 0
			
			var dialog_text: Array[String] ## hp, mp, spdのsetter関数の返り値
			match ability.status:
				AbilityHealing.Status.HP:
					dialog_text = target.hp_setter(heal, true)
				
				AbilityHealing.Status.MP:
					dialog_text = target.mp_setter(heal, true)
				
				AbilityHealing.Status.SPD:
					pass # TODO 未実装
			
			await dialog.text_setter(0, true, dialog_text)
		
		elif ability is AbilityExtra: # 連続攻撃
			await command_selected(monster, ability.action, index, ability)


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
	
	turn_end(monster)

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
			var item_tween: Tween = item_node.create_tween().bind_node(item_node)
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
func turn_end(monster: BattleMonster) -> void:
	# 相手全滅
	if Global.e1_death == true and Global.e2_death == true and Global.e3_death == true:
		return
	# 味方全滅
	elif Global.p1_death == true and Global.p2_death == true and Global.p3_death == true:
		return
	
	monster.get_node("SPD").value = 0
	for effect: MonsterEffect in monster.effect_list: # エフェクト効果を引き起こす
		effect.turn_finished()
	
	# モンスター交代
	if monster.player == true and player_monster != player_deck[player_next_index]:
		player_monster.bench_set() # フィールドのモンスターをベンチに
		player_monster = player_deck[player_next_index]
		player_monster.field_set() # 次に指定されたモンスターをフィールドに
	elif monster.player == false and enemy_monster != enemy_deck[enemy_next_index]:
		enemy_monster.bench_set()
		enemy_monster = enemy_deck[enemy_next_index]
		enemy_monster.field_set()
	
	# 死んでなきゃSPDゲージ再開
	if player_monster.death == false:
		player_monster.get_node("SPD").set_process(true)
	if tutorial_mode == false:
		if enemy_monster.death == false:
			enemy_monster.get_node("SPD").set_process(true)
	
	if monster.player == true: # 味方モンスターが動いた後にフレーバーテキスト更新
		
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

## 選ばれた敵または味方の[param index]を基にして技・特殊効果・アイテム[param resource]
## の発動先をリストにして返す関数[br]
## [param player]発動者がプレイヤーなら[code]true[/code]、敵なら[code]false[/code]。
func target_setting(player: bool, resource: Resource, index: int)\
 -> Array[BattleMonster]:
	var target_list: Array[BattleMonster] = [] # 特殊効果の発動対象
	
	# 技でも特殊効果でもアイテムでもなければ中断
	if resource is not Action and resource is not Ability and resource is not Item:
		print("不明な型です")
		return []
	
	if player == true:
		match resource.target:
			Global.Target.近接:
				for mon: BattleMonster in enemy_deck:
					if mon.field == true:
						target_list.append(mon)
						break
			
			Global.Target.遠隔:
				target_list.append(enemy_deck[index])
			
			Global.Target.敵全体:
				for mon: BattleMonster in enemy_deck:
					if mon.death == false:
						target_list.append(mon)
			
			Global.Target.自分:
				for mon: BattleMonster in player_deck:
					if mon.field == true:
						target_list.append(mon)
						break
			
			Global.Target.味方単体:
				target_list.append(player_deck[index])
			
			Global.Target.味方全体:
				for mon: BattleMonster in player_deck:
					if mon.death == false:
						target_list.append(mon)
			
			Global.Target.敵味方全体:
				for deck: Array[BattleMonster] in [enemy_deck, player_deck]:
					for mon: BattleMonster in deck:
						if mon.death == false:
							target_list.append(mon)
	else:
		match resource.target:
			Global.Target.近接:
				for mon: BattleMonster in player_deck:
					if mon.field == true:
						target_list.append(mon)
						break
			
			Global.Target.遠隔:
				target_list.append(player_deck[index])
			
			Global.Target.敵全体:
				for mon: BattleMonster in player_deck:
					if mon.death == false:
						target_list.append(mon)
			
			Global.Target.自分:
				for mon: BattleMonster in enemy_deck:
					if mon.field == true:
						target_list.append(mon)
						break
			
			Global.Target.味方単体:
				target_list.append(enemy_deck[index])
			
			Global.Target.味方全体:
				for mon: BattleMonster in enemy_deck:
					if mon.death == false:
						target_list.append(mon)
			
			Global.Target.敵味方全体:
				for deck: Array[BattleMonster] in [player_deck, enemy_deck]:
					for mon: BattleMonster in deck:
						if mon.death == false:
							target_list.append(mon)
	
	return target_list

## 属性倍率計算機(1属性)
func attribute(o: int,d: int):
	if ( # 0:無 1:火 2:水 3:雷 4:土 5:風 6:氷 7:光 8:闇
		(o == 2 and d == 1) or (o == 3 and d == 2) or (o == 4 and d == 3) or 
		(o == 5 and d == 4) or (o == 6 and d == 5) or (o == 1 and d == 6) or 
		(o == 7 and d == 8) or (o == 8 and d == 7)):
		return 2.0 # 弱点を突いたときダメージ2倍
	elif (
		(o == 1 and d == 2) or (o == 2 and d == 3) or (o == 3 and d == 4) or 
		(o == 4 and d == 5) or (o == 5 and d == 6) or (o == 6 and d == 1) or 
		(o == d and o != 0)):
		return 0.5 # 得意属性もしくは同じ属性の技を受けた時ダメージ0.5倍
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
	var type: Array[Global.Status] = []
	type.resize(2)
	match action.damage_type: # 必要なステータス参照
		Action.DamageType.なし:
			pass
		
		Action.DamageType.物理:
			status[0] = offense.monster.ATK
			status[1] = defense.monster.DEF
			type[0] = Global.Status.ATK
			type[1] = Global.Status.DEF
		
		Action.DamageType.魔法:
			status[0] = offense.monster.MAG
			status[1] = defense.monster.RES
			type[0] = Global.Status.MAG
			type[1] = Global.Status.RES
		
		_:
			print("ERROR:damage_typeが検知できません")
	
	# エフェクトをステータスに対応させる処理
	var effects_list = [offense.effect_list, defense.effect_list]
	for i in range(2): # i=0:攻撃側ステータスについて i=1:守備側ステータスについて
		for effect: MonsterEffect in effects_list[i]:
			var ability = effect.effect
			if ability is AbilityBuff: # バフ
				if type[i] == ability.status: # 計算に用いるステータスと一致している時
					status[i] *= ability.amount
			
			elif ability is AbilityDebuff: # デバフ
				if type[i] == ability.status: # 計算に用いるステータスと一致している時
					status[i] /= ability.amount
	
	var magnification: float = attribute_setup(action, defense.monster)
	var magnification_text: String = ""
	if magnification < 1.0:
		magnification_text = "[color=light_blue]耐性があるようだ...[/color]\n"
	elif magnification > 1.0:
		magnification_text = "[color=red]弱点をついた！[/color]\n"
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
	
	for ability: Ability in action.ability:
		if randi() % 100 + 1 > ability.chance: # 確率範囲外ならその効果の処理スキップ
			continue
		if ability is AbilityCritical:
			match ability.amount_type:
				AbilityCritical.AmountType.加算:
					damage += ability.amount
				
				AbilityCritical.AmountType.乗算:
					damage *= ability.amount
			
			magnification_text += ability.battle_log_message
		
		elif ability is AbilityFumble:
			match ability.amount_type:
				AbilityFumble.AmountType.減算:
					damage -= ability.amount
				
				AbilityFumble.AmountType.除算:
					damage /= ability.amount
		
			magnification_text += ability.battle_log_message
	
	return [int(damage), magnification_text]
