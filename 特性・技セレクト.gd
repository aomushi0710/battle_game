extends Control

var selected_skill = 0 # 選ばれたスキルパターン
var now_select_action = 0 # 現在指定されている技
var sum_chance = 0 # 出現率の合計
var monster_data = Global.monster_data # モンスターの各種データ取得
var action_data = Global.action_data # 技の各種データ取得
var monster_id = Global.selected_monster
var selected_action = {} # key:選ばれた技(Action) value:出現率(int)
var actions: Array[Action] = [null, null, null, null] ## 選ばれた技
var chances: Array[int] = [0, 0, 0, 0] ## 選ばれた技の出現確率
var check_provability = [] # 出現率0%弾き出し用
var pie_chart

func _ready() -> void:
	_on_技_draw()
	selected_action.clear() # 以下2行、初期化処理
	sum_chance = 0
	
	# すでに登録されているものと同じモンスターを選んだ場合、その技をロード
	if Global.player_deck.monster[Global.now_picking] != null:
		if Global.player_deck.monster[Global.now_picking].id == monster_id:
			for i in len(Global.player_deck.action[Global.now_picking]):
				selected_action[Global.player_deck.action[Global.now_picking][i]] = \
				Global.player_deck.chance[Global.now_picking][i] # selected_action生成
	ui_update()


func _on_戻る_button_up():
	reset()
	get_tree().change_scene_to_file(Global.chara_scene)

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
	Global.player_deck.monster_dict[Global.now_picking] = monster_data[monster_id]
	Global.player_deck.monster[Global.now_picking] = \
	Global.player_deck.monster_dict[Global.now_picking][0].duplicate()
	Global.player_deck.action[Global.now_picking] = action_list.keys()
	Global.player_deck.chance[Global.now_picking] = action_list.values()
	#Global.player_deck.skill[Global.now_picking] = selected_skill
	reset()
	get_tree().change_scene_to_file(Global.deck_scene)


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
		aka = "[hint=バトル中は %s と表示されます]%s[/hint]" % [act.aka, act.name]
	
	var descriptions: Array[String] = Global.action_description_creator(act, false)
	
	if act.ability.is_empty() == false: # 技の追加効果が存在する場合
		if (len(act.ability) != len(act.ability_chance) or # エラー処理
		len(act.ability_chance) != len(act.ability_power) or 
		len(act.ability_power) != len(act.ability)):
			$エラーメッセージ.dialog_text = "エラーメッセージ\n\
			特殊効果カテゴリの配列のサイズが一致しません！"
			$エラーメッセージ.popup_centered()
			return
			
		for i in len(act.ability):
			var ability_ui = load("res://description_ui_ability.tscn").instantiate()
			var text = ability_ui.get_child(0)
			
			var ability_descriptions: Array = \
			Global.ability_description_creator(act, i, false)
			
			text.text = "[center]%s\n%s %s\n%s[/center]" % \
			[ability_descriptions[0], ability_descriptions[1], 
			ability_descriptions[2], ability_descriptions[3]]
			
			ability_ui.color = ability_descriptions[4]
			
			if i != 0: # 複数のabilityを持つときabilityの表示位置をずらす
				ability_ui.position.y += i * 80 # abilityの位置はループごとにリセットされるので乗算
				$description_ui/description.position.y += 80 # descriptionの位置は
				$description_ui/description.size.y -= 80 # ループしてもリセットされない
			
			$description_ui.add_child(ability_ui,-1)
	
	else: # 技の追加効果が存在しない場合
		var ability = load("res://description_ui_ability.tscn").instantiate()
		ability.color = Color(0, 0, 0, 0.5)
		var text = ability.get_child(0)
		text.text = "[center]なし\n対象:[color=yellow]――――[/color] 確率:[color=green]---%[/color][/center]"
		$description_ui.add_child(ability,-1)
	
	$description_ui/name/name_text.text = "[center][b][i]%s[/i][/b][/center]" % aka
	$description_ui/element/element_text.selected(act, 25)
	$description_ui/damage_type/damage_type_text.text = "[center]%s[/center]" % descriptions[0]
	$description_ui/target/target_text.text = "[center]%s[/center]" % descriptions[1]
	$description_ui/max_frequency/max_frequency_text.text = "[center][hint=技の出現率を設定できる上限\n
	この値を越える確率で技が選ばれることはありません]出現率上限[color=green]%s%%[/color][/hint][/center]" % act.max_chance
	$description_ui/mp/mp_text.text = \
	"[center][hint=技の使用に必要なMP]MP Cost:[color=aqua]%s[/color][/hint][/center]" % act.mp
	$description_ui/power/power_text.text = \
	"[center][hint=技の基礎的な威力]Power:[color=red]%s[/color][/hint][/center]" % act.power
	$description_ui/description.text = act.description


func ui_update(): # 先にsliderのvalueを取得しなければlabelのtextを更新できないためforループを2つ使用せざるを得ない
	sum_chance = 0 # 初期化処理
	
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
	value_change(0, value)

func _on_act_slider_2_value_changed(value):
	value_change(1, value)

func _on_act_slider_3_value_changed(value):
	value_change(2, value)

func _on_act_slider_4_value_changed(value):
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


func _on_button_button_up() -> void:
	get_tree().change_scene_to_file(Global.select_scene)
