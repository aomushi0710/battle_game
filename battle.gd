extends Control

var player_deck: Deck = Global.deck1
var enemy_deck: Deck = Global.enemy_deck
enum{none, ATK, DEF, MAG, RES}

signal player_damage1
signal player_damage2
signal player_damage3
signal enemy_damage1
signal enemy_damage2
signal enemy_damage3
signal player_healing1
signal player_healing2
signal player_healing3
signal enemy_healing1
signal enemy_healing2
signal enemy_healing3
signal player_evolution1
signal player_evolution2
signal player_evolution3
signal enemy_evolution1
signal enemy_evolution2
signal enemy_evolution3
signal player_mp1
signal player_mp2
signal player_mp3
signal enemy_mp1
signal enemy_mp2
signal enemy_mp3

func _ready():
	$"../バトル終了".position = Vector2(0,0)
	$result_rect.z_index = 9
	$result_rect/win.z_index = 10
	$result_rect/lose.z_index = 10
	$"../バトル終了".z_index = 11

# 複数の属性を持つ場合にそれぞれに倍率計算を施す関数
func attribute_setup(action: Action, monster: Monster, aiteno: String) -> float:
	var magnification: float = 1.0 # 最終的な属性相性倍率
	for act_element: Element in action.element:
		for monster_element: Element in monster.element:
			magnification *= attribute(act_element.id, monster_element.id)
	
	if aiteno == "": # 反転
		aiteno = "相手の "
	else:
		aiteno = ""
	
	if magnification >= 2.0:
		$"../log_window/log".text += \
		"[color=red]%s%s の弱点をついた！[/color]\n" % [aiteno, monster.name]
	elif magnification < 1.0:
		$"../log_window/log".text += \
		"[color=light_blue]%s%s は耐性があるようだ...[/color]\n" % [aiteno, monster.name]
	
	return magnification

# 属性IDを基に倍率を計算する関数
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

# ダメージ計算機 攻撃する技、攻撃側及び守備側のモンスターとエフェクトを引数に、ダメージを返す
func damage_calc(action: Action, offense_monster: Monster, defense_monster: Monster, 
offense_effect: Array, defense_effect: Array, aiteno: String) -> int:
	if action.power == 0: # powerが0なら不要なので中断
		return 0
	
	# セットアップ
	var effects: Array[Array] = [offense_effect, defense_effect]
	var status: Array[float] = [0, 0] # ステータス値
	var type: Array[int] = [0, 0] # 0:なし 1:ATK 2:DEF 3:MAG 4:RES
	match action.damage_type: # 必要なステータス参照
		0:
			pass
		1:
			status[0] = float(offense_monster.ATK)
			status[1] = float(defense_monster.DEF)
			type[0] = ATK
			type[1] = DEF
		2:
			status[0] = float(offense_monster.MAG)
			status[1] = float(defense_monster.RES)
			type[0] = MAG
			type[1] = RES
		_:
			print("ERROR:damage_typeが検知できません")
	
	# エフェクトをステータスに対応させる処理
	for i in range(2): # i=0:攻撃側ステータスについて i=1:守備側ステータスについて
		for effect: Effect in effects[i]:
			match effect.category:
				2: # バフ
					if effect.buff == type[i]:
						status[i] *= effect.power
				3: # デバフ
					if effect.buff == type[i]:
						status[i] /= effect.power
	# 属性相性倍率計算
	var magnification = attribute_setup(action, defense_monster, aiteno)
	# power * ((攻撃側ステータス / 守備側ステータス) ** ステータス乖離ボーナス(1.2) * 属性相性
	var damage = action.power * ((status[0] / status[1]) ** 1.2) * magnification
	
	var break_flag: bool = false
	for element_a in action.element: # 技の属性
		for element_m in offense_monster.element: # モンスターの属性
			if element_a.id == element_m.id: # これらのうちいずれかが一致するとき
				damage *= 1.5 # ダメージ補正1.5倍
				break_flag = true # 次のループもbreakする用のフラグ
				break
		if break_flag == true:
			break
	
	return int(damage)

# 技の発動処理関数 action:選ばれた技 monster:攻撃モンスター 
# boolian true:playerが攻撃 false:enemyが攻撃 index:攻撃モンスターの位置
func _on_buttle_command(action: Action, monster: Monster, boolian: bool, index: int):
	 # 死亡フラグ管理リスト(target_set関数の引数用)
	var death_lists: Array[Array] = [[Global.p1_death, Global.p2_death, Global.p3_death], \
	[Global.e1_death, Global.e2_death, Global.e3_death]]
	var death_list1: Array
	var death_list2: Array
	var target: int
	var support_target: int
	var offense_deck: Deck
	var defense_deck: Deck
	var offense_effect: Array # 攻撃側エフェクト
	var defense_effect: Array # 守備側エフェクト
	var enemy: Monster # 守備側モンスター
	var aiteno: String = "" # 敵の行動時には「相手の」をログに追加で表示させる
	
	if boolian == true:
		death_list1 = death_lists[1]
		death_list2 = death_lists[0]
		offense_deck = player_deck
		defense_deck = enemy_deck
	else:
		death_list1 = death_lists[0]
		death_list2 = death_lists[1]
		offense_deck = enemy_deck
		defense_deck = player_deck
		aiteno = "相手の "
	
	# 対象となる敵または味方を取得
	if boolian == true:
		target = target_set(Global.target, death_list1)
		support_target = target_set(Global.support_target, death_list2)
	else:
		target = target_set(randi() % 3, death_list1)
		support_target = target_set(randi() % 3, death_list2)
	
	offense_effect = offense_deck.effect[index].keys()
	defense_effect = defense_deck.effect[target].keys()
	enemy = defense_deck.monster[target]
	# 第1形態から最終形態にスキップしないように
	if len(offense_deck.evolution_forms[index]) == 3 \
	and monster.form == 0 and action.id == 10002:
		$"../log_window/log".text += "[color=yellow]%s" % aiteno + \
		"%s はまだ最終形態には進化できない！[/color]\n" % monster.name
		return
	
	if monster.MP < action.mp:
		$"../log_window/log".text += "[color=yellow]%s" % aiteno + \
		"%s はMPが足りない！[/color]\n" % monster.name
		return
	if action.mp != 0: # mpを消費した時の挙動
		if boolian == true:
			match index:
				0: # mpを減らす
					player_mp1.emit(action.mp)
				1:
					player_mp2.emit(action.mp)
				2:
					player_mp3.emit(action.mp)
				_:
					print("ERROR:攻撃側モンスターの位置indexが不明です")
		else:
			match index:
				0: # mpを減らす
					enemy_mp1.emit(action.mp)
				1:
					enemy_mp2.emit(action.mp)
				2:
					enemy_mp3.emit(action.mp)
				_:
					print("ERROR:攻撃側モンスターの位置indexが不明です")
		$"../log_window/log".text += aiteno + monster.name + \
		" は[color=aqua]%dMP[/color]を消費した...\n" % action.mp
	$"../log_window/log".text += aiteno + monster.name + " の " + action.name + "!\n"
	
	if action.id == 10001 or action.id == 10002: # 進化技
		if boolian == true:
			match index:
				0:
					player_evolution1.emit()
				1:
					player_evolution2.emit()
				2:
					player_evolution3.emit()
				_:
					print("ERROR:攻撃側モンスターの位置indexが不明です")
		else:
			match index:
				0:
					enemy_evolution1.emit()
				1:
					enemy_evolution2.emit()
				2:
					enemy_evolution3.emit()
				_:
					print("ERROR:攻撃側モンスターの位置indexが不明です")
		$"../SoundEffects/evolution".play()
		return
	
	for i in len(action.ability): # 全ての特殊能力について順番に処理
		var ability = action.ability[i]
		var deck: Deck # 対象となるデッキ
		var flag: bool # player:true enemy:false を返す
		var range: Array[int] # 対象となるモンスターの位置index
		var ability_range: int # 連動範囲の指定用
		
		if action.ability_range[i] == 0: # 連動 のとき
			ability_range = action.range # actionの対象と同じにする
		else:
			ability_range = action.ability_range[i]
		match ability_range:
			1: # 敵単体
				deck = defense_deck
				flag = !boolian
				range.append(target)
			2: # 敵全体
				deck = defense_deck
				flag = !boolian
				range = [0,1,2]
			3: # 味方単体
				deck = offense_deck
				flag = boolian
				range.append(support_target)
			4: # 味方全体
				deck = offense_deck
				flag = boolian
				range = [0,1,2]
			5: # 自分
				deck = offense_deck
				flag = boolian
				range.append(index)
		
		if flag == true: # 敵か味方か判定
			aiteno = ""
		else:
			aiteno = "相手の "
		
		match ability.category:
			1: # 状態異常　未実装
				pass
			2, 3: # バフデバフ エフェクトをkey、ターン数をvalueとして登録
				for i_range: int in range:
					if ability.effect in deck.effect[i_range]: # 既に発動中ならターン延長
						deck.effect[i_range][ability.effect] += action.ability_power[i]
					else:
						deck.effect[i_range][ability.effect] = action.ability_power[i]
					# もし自分に与えるエフェクトだった場合、発動時にも1ターン減るので付け足す
					if deck == offense_deck and i_range == index:
						deck.effect[i_range][ability.effect] += 1
					# バフデバフアイコン表示
					buff_icon(flag, i_range)
					# ログ表示
					$"../log_window/log".text += "[color=red]%s" % aiteno + \
					deck.monster[i_range].name + " %s[/color]\n" % ability.effect.log
					
					match ability.category:
						2: # バフ SE再生
							$"../SoundEffects/buff".play()
						3: # デバフ SE再生
							$"../SoundEffects/debuff".play()
			4: # 回復
				var heal: int # 回復量
				match ability.healing:
					1: # ステータス参照HP回復
						match action.damage_type:
							2: # 魔法 
								heal = monster.MAG * \
								(float(action.ability_power[i]) / 100)
					2: # 定数HP回復
						heal = action.ability_power[i]
						
				for i_range: int in range:
					if flag == true:
						match i_range:
							0:
								player_healing1.emit(heal)
							1:
								player_healing2.emit(heal)
							2:
								player_healing3.emit(heal)
					else:
						match i_range:
							0:
								enemy_healing1.emit(heal)
							1:
								enemy_healing2.emit(heal)
							2:
								enemy_healing3.emit(heal)
				$"../SoundEffects/heal".play()
	
	match action.range:
		1: # 敵単体
			var damage = damage_calc(action, monster, enemy, \
			offense_effect, defense_effect, aiteno)
			if boolian == true:
				match target:
					0:
						enemy_damage1.emit(damage)
					1:
						enemy_damage2.emit(damage)
					2:
						enemy_damage3.emit(damage)
			else:
				match target:
					0:
						player_damage1.emit(damage)
					1:
						player_damage2.emit(damage)
					2:
						player_damage3.emit(damage)
		2: # 敵全体
			pass
		3: # 味方単体
			pass
		4: # 味方全体
			pass
		5: # 自分
			pass
		6: # 敵散開
			var damage = damage_calc(action, monster, enemy, \
			offense_effect, defense_effect, aiteno)
			if boolian == true:
				match target:
					0:
						enemy_damage1.emit(damage)
						if death_list1[1] == false: # 生きていたら
							damage = damage_calc(action, monster, defense_deck.monster[1], \
							offense_effect, defense_deck.effect[1].keys(), aiteno) / 2
							enemy_damage2.emit(damage) # 半分のダメージを与える
					1:
						enemy_damage2.emit(damage)
						for i in [0, 2]:
							if death_list1[i] == false: # 生きていたら
								damage = damage_calc(action, monster, defense_deck.monster[i], \
								offense_effect, defense_deck.effect[i].keys(), aiteno) / 2
								
								match i:
									0:
										enemy_damage1.emit(damage) # 半分のダメージを与える
									2:
										enemy_damage3.emit(damage)
					2:
						enemy_damage3.emit(damage)
						if death_list1[1] == false: # 生きていたら
							damage = damage_calc(action, monster, defense_deck.monster[1], \
							offense_effect, defense_deck.effect[1].keys(), aiteno) / 2
							enemy_damage2.emit(damage) # 半分のダメージを与える
			else:
				match target:
					0:
						player_damage1.emit(damage)
						if death_list1[1] == false: # 生きていたら
							damage = damage_calc(action, monster, defense_deck.monster[1], \
							offense_effect, defense_deck.effect[1].keys(), aiteno) / 2
							player_damage2.emit(damage) # 半分のダメージを与える
					1:
						player_damage2.emit(damage)
						for i in [0, 2]:
							if death_list1[i] == false: # 生きていたら
								damage = damage_calc(action, monster, defense_deck.monster[i], \
								offense_effect, defense_deck.effect[i].keys(), aiteno) / 2
								
								match i:
									0:
										player_damage1.emit(damage) # 半分のダメージを与える
									2:
										player_damage3.emit(damage)
					2:
						player_damage3.emit(damage)
						if death_list1[1] == false: # 生きていたら
							damage = damage_calc(action, monster, defense_deck.monster[1], \
							offense_effect, defense_deck.effect[1].keys(), aiteno) / 2
							player_damage2.emit(damage) # 半分のダメージを与える
	
	if action.power != 0:
		$"../SoundEffects/damage".play()

# target_input:現在選択中のtargetを入力 death:モンスターの生存状態を確認するboolのarray
func target_set(target_input: int, death: Array) -> int:
	var target_output :int
	if (target_input == 0 or target_input > 2) and death[0] == true: #死んでいる0がtargetの時
		if death[1] == true:
			target_output = 2
		elif death[2] == true:
			target_output = 1
		else:
			target_output = randi() % 2 + 1 # 1 or 2
	elif (target_input == 1 or target_input > 2) and death[1] == true:
		if death[2] == true:
			target_output = 0
		else:
			if randi() % 2 == 0:
				target_output = 0
			else:
				target_output = 2
	elif (target_input == 2 or target_input > 2) and death[2] == true:
		target_output = randi() % 2
	elif target_input > 2: # ターゲット指定なしならランダムに指定する
		target_output = randi() % 3
	else:
		target_output = target_input
	
	return target_output

func _on_enemy_1_button_up():
	Global.target = 0
	call("target_text_log",Global.target)

func _on_enemy_2_button_up():
	Global.target = 1
	call("target_text_log",Global.target)

func _on_enemy_3_button_up():
	Global.target = 2
	call("target_text_log",Global.target)

func target_text_log(x):
	$"../log_window/log".text += \
	"相手の " + enemy_deck.monster[x].name + " に攻撃の狙いを定めた！\n"


func death_check():
	if Global.e1_death == true and Global.e2_death == true and Global.e3_death == true:
		$result_rect.show()
		$result_rect/win.show()
		$"../バトル終了".position = Vector2(450,400)
		get_tree().paused = true
	elif Global.p1_death == true and Global.p2_death == true and Global.p3_death == true:
		$result_rect.show()
		$result_rect/lose.show()
		$"../バトル終了".position = Vector2(450,400)
		get_tree().paused = true

func _on_p_1_hp_death():
	Global.p1_death = true
	death_check()


func _on_p_2_hp_death():
	Global.p2_death = true
	death_check()


func _on_p_3_hp_death():
	Global.p3_death = true
	death_check()


func _on_player_1_button_up():
	Global.support_target = 0
	support_target_text_log(Global.support_target)

func _on_player_2_button_up():
	Global.support_target = 1
	support_target_text_log(Global.support_target)

func _on_player_3_button_up():
	Global.support_target = 2
	support_target_text_log(Global.support_target)

func support_target_text_log(x):
	$"../log_window/log".text += \
	player_deck.monster[x].name + " にサポートの狙いを定めた！\n"


func buff_icon(b: bool, i: int) -> void:# バフアイコン表示更新処理 true:プレイヤー false:敵
	var effects: Dictionary
	var buff_icon: TextureButton
	var buff_turn: RichTextLabel
	var debuff_icon: TextureButton
	var debuff_turn: RichTextLabel
	
	if b == true:
		effects = Global.deck1.effect[i]
		if i == 0:
			buff_icon = $player1/p1_icon/バフアイコン
			buff_turn = $player1/p1_icon/buff_turn
			debuff_icon = $player1/p1_icon/デバフアイコン
			debuff_turn = $player1/p1_icon/debuff_turn
		elif i == 1:
			buff_icon = $player2/p2_icon/バフアイコン
			buff_turn = $player2/p2_icon/buff_turn
			debuff_icon = $player2/p2_icon/デバフアイコン
			debuff_turn = $player2/p2_icon/debuff_turn
		elif i == 2:
			buff_icon = $player3/p3_icon/バフアイコン
			buff_turn = $player3/p3_icon/buff_turn
			debuff_icon = $player3/p3_icon/デバフアイコン
			debuff_turn = $player3/p3_icon/debuff_turn
		else:
			print("関数buff_iconエラー 不正な引数i 範囲は0~2です")
	else:
		effects = Global.enemy_deck.effect[i]
		if i == 0:
			buff_icon = $"../enemies/enemy1/e1_icon/バフアイコン"
			buff_turn = $"../enemies/enemy1/e1_icon/buff_turn"
			debuff_icon = $"../enemies/enemy1/e1_icon/デバフアイコン"
			debuff_turn = $"../enemies/enemy1/e1_icon/debuff_turn"
		elif i == 1:
			buff_icon = $"../enemies/enemy2/e2_icon/バフアイコン"
			buff_turn = $"../enemies/enemy2/e2_icon/buff_turn"
			debuff_icon = $"../enemies/enemy2/e2_icon/デバフアイコン"
			debuff_turn = $"../enemies/enemy2/e2_icon/debuff_turn"
		elif i == 2:
			buff_icon = $"../enemies/enemy3/e3_icon/バフアイコン"
			buff_turn = $"../enemies/enemy3/e3_icon/buff_turn"
			debuff_icon = $"../enemies/enemy3/e3_icon/デバフアイコン"
			debuff_turn = $"../enemies/enemy3/e3_icon/debuff_turn"
		else:
			print("関数buff_iconエラー 不正な引数i 範囲は0~2です")
	
	var buff_longest_turn: int = 0
	var debuff_longest_turn: int = 0
	for effect: Effect in effects.keys():
		match effect.category:
			# TODO 状態異常にも同様の処理を作る
			2: # バフ最長ターン数計測
				if buff_longest_turn < effects[effect]:
					buff_longest_turn = effects[effect]
			3: # デバフ
				if debuff_longest_turn < effects[effect]:
					debuff_longest_turn = effects[effect]
	
	if buff_longest_turn != 0: # バフがある時
		buff_turn.text = "[right][color=yellow][i][b]%d[/b][/i][/color][/right]" % \
		buff_longest_turn
		if buff_turn.visible == false: # アイコンがオフの時
			buff_icon.self_modulate = Color(1, 1, 1, 1) # アイコンをオンにする
			buff_icon.set_process(true)
			buff_turn.show()
	elif buff_turn.visible == true: # バフはないがアイコンがオンの時
		buff_icon.self_modulate = Color(0.2353, 0.2353, 0.2353, 1) # アイコンをオフにする
		buff_icon.set_process(false)
		buff_turn.hide()
	
	if debuff_longest_turn != 0: # デバフがある時
		debuff_turn.text = "[right][color=yellow][i][b]%d[/b][/i][/color][/right]" % \
		debuff_longest_turn
		if debuff_turn.visible == false: # アイコンがオフの時
			debuff_icon.self_modulate = Color(1, 1, 1, 1) # アイコンをオンにする
			debuff_icon.set_process(true)
			debuff_turn.show()
	elif debuff_turn.visible == true: # デバフはないがアイコンがオンの時
		debuff_icon.self_modulate = Color(0.2353, 0.2353, 0.2353, 1) # アイコンをオフにする
		debuff_icon.set_process(false)
		debuff_turn.hide()



func _on_e_1_hp_death() -> void:
	Global.e1_death = true
	death_check()


func _on_e_2_hp_death() -> void:
	Global.e2_death = true
	death_check()


func _on_e_3_hp_death() -> void:
	Global.e3_death = true
	death_check()
