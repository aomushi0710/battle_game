extends Control

@onready var se := $"../SoundEffects"
@onready var background := $"../background"
@onready var camera := $"../Camera2D"
@onready var accept_dialog = $"../AcceptDialog"
@onready var back_button := $"../CanvasLayer/Control/戻る"
@onready var confirm_button := $"../CanvasLayer/Control/決定"
@onready var help_mask := $"../CanvasLayer/Control/Panel/mask"
@onready var help_label := $"../CanvasLayer/Control/Panel/mask/help"
@onready var action_select := $action_select
@onready var slider := $action_select/chance
@onready var spinbox := $action_select/SpinBox
@onready var action_list := $action_list
var text_speed: float = 0.05 ## テキストアニメーションの1文字あたりの再生速度
var selected_action: Action ## 現在選択中の技
var selected_skill = 0 # 選ばれたスキルパターン
var now_select_action = 0 # 現在指定されている技
var monster_id = Global.selected_monster
var monster_dict ## 現在選択中のモンスターの辞書
var actions: Array[Action] = [null, null, null, null] ## 選ばれた技
var chances: Array[int] = [0, 0, 0, 0] ## 選ばれた技の出現確率
var check_provability = [] # 出現率0%弾き出し用
var pie_chart
var text_tween: Tween
var camera_tween: Tween
var camera_mode: CameraMode = CameraMode.MAIN: ## 現在のカメラ位置
	set(mode): ## 対応する画面遷移を行ってからモード変更
		# 全てのボタンを使用不可に
		for child in $"../CanvasLayer/Control".get_children():
			if child is Button:
				child.disabled = true
		## カメラ移動アニメーション
		camera_tween = get_tree().create_tween().bind_node(camera)
		match mode:
			CameraMode.MAIN:
				background.color_change(Color.GREEN) # 背景カラーチェンジ
				camera_tween.tween_property(camera, "offset:x", 960, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "決定！"
			CameraMode.ACTION:
				background.color_change(Color.ORANGE) # 背景カラーチェンジ
				camera_tween.tween_property(camera, "offset:x", 1750, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "登録！"
		await camera_tween.finished
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
	monster_dict = Global.monster_data[monster_id].duplicate() # 初期化
	camera.offset = Vector2(960, 540)
	# 進化前モンスターを表示
	$monster.texture = monster_dict[0].image
	# すでに登録されているものと同じモンスターを選んだ場合、その技をロード
	if Global.deck1.monster[Global.now_picking] != null:
		if Global.deck1.monster[Global.now_picking].id == monster_id:
			for i in len(Global.deck1.action[Global.now_picking]):
				# 以下、追加部分
				actions[i] = Global.deck1.action[Global.now_picking][i]
				chances[i] = Global.deck1.chance[Global.now_picking][i]
	
	# 円グラフ生成
	pie_chart = load("res://pie_chart.tscn").instantiate()
	pie_chart.position = Vector2(950, 70)
	add_child(pie_chart)
	pie_chart_update()
	
	setting_action_button()
	# スクリプト上でしかtabbarはいじれないので
	action_list.get_tab_bar().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	connect_hover_signal($"..")

## help_textデータを持つ全てのノード[param node]にシグナルを接続する再起関数
func connect_hover_signal(node: Node) -> void:
	if node is Control and node.has_meta("help_text"):
		node.mouse_entered.connect(func(): 
			var text: String = "[i]%s[/i]" % node.get_meta("help_text")
			text_animation(help_label, text.replace("\n", "")))
		node.mouse_exited.connect(func():
			text_animation(help_label, "[i]ボタンにカーソルを合わせるとヘルプテキストが表示されます。[/i]"))
	
	for child in node.get_children():
		connect_hover_signal(child)

## [param label]に表示される[param text]を少しずつ表示させるアニメーションを再生する関数
func text_animation(label: RichTextLabel, text: String) -> void:
	# アニメーション中なら中断
	if text_tween and text_tween.is_running():
		text_tween.kill()
	
	label.text = text
	label.size.x = label.get_content_width()
	label.position.x = 0
	# 文字が枠をはみ出す時
	if label.get_content_width() > help_mask.size.x:
		label.text += "　　" # 前後を空白で区切る
		var final_val: int = -label.get_content_width() # 1ループ分の移動先
		var duration: float = -final_val * text_speed * 0.1
		label.text += text # ループ後に元の文字が戻ってくるように追加
		label.size.x = label.get_content_width() # 画面外に消えるのを防止
		
		text_tween = get_tree().create_tween().bind_node(label).set_loops()
		text_tween.tween_interval(2)
		text_tween.tween_property(label, "position:x", final_val, duration)
		text_tween.tween_callback(func(): label.position.x = 0)

## 円グラフ更新関数
func pie_chart_update() -> void:
	pie_chart.actions = actions
	pie_chart.chances = chances
	pie_chart.queue_redraw()
	await pie_chart.draw_ended # draw関数終了を待つ
	# グラフ色と確率表記
	var nodes_i: int = 0 ## nodesのインデックス指定用
	for child: Panel in $actions/chart_colors.get_children():
		var panel: StyleBoxFlat = child.get_theme_stylebox("panel")
		if actions[nodes_i] != null:
			panel.bg_color = pie_chart.color_list[nodes_i]
			panel.shadow_size = 30
		else:
			panel.bg_color = Color.BLACK
			panel.shadow_size = 0
		child.get_child(0).text = "%d%%" % chances[nodes_i]
		nodes_i += 1
	# 技ボタン生成と技削除ボタン有効無効切り替え
	for child in $actions/action_buttons.get_children():
		child.queue_free()
	for i in len(actions):
		var button = Global.action_button.instantiate()
		button.action = actions[i]
		button.button_up.connect(func(): action_button_up(button.action))
		if actions[i] == null:
			$actions/delete_buttons.get_child(i).disabled = true
			$actions/delete_buttons.get_child(i).mouse_default_cursor_shape = \
			CursorShape.CURSOR_ARROW
			button.set_meta("help_text", "技が登録されていません。クリックで登録画面に移動します。")
		else:
			$actions/delete_buttons.get_child(i).disabled = false
			$actions/delete_buttons.get_child(i).mouse_default_cursor_shape = \
			CursorShape.CURSOR_POINTING_HAND
			button.set_meta("help_text", "現在登録されている技。クリックで登録画面に移動します。")
		connect_hover_signal(button)
		$actions/action_buttons.add_child(button)

## 全ての形態に関して、技をそれぞれのコンテナにボタン化して追加する関数
func setting_action_button() -> void:
	for monster: Monster in monster_dict.values():
		## 技が追加されるコンテナ(TabContainer -> ScrollContainer -> VboxContainer)
		var container = action_list.get_child(monster.form).get_child(0)
		for act: Action in monster.actions:
			var button = Global.action_button.instantiate()
			button.action = act
			button.button_up.connect(func(): action_button_up(button.action))
			button.set_meta("help_text", "クリックで技の詳細を確認できます。")
			container.add_child(button)

## 技ボタンが押された時の関数
func action_button_up(act: Action, extra: bool = false) -> void:
	var container := $action_description/ability/container
	for child in container.get_children(): # 初期化
		child.queue_free()
	
	if camera_mode != CameraMode.ACTION: # まだ移動していなければカメラ移動
		camera_mode = CameraMode.ACTION
	
	if act == null: # nullなら移動だけして中断
		return
	
	$action_select.show() # nullじゃなければ表示
	
	selected_action = act
	# 選ばれた技が既に登録されているかどうかで登録ボタンの挙動を変える
	if act in actions:
		confirm_button.disabled = true
	else:
		confirm_button.disabled = false
	## 元々ボタンがあれば取得される
	var exists = action_select.get_node_or_null("action_button")
	if exists: # 存在したら削除
		action_select.remove_child(exists)
		exists.queue_free()
	## 新たに表示されるボタン
	var button = Global.action_button.instantiate()
	button.name = "action_button"
	button.position = Vector2(160, 20)
	button.action = act
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW # カーソルも戻す
	button.set_meta("help_text", act.description)
	connect_hover_signal(button)
	action_select.add_child(button)
	
	if extra == true: # 技ボタン以外隠す
		for child in action_select.get_children():
			if child is Range:
				child.editable = false
				if child is HSlider:
					child.tick_count = 0
			elif child is RichTextLabel:
				child.hide()
	else:
		for node in [slider, spinbox]: # sliderとspinboxのセッティング
			# この時点では、先に設定していた技の最大値を、次に選ばれた技の確率が越えていた場合に、
			# 最大値に引っかかってしまう
			if act in actions:
				node.set_value_no_signal(chances[actions.find(act)])
			else:
				node.set_value_no_signal(0)
			node.max_value = float(act.max_chance)
			# もう一度値を設定して、適切な値に戻す
			if act in actions:
				node.set_value_no_signal(chances[actions.find(act)])
			$action_select/max_chance.text = "%d%%" % act.max_chance
			node.editable = true
		slider.tick_count = slider.max_value / 10 + 1
	
	var power: RichTextLabel = $action_description/power
	var mp: RichTextLabel = $action_description/mp
	var type: RichTextLabel = $action_description/type
	var target: RichTextLabel = $action_description/target
	power.text = "[color=red]Power[/color]:%4d" % act.power
	mp.text = "[color=aqua]MP   [/color]:%4d" % act.mp
	
	match act.damage_type: # 分類によってテキストと枠線を変える
		Action.DamageType.なし:
			type.text = "分類:なし"
			var style: StyleBoxFlat = type.get_theme_stylebox("normal")
			style.border_color = Color.WHITE
		
		Action.DamageType.物理:
			type.text = "分類:[color=red]物理[/color]"
			var style: StyleBoxFlat = type.get_theme_stylebox("normal")
			style.border_color = Color.RED
		
		Action.DamageType.魔法:
			type.text = "分類:[color=dodger_blue]魔法[/color]"
			var style: StyleBoxFlat = type.get_theme_stylebox("normal")
			style.border_color = Color.DODGER_BLUE
	
	match act.target: # 範囲によってテキストを変える
		Global.Target.なし:
			target.text = "[color=yellow]対象[/color]:なし"
		
		Global.Target.近接:
			target.text = "[color=yellow]対象[/color]:近接"
		
		Global.Target.遠隔:
			target.text = "[color=yellow]対象[/color]:遠隔"
		
		Global.Target.敵全体:
			target.text = "[color=yellow]対象[/color]:敵全体"
		
		Global.Target.自分:
			target.text = "[color=yellow]対象[/color]:自分"
		
		Global.Target.味方単体:
			target.text = "[color=yellow]対象[/color]:味方単体"
		
		Global.Target.味方全体:
			target.text = "[color=yellow]対象[/color]:味方全体"
		
		Global.Target.敵味方全体:
			target.text = "[color=yellow]対象[/color]:敵味方全体"
	
	for ability: Ability in act.ability:
		var description = Global.ability_description.instantiate()
		description.ability = ability
		description.set_meta("help_text", ability.description)
		connect_hover_signal(description)
		container.add_child(description)

## 技削除ボタンの処理
func delete_button_up(i: int) -> void:
	actions[i] = null
	chances[i] = 0
	pie_chart_update()

## 戻るボタンの処理
func _on_戻る_button_up():
	se.click.play()
	match camera_mode:
		CameraMode.MAIN: # キャラ選択に戻す
			reset()
			get_tree().change_scene_to_file(Global.chara_scene)
		CameraMode.ACTION: # 画面を戻す
			camera_mode = CameraMode.MAIN

## 決定ボタンの処理
func _on_決定_button_up():
	se.click.play()
	match camera_mode:
		CameraMode.MAIN:
			var sum_chance = 0 ## 技の出現率の合計
			for i: int in chances:
				sum_chance += i
			if sum_chance != 100:
				accept_dialog.display_dialog("出現率の合計が100%ではありません！")
				return
			
			if len(monster_dict) == 3: # 2回進化モンスター
				for evol_action in monster_dict[2].actions: # 全ての進化技をループ
					for middle_evol_action in monster_dict[1].actions: # 全ての中間進化技をループ
						# 進化技は選択されているが、中間進化技が選択されていない場合に警告メッセージ
						if evol_action in actions and \
						middle_evol_action not in actions:
							accept_dialog.display_dialog(
								"中間進化技が選択されていません！\nこのモンスターは進化が2回必要です")
							return
			#elif selected_skill == 0: #スキル実装後に実装
				#$エラーメッセージ.dialog_text = "スキルが選択されていません！"
				#$エラーメッセージ.popup_centered()
				#return
			
			for i in len(chances): # 技が登録されているが0%になっている時、nullを入れる
				if chances[i] == 0:
					actions[i] = null
			
			Global.deck1.monster_dict[Global.now_picking] = monster_dict
			Global.deck1.monster[Global.now_picking] = \
			Global.deck1.monster_dict[Global.now_picking][0].duplicate()
			# nullは消す
			Global.deck1.action[Global.now_picking] = actions.filter(func(x): return x != null)
			# 0は消す
			Global.deck1.chance[Global.now_picking] = chances.filter(func(x): return x != 0)
			#Global.deck1.skill[Global.now_picking] = selected_skill
			reset()
			get_tree().change_scene_to_file(Global.deck_scene)
		CameraMode.ACTION:
			if selected_action in actions: # 既存の技を選択中の時
				accept_dialog.display_dialog("既に登録されている技です！\n\n" + 
				"───妙だな、\"今\"このボタンが押されるなんて。\n" + 
				"こんなこともあろうかと、対策を施していて正解だった。")
				return
			if null not in actions: # 空きスペース(null)がない時
				accept_dialog.display_dialog(
					"技は4個までしか登録できません！\n既に登録されている技を削除してください！")
				return
			# 元々選択されている技の出現率に、登録したい技の出現率を足す計算
			var sum_chance = 0
			for i: int in chances:
				sum_chance += i
			if sum_chance + slider.value > 100:
				accept_dialog.display_dialog("技の出現率の合計が100%を越えてしまいます！")
				return
			
			confirm_button.disabled = true
			
			var index = actions.find(null) ## 空き枠のうち先頭のインデックスを取得
			actions[index] = selected_action
			chances[index] = int(slider.value)
			pie_chart_update()


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
func _on_chance_value_changed(value: int) -> void:
	if selected_action in actions: # 既に選択中の技の時
		var sum_chance: int = 0
		var index: int = actions.find(selected_action) ## 既に選択中の技のインデックス
		var previous_chances = chances.duplicate() ## 選択中の技を除いたchances
		var previous_value = previous_chances.pop_at(index)
		
		for i: int in previous_chances:
			sum_chance += i
		sum_chance += value
		
		if sum_chance > 100: # 100%を越える場合、元の値に差し戻し
			accept_dialog.display_dialog("技の出現率の合計が100%を越えてしまいます！")
			value = previous_value # 元の値に戻す
		else:
			chances[index] = value # 技一覧の確率と円グラフを更新
			pie_chart_update()
	
	for node in [slider, spinbox]: # sliderとspinboxを更新
		node.set_value_no_signal(value)
