extends Control

var selected_skill = 0 # 選ばれたスキルパターン
var now_select_action = 0 # 現在指定されている技
var sum_chance = 0 # 出現率の合計
var monster_data = Global.monster_data # モンスターの各種データ取得
var action_data = Global.action_data # 技の各種データ取得
var monster_id = Global.selected_monster
var selected_action = {} # key:選ばれた技(Action) value:出現率(int)
var check_provability = [] # 出現率0%弾き出し用

func _on_node_2d_tree_entered():
	_on_技_draw()
	selected_action.clear() # 以下2行、初期化処理
	sum_chance = 0
	
	# すでに登録されているものと同じモンスターを選んだ場合、その技をロード
	if Global.deck1.monster[Global.now_picking] != null:
		if Global.deck1.monster[Global.now_picking].id == monster_id:
			for i in len(Global.deck1.action[Global.now_picking]):
				selected_action[Global.deck1.action[Global.now_picking][i]] = \
				Global.deck1.chance[Global.now_picking][i] # selected_action生成
	ui_update()


func _on_戻る_button_up():
	call("reset")
	get_tree().change_scene_to_packed(Global.chara_scene)

func _on_決定_button_up():
	var monster_dict = monster_data[monster_id].duplicate() # Dictionary{Monster...}
	
	if sum_chance != 100:
		$エラーメッセージ.dialog_text = "出現率の合計が100%ではありません！"
		$エラーメッセージ.popup_centered()
		return
	
	elif float(0) in selected_action.values():
		$エラーメッセージ.dialog_text = "出現率が0%の技は選択を解除してください！"
		$エラーメッセージ.popup_centered()
		return
	
	elif len(monster_dict) == 3: # 2回進化モンスター
		for evol_action in monster_dict[2].actions: # 全ての進化技をループ
			for middle_evol_action in monster_dict[1].actions: # 全ての中間進化技をループ
				# 進化技は選択されているが、中間進化技が選択されていない場合に警告メッセージ
				if evol_action in selected_action.keys() and \
				middle_evol_action not in selected_action.keys():
					$エラーメッセージ.dialog_text = "中間進化技が選択されていません！\nこのモンスターは進化が2回必要です"
					$エラーメッセージ.popup_centered()
					return
	#elif selected_skill == 0: #スキル実装後に実装
		#$エラーメッセージ.dialog_text = "スキルが選択されていません！"
		#$エラーメッセージ.popup_centered()
		#return
	
	var action_list = selected_action.duplicate(true)
	Global.deck1.monster_dict[Global.now_picking] = monster_data[monster_id]
	Global.deck1.monster[Global.now_picking] = \
	Global.deck1.monster_dict[Global.now_picking][0].duplicate()
	Global.deck1.action[Global.now_picking] = action_list.keys()
	Global.deck1.chance[Global.now_picking] = action_list.values()
	#Global.deck1.skill[Global.now_picking] = selected_skill
	reset()
	get_tree().change_scene_to_packed(Global.deck_scene)


func _on_スキルボタン_item_selected(index: int): # オプションボタンで選んだパターンを登録
	selected_skill = index + 1

func _on_技_select(act: Action):
	$description_ui/description.position.y = 250 # 説明文の位置初期化
	$description_ui/description.size.y = 365
	if $description_ui/ability:
		$description_ui/ability.queue_free() # 初回のみ表示され、以降表示しない
	
	# ability数をget_children()でカウントしてその数だけabilityを消す。
	# index-1指定のループは予期しない動作をするため
	for i in range($description_ui.get_children().size() - 1, 7, -1):
		$description_ui.get_child(i).queue_free()
	
	if act in selected_action: # すでに登録されている技をもう一度選択して解除
		selected_action.erase(act)
		ui_update()
		now_select_action = 0
	elif len(selected_action) >= 4:
		$エラーメッセージ.dialog_text = "技は4個までしか登録できません！"
		$エラーメッセージ.popup_centered()
	elif sum_chance >= 100:
		$エラーメッセージ.dialog_text = "出現率の合計が100%を越えています！"
		$エラーメッセージ.popup_centered()
	else:
		selected_action[act] = 1 # 出現率1%で仮登録、スライダーで確率は調整できる
		ui_update()
	
	# 以下、技説明表示
	var aka = act.name
	if act.aka != "": # 略称が存在する場合、略称をtooltipに登録
		aka = "[hint=バトル中は " + act.aka + " と表示されます]" + \
		act.name + "[/hint]"
	
	var range_text = "" # 技の対象についての記述変形
	var range_tip = ""
	match act.range:
		0:
			range_text = "なし"
			range_tip = "発動対象が存在しません"
		1:
			range_text = "敵単体"
			range_tip = "敵単体に技を発動します"
		2:
			range_text = "敵全体"
			range_tip = "敵全体に技を発動します。"
		3:
			range_text = "味方単体"
			range_tip = "味方単体に技を発動します。"
		4:
			range_text = "味方全体"
			range_tip = "味方全体に技を発動します。"
		5:
			range_text = "自分"
			range_tip = "自分に技を発動します。"
		6:
			range_text = "敵散開"
			range_tip = "敵単体に加え、さらに隣の敵にも\n追加で半分のダメージを与えます"
		_:
			range_text = "[color=red][b]ERROR[/b][/color]"
			range_tip = "虚空に向かって技を放つのか？"
	
	var dmg_type_text = "" # 技のステータス参照先についての記述変形
	var dmg_type_tip = ""
	match act.damage_type:
		0:
			dmg_type_text = "なし"
			dmg_type_tip = "いずれのステータスも参照されません"
		1:
			dmg_type_text = "[color=red]物理[/color]"
			dmg_type_tip = "自身のATKと相手のDEFを参照します"
		2:
			dmg_type_text = "[color=dodger_blue]魔法[/color]"
			dmg_type_tip = "自身のMAGと相手のRESを参照します"
		_:
			dmg_type_text = "[color=red][b]ERROR[/b][/color]"
			dmg_type_tip = "一体どうやって技を放つんだ？"
	
	if act.ability.is_empty() == false: # 技の追加効果が存在する場合
		if (len(act.ability) != len(act.ability_chance) or # エラー処理
		len(act.ability_chance) != len(act.ability_power) or 
		len(act.ability_power) != len(act.ability)):
			$エラーメッセージ.dialog_text = "エラーメッセージ\n\
			特殊効果カテゴリの配列のサイズが一致しません！"
			$エラーメッセージ.popup_centered()
			return
			
		for i in len(act.ability):
			var ability = load("res://description_ui_ability.tscn").instantiate()
			var text = ability.get_child(0)
			
			var ability_text = "" # 特殊効果の名前
			var ability_tip = "" # 特殊効果の説明
			var ability_power = "" # 特殊効果の効果量
			match act.ability[i].category: # 状態異常
				0:
					ability_power = "状態異常継続ターン数:[color=red]%d[/color]" % \
					act.ability_power[i]
					match act.ability[i].ailment:
						1:
							ability_text = "[color=red]火傷[/color]"
							ability_tip = "相手を火傷状態にします"
							ability.color = Color(1, 0, 0, 0.5) # red
						2:
							ability_text = "[color=dodger_blue]水圧[/color]"
							ability_tip = "相手を水圧状態にします"
							ability.color = Color(0, 0, 1, 0.5) # blue
						3:
							ability_text = "[color=yelllow]感電[/color]"
							ability_tip = "相手を感電状態にします"
							ability.color = Color(1, 1, 0, 0.5) # yellow
						4:
							ability_text = "[color=chocolate]泥々[/color]"
							ability_tip = "相手を泥々状態にします" # brown
							ability.color = Color(0.647059, 0.164706, 0.164706, 0.5)
						5:
							ability_text = "[color=green]竜巻[/color]"
							ability_tip = "相手を竜巻状態にします"
							ability.color = Color(0, 1, 0, 0.5) # green
						6:
							ability_text = "[color=aqua]霜焼[/color]"
							ability_tip = "相手を霜焼状態にします"
							ability.color = Color(0, 1, 1, 0.5) # aqua
						7:
							ability_text = "[color=light_yellow]紫外線[/color]"
							ability_tip = "相手を紫外線状態にします"
							ability.color = Color(1, 1, 0.878431, 0.5) # light_yellow
						8:
							ability_text = "[color=violet]呪い[/color]"
							ability_tip = "相手を呪い状態にします"
							ability.color = Color(0.580392, 0, 0.827451, 0.5) # violet
				2: # バフ
					ability_power = "バフ継続ターン数:[color=red]%d[/color]" % \
					act.ability_power[i]
					ability.color = Color(0.545098, 0, 0, 0.5) # dark_red
					match act.ability[i].buff:
						1:
							ability_text = "[color=red]ATK UP[/color]"
							ability_tip = "ATKを1.5倍に強化させます"
						2:
							ability_text = "[color=light_blue]DEF UP[/color]"
							ability_tip = "DEFを1.5倍に強化させます"
						3:
							ability_text = "[color=dodger_blue]MAG UP[/color]"
							ability_tip = "MAGを1.5倍に強化させます"
						4:
							ability_text = "[color=purple]RES UP[/color]"
							ability_tip = "RESを1.5倍に強化させます"
						5:
							ability_text = "[color=green]SPD UP[/color]"
							ability_tip = "SPDを???倍に強化させます"
						_:
							ability_text = "[color=red][b]ERROR[/b][/color]"
							ability_tip = "強化するものすら存在しなかった"
				3: # デバフ
					ability_power = "デバフ継続ターン数:[color=red]%d[/color]" % \
					act.ability_power[i]
					ability.color = Color(0, 0, 0.545098, 0.5) # dark_blue
					match act.ability[i].debuff:
						1:
							ability_text = "[color=red]ATK DOWN[/color]"
							ability_tip = "ATKを2/3倍に弱体化させます"
						2:
							ability_text = "[color=light_blue]DEF DOWN[/color]"
							ability_tip = "DEFを2/3倍に弱体化させます"
						3:
							ability_text = "[color=dodger_blue]MAG DOWN[/color]"
							ability_tip = "MAGを2/3倍に弱体化させます"
						4:
							ability_text = "[color=purple]RES DOWN[/color]"
							ability_tip = "RESを2/3倍に弱体化させます"
						5:
							ability_text = "[color=green]SPD DOWN[/color]"
							ability_tip = "SPDを???倍に弱体化させます"
						_:
							ability_text = "[color=red][b]ERROR[/b][/color]"
							ability_tip = "弱体化するものすら存在しなかった"
				4: # 回復 forest_green
					ability.color = Color(0.133333, 0.545098, 0.133333, 0.5)
					var status: String # 参照するステータス名
					match act.damage_type:
						1:
							status = "[color=red]ATK[/color]"
						2:
							status = "[color=dodger_blue]MAG[/color]"
					match act.ability[i].healing:
						1:
							ability_text = "[color=green]HP回復[/color]"
							ability_tip = "ステータスを参照してHPを回復させます"
							ability_power = "HP回復量:%sの[color=red]%d%%[/color]相当" % \
							[status, act.ability_power[i]]
						2:
							ability_text = "[color=green]定数HP回復[/color]"
							ability_tip = "一定の量だけHPを回復させます"
							ability_power = "HP回復量:[color=red]%d[/color]" % \
							act.ability_power[i]
						3:
							ability_text = "[color=aqua]MP回復[/color]"
							ability_tip = "ステータスを参照してMPを回復させます"
							ability_power = "未実装"
						4:
							ability_text = "[color=aqua定数MP回復[/color]"
							ability_tip = "一定の量だけMPを回復させます"
							ability_power = "MP回復量:[color=red]%d[/color]" % \
							act.ability_power[i]
						_:
							ability_text = "[color=red][b]ERROR[/b][/color]"
				5: # 吸収
					ability_power = "吸収率:[color=red]%d%%[/color]" % act.ability_power[i]
					ability.color = Color(1, 0.411765, 0.705882, 1) # hot_pink
					match act.ability[i].steal:
						1:
							ability_text = "[color=green]HP吸収[/color]"
							ability_tip = "与えたダメージに対して一定の割合でHPを回復させます"
						2:
							ability_text = "[color_aqua]MP吸収[/color]"
							ability_tip = "与えたダメージに対して一定の割合でMPを回復させます"
						3:
							ability_text = "[color=green]SPD吸収[/color]"
							ability_tip = "未実装"
			
			var ability_range_text = ""
			var ability_range_tip = ""
			match act.ability_range[i]:
				0: # rangeと同期
					ability_range_text = range_text
					ability_range_tip = range_text + "に効果を発動します"
				1:
					ability_range_text = "敵単体"
					ability_range_tip = "敵単体に効果を発動します"
				2:
					ability_range_text = "敵全体"
					ability_range_tip = "敵全体に効果を発動します。"
				3:
					ability_range_text = "味方単体"
					ability_range_tip = "味方単体に効果を発動します。"
				4:
					ability_range_text = "味方全体"
					ability_range_tip = "味方全体に効果を発動します。"
				5:
					ability_range_text = "自分"
					ability_range_tip = "自分に効果を発動します。"
				_:
					ability_range_text = "[color=red][b]ERROR[/b][/color]"
					ability_range_tip = "虚空に向かって効果を発動するのか？"
			
			text.text = "[center][hint=" + ability_tip + "]" + ability_text + \
			"[/hint]\n[hint=" + ability_range_tip + "]対象:[color=yellow]" + \
			ability_range_text + "[/color][/hint] [hint=特殊効果の発生確率]" + \
			"確率:[color=green]%3d%%[/color][/hint]\n" % act.ability_chance + \
			ability_power + "[/center]"
			
			if i != 0: # 複数のabilityを持つときabilityの表示位置をずらす
				ability.position.y += i * 80 # abilityの位置はループごとにリセットされるので乗算
				$description_ui/description.position.y += 80 # descriptionの位置は
				$description_ui/description.size.y -= 80 # ループしてもリセットされない
			
			$description_ui.add_child(ability,-1)
	
	else: # 技の追加効果が存在しない場合
		var ability = load("res://description_ui_ability.tscn").instantiate()
		ability.color = Color(0, 0, 0, 0.5)
		var text = ability.get_child(0)
		text.text = "[center]なし\n対象:[color=yellow]――――[/color] 確率:[color=green]---%[/color][/center]"
		$description_ui.add_child(ability,-1)
	
	$description_ui/name/name_text.text = "[center][b][i]" + aka + "[/i][/b][/center]"
	$description_ui/damage_type/damage_type_text.text = "[center][hint=" + dmg_type_tip + \
	"]分類:" + dmg_type_text + "[/hint][/center]"
	$description_ui/target/target_text.text = "[center][hint=" + range_tip + \
	"]対象:[color=yellow]" + range_text + "[/color][/hint][/center]"
	$description_ui/max_frequency/max_frequency_text.text = "[center][hint=技の出現率を設定できる上限\n
	この値を越える確率で技が選ばれることはありません]出現率上限[color=green]" + \
	str(act.max_chance) + "%[/color][/hint][/center]"
	$description_ui/mp/mp_text.text = "[center][hint=技の使用に必要なMP]MP Cost:[color=aqua]" + \
	str(act.mp) + "[/color][/hint][/center]"
	$description_ui/power/power_text.text = "[center][hint=技の基礎的な威力]Power:[color=red]" + \
	str(act.power) + "[/color][/hint][/center]"
	$description_ui/description.text = act.description


func ui_update(): # 先にsliderのvalueを取得しなければlabelのtextを更新できないためforループを2つ使用せざるを得ない
	sum_chance = 0 # 初期化処理
	print(selected_action)
	
	var slider = [] # sliderノードを格納
	var label = [] # labelノードを格納
	var spinbox = [] # spinboxノードを格納
	for child in $出現率設定UI/出現率設定UI.get_children(): # 子ノードをforループ
		if child is HSlider: # slider分類
			slider.append(child)
		elif child is RichTextLabel: # label分類
			label.append(child)
	for child in $"出現率設定UI".get_children():
		if child is SpinBox:
			spinbox.append(child)
			
	for i: int in len(slider): # HSliderから、value取得  sliderとselected_action_nameのindexを同期させている
		if len(selected_action) > i: # 現在選択中の技のみ
			var action: Action = selected_action.keys()[i]
			slider[i].max_value = float(action.max_chance)
			slider[i].set_value_no_signal(selected_action[action])
			slider[i].tick_count = action.max_chance / 10 + 1 # スライダー目盛り生成
			slider[i].editable = true
		else: # 未選択のものは初期化＋非表示
			slider[i].set_value_no_signal(0) # この関数を使うとvalue_changedに影響を与えずにvalueを変更できる
			slider[i].tick_count = 0
			slider[i].editable = false
	
	for i: int in len(spinbox):
		if len(selected_action) > i:
			var action: Action = selected_action.keys()[i]
			spinbox[i].max_value = float(action.max_chance)
			spinbox[i].set_value_no_signal(selected_action[action])
			spinbox[i].editable = true
		else:
			spinbox[i].set_value_no_signal(0)
			spinbox[i].editable = false
	
	for i: int in len(label): # TODO 今後、複数属性を持つ場合にも対応する
		if len(selected_action) > i:
			var action: Action = selected_action.keys()[i]
			label[i].text = " [img=20]%s[/img] %s" % \
			[action.element[0].icon.resource_path, action.name]
		else:
			label[i].text = " 未設定"
	
	var color_list: Array[String]
	for i in selected_action.values(): # 出現率の合計値を取得
		sum_chance += i
	if sum_chance == 100:
		color_list = ["green", "white"]
	else:
		color_list = ["red", "yellow"]
	$status/chance.text = "[b]現在の出現率[/b]\n\n" + \
	"合計 : [color=%s]%3d%%[/color]\n余り : [color=%s]%3d%%[/color]" % \
	[color_list[0], sum_chance, color_list[1], 100 - sum_chance]
	now_select_action = 0

func _on_act_slider_1_value_changed(value):
	print("slider1 changed:", value)
	value_change(0, value)

func _on_act_slider_2_value_changed(value):
	print("slider2 changed:", value)
	value_change(1, value)

func _on_act_slider_3_value_changed(value):
	print("slider3 changed:", value)
	value_change(2, value)

func _on_act_slider_4_value_changed(value):
	print("slider4 changed:", value)
	value_change(3, value)

func value_change(i: int, value: int) -> void:
	selected_action[selected_action.keys()[i]] = value
	ui_update()


func status_text(monster: Monster) -> void:
	for label in $status/VBoxContainer.get_children():
		label.queue_free()
	$status/monster.texture = monster.image
	match monster.form:
		0:
			$status/title.text = "" 
		1:
			$status/title.text = "[center][color=yellow]中間進化後のステータス[/color][/center]"
		2:
			$status/title.text = "[center][color=red]進化後のステータス[/color][/center]"
	for label in Global.all_status(monster, 35):
		$status/VBoxContainer.add_child(label)

func reset():
	for act_ui in $出現率設定UI/出現率設定UI.get_children():
		if act_ui is HSlider:
			act_ui.set_value_no_signal(0)
			act_ui.editable = false
	selected_skill = 0
	selected_action.clear()


func _on_技_draw(): # それぞれの技の形態のタブを開くときにステータス表示を変える
	status_text(monster_data[monster_id][0])

func _on_中間進化技_draw():
	status_text(monster_data[monster_id][1])

func _on_進化技_draw(): # 最終形態の呼び出しは、1回進化でも2回進化でもindex　-1で参照できる
	status_text(monster_data[monster_id][2])
