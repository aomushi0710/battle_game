extends Control

@onready var camera: Camera2D = $"../Camera2D"
@onready var back_button: Button = $"../CanvasLayer/Control/戻る"
@onready var confirm_button: Button = $"../CanvasLayer/Control/決定"
@onready var action_select: Control = $action_select
@onready var slider: HSlider = $action_select/chance
@onready var spinbox: SpinBox = $action_select/SpinBox
const action_button = preload("res://action_button.tscn")
var selected_action: Action ## 現在選択中の技
var selected_skill = 0 # 選ばれたスキルパターン
var now_select_action = 0 # 現在指定されている技
var monster_data = Global.monster_data # モンスターの各種データ取得
var action_data = Global.action_data # 技の各種データ取得
var monster_id = Global.selected_monster
var actions: Array[Action] = [null, null, null, null] ## 選ばれた技
var chances: Array[int] = [0, 0, 0, 0] ## 選ばれた技の出現確率
var check_provability = [] # 出現率0%弾き出し用
var pie_chart
var camera_mode: CameraMode = CameraMode.MAIN: ## 現在のカメラ位置
	set(mode): ## 対応する画面遷移を行ってからモード変更
		# 全てのボタンを使用不可に
		for child in $"../CanvasLayer/Control".get_children():
			if child is Button:
				child.disabled = true
		## カメラ移動アニメーション
		var tween: Tween = get_tree().create_tween().bind_node(camera)
		match mode:
			CameraMode.MAIN:
				tween.tween_property(camera, "offset:x", 960, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "決定！"
			CameraMode.ACTION:
				tween.tween_property(camera, "offset:x", 1750, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "登録！"
		await tween.finished
		# モード切り替え
		camera_mode = mode
		# 全てのボタンを使用可能に
		for child in $"../CanvasLayer/Control".get_children():
			if child is Button:
				child.disabled = false
		if mode == CameraMode.ACTION and selected_action in actions: # 既に選ばれた技を選んだ時
			confirm_button.disabled = true # 再登録を不可に上書き
			
enum CameraMode{
	MAIN, ## 真ん中の画面
	ACTION, ## 右の技選択画面
}

func _ready() -> void:
	camera.offset = Vector2(960, 540)
	# 進化前モンスターを表示
	$monster.texture = Global.monster_data[Global.selected_monster][0].image
	# すでに登録されているものと同じモンスターを選んだ場合、その技をロード
	if Global.deck1.monster[Global.now_picking] != null:
		if Global.deck1.monster[Global.now_picking].id == monster_id:
			for i in len(Global.deck1.action[Global.now_picking]):
				# 以下、追加部分
				actions[i] = Global.deck1.action[Global.now_picking][i]
				chances[i] = Global.deck1.chance[Global.now_picking][i]
			# 円グラフ生成
			pie_chart = load("res://PieChart_action.tscn").instantiate()
			pie_chart.position = Vector2(1370, 80)
			add_child(pie_chart)
			pie_chart_update()

## 円グラフ更新関数
func pie_chart_update() -> void:
	pie_chart.actions = actions
	pie_chart.chances = chances
	pie_chart.update()
	# グラフ色と確率表記
	var nodes_i: int = 0 ## nodesのインデックス指定用
	for child: ColorRect in $actions/chart_colors.get_children():
		child.color = pie_chart.nodes[nodes_i].tint_progress
		child.get_child(0).text = "%d%%" % chances[nodes_i]
		nodes_i += 1
	# 技ボタン生成と技削除ボタン有効無効切り替え
	for child in $actions/action_buttons.get_children():
		child.queue_free()
	for i in len(actions):
		var button = action_button.instantiate()
		button.action = actions[i]
		if button.action == null: # 技がなければ
			button.disabled = true # ボタン無効
		button.button_up.connect(func(): action_button_up(button.action))
		$actions/action_buttons.add_child(button)
		if actions[i] == null:
			$actions/delete_buttons.get_child(i).disabled = true
		else:
			$actions/delete_buttons.get_child(i).disabled = false

## 技ボタンが押された時の関数
func action_button_up(act: Action) -> void:
	selected_action = act
	# まだ移動していなければカメラ移動
	if camera_mode != CameraMode.ACTION:
		camera_mode = CameraMode.ACTION
	if selected_action in actions: # 既に選ばれた技を選んだ時
		confirm_button.disabled = true # 再登録を不可に
	## 元々ボタンがあれば取得される
	var exists = action_select.get_node_or_null("action_button")
	if exists: # 存在したら削除
		action_select.remove_child(exists)
		exists.queue_free()
	## 新たに表示されるボタン
	var button = action_button.instantiate()
	button.name = "action_button"
	button.position = Vector2(160, 20)
	button.action = act
	action_select.add_child(button)
	# sliderとspinboxのセッティング
	for node in [slider, spinbox]:
		node.max_value = float(act.max_chance)
		if act in actions:
			node.set_value_no_signal(chances[actions.find(act)])
		else:
			node.set_value_no_signal(0)
	slider.tick_count = slider.max_value / 10 + 1

## 技削除ボタンの処理
func delete_button_up(i: int) -> void:
	actions[i] = null
	chances[i] = 0
	pie_chart_update()

## 戻るボタンの処理
func _on_戻る_button_up():
	match camera_mode:
		CameraMode.MAIN: # キャラ選択に戻す
			reset()
			get_tree().change_scene_to_packed(Global.chara_scene)
		CameraMode.ACTION: # 画面を戻す
			camera_mode = CameraMode.MAIN

## 決定ボタンの処理
func _on_決定_button_up():
	match camera_mode:
		CameraMode.MAIN:
			var monster_dict = monster_data[monster_id].duplicate() # Dictionary{Monster...}
			
			for i in len(chances): # 技が登録されているが0%になっている時
				if chances[i] == 0 and actions[i] != null:
					$エラーメッセージ.dialog_text = "出現率が0%の技は選択を解除してください！"
					$エラーメッセージ.popup_centered()
					return
			
			var sum_chance = 0 ## 技の出現率の合計
			for i: int in chances:
				sum_chance += i
			if sum_chance != 100:
				$エラーメッセージ.dialog_text = "出現率の合計が100%ではありません！"
				$エラーメッセージ.popup_centered()
				return
			
			if len(monster_dict) == 3: # 2回進化モンスター
				for evol_action in monster_dict[2].actions: # 全ての進化技をループ
					for middle_evol_action in monster_dict[1].actions: # 全ての中間進化技をループ
						# 進化技は選択されているが、中間進化技が選択されていない場合に警告メッセージ
						if evol_action in actions and \
						middle_evol_action not in actions:
							$エラーメッセージ.dialog_text = "中間進化技が選択されていません！\nこのモンスターは進化が2回必要です"
							$エラーメッセージ.popup_centered()
							return
			#elif selected_skill == 0: #スキル実装後に実装
				#$エラーメッセージ.dialog_text = "スキルが選択されていません！"
				#$エラーメッセージ.popup_centered()
				#return
			Global.deck1.monster_dict[Global.now_picking] = monster_data[monster_id]
			Global.deck1.monster[Global.now_picking] = \
			Global.deck1.monster_dict[Global.now_picking][0].duplicate()
			# nullは消す
			Global.deck1.action[Global.now_picking] = actions.filter(func(x): return x != null)
			# 0は消す
			Global.deck1.chance[Global.now_picking] = chances.filter(func(x): return x != 0)
			#Global.deck1.skill[Global.now_picking] = selected_skill
			reset()
			get_tree().change_scene_to_packed(Global.deck_scene)
		CameraMode.ACTION:
			if selected_action in actions: # 既存の技を選択中の時
				$エラーメッセージ.dialog_text = "既に登録されている技です！"
				$エラーメッセージ.popup_centered()
				return
			if null not in actions: # 空きスペース(null)がない時
				$エラーメッセージ.dialog_text = \
				"技は4個までしか登録できません！\n既に登録されている技を削除してください！"
				$エラーメッセージ.popup_centered()
				return
			if slider.value == 0:
				$エラーメッセージ.dialog_text = "0%で技を登録することはできません！"
				$エラーメッセージ.popup_centered()
				return
			# 元々選択されている技の出現率に、登録したい技の出現率を足す計算
			var sum_chance = 0
			for i: int in chances:
				sum_chance += i
			if sum_chance + slider.value > 100:
				$エラーメッセージ.dialog_text = "技の出現率の合計が100%を越えてしまいます！"
				$エラーメッセージ.popup_centered()
				return


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


func reset():
	actions = [null, null, null, null]
	chances = [0, 0, 0, 0]
	selected_skill = 0

## slider及びspinboxの値が変更された時に、反映させる関数
func _on_chance_value_changed(value: float) -> void:
	for node in [slider, spinbox]: # sliderとspinboxを更新
		node.set_value_no_signal(value)
	if selected_action in actions: # もし既に選択中の技であれば、
		chances[actions.find(selected_action)] = int(value) # 技一覧の確率も変更
		pie_chart_update()
