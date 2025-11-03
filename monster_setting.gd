extends "res://select.gd"

const STATUS_BAR_TEXT: Array[String] = [
	"[color=coral]HP [font_size=2]                   [/font_size][/color]:%4d", 
	"[table=2][cell][font_size=20][color=aqua]MP\nmax   " + 
	"[/color][/font_size][/cell][cell][center]:%4d[/center][/cell]", 
	"[table=2][cell][font_size=20][color=aqua]MP\nsupply" + 
	"[/color][/font_size][/cell][cell][center]:%4d[/center][/cell]", 
	"[color=limegreen]SPD[font_size=2]                   [/font_size][/color]:%4d", 
	"[color=orange]ATK[font_size=2]                   [/font_size][/color]:%4d", 
	"[color=lightblue]DEF[font_size=2]                   [/font_size][/color]:%4d", 
	"[color=dodgerblue]MAG[font_size=2]                   [/font_size][/color]:%4d", 
	"[color=violet]RES[font_size=2]                   [/font_size][/color]:%4d"
	]

@export var monster_node: TextureRect
@export var action_select: Control
@export var slider: HSlider
@export var spinbox: SpinBox
@export var action_description: Control
@export var action_list: TabContainer
@export var pie_chart: PieChart

var text_speed: float = 0.05 ## テキストアニメーションの1文字あたりの再生速度
var selected_action: Action ## 現在選択中の技
var selected_skill = 0 ## 選ばれたスキルパターン
var now_select_action = 0 ## 現在指定されている技
var evolution_forms: Array[Monster] ## 現在選択中のモンスターの全形態が登録されている配列
var all_status_list: Array = []
var actions: Array[Action] = [null, null, null, null] ## 選ばれた技
var chances: Array[int] = [0, 0, 0, 0] ## 選ばれた技の出現確率
var check_provability = [] ## 出現率0%弾き出し用
var text_tween: Tween

var level: int: ## プレビュー時のモンスターレベル
	set(value):
		level = value
		# 全ての形態のステータスを更新してリストに登録
		all_status_list.clear()
		for i in len(evolution_forms):
			evolution_forms[i].status_calculator(level)
			all_status_list.append(evolution_forms[i].get_status_list())
		
		if parent.mode == Mode.STATUS:
			monster_preview(selected_monster.form)
		else:
			monster_preview(selected_monster.form, true)


func on_mode_entered() -> void:
	camera.offset = Vector2(960, 540)
	
	# action_listの中身を削除
	for container in action_list.get_children():
		for child in container.get_child(0).get_children():
			child.queue_free()
	
	selected_monster = parent.selected_monster
	evolution_forms = Global.monster_data[selected_monster.id].duplicate() # 初期化
	
	# 進化プレビュー選択肢追加
	evolution_preview_button.clear()
	for i in len(evolution_forms):
			evolution_preview_button.add_item(Monster.form_names[i], i)
	
	# セーブデータ読み込み
	if selected_monster.id in Global.save_data.monster_levels:
		level_spinbox.value = Global.save_data.monster_levels[selected_monster.id]
	else:
		level_spinbox.value = 1
	# モンスターを表示
	monster_preview(selected_monster.form)
	
	# すでに登録されているものと同じモンスターを選んだ場合、その技をロード
	if (Global.player_deck.monster[Global.now_picking].monster != null and 
		Global.player_deck.monster[Global.now_picking].monster.id == selected_monster.id):
		actions = Global.player_deck.monster[Global.now_picking].action
		chances = Global.player_deck.monster[Global.now_picking].chance
	
	# 円グラフ生成
	pie_chart_update()
	
	setting_action_button()
	# スクリプト上でしかtabbarはいじれないので
	action_list.get_tab_bar().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_list.set_tab_metadata(0, "モンスターが発動できる技の一覧です。")
	action_list.set_tab_metadata(1, 
	"第二形態に進化したモンスターが、発動できる技の一覧です。この技を登録すると、" + 
	"バトル中に同じ確率で「進化Ⅰ」が現れ、進化することでこの技が発動できるようになります。")
	action_list.set_tab_metadata(2, 
	"第三形態に進化したモンスターが、発動できる技の一覧です。この技を登録すると、" + 
	"バトル中に同じ確率で「進化Ⅱ」が現れ、進化することでこの技が発動できるようになります。")

## モンスターの形態[param form]のプレビュー表示更新関数[br]
## [param is_text_only]が[code]false[/code]の時、棒グラフがアニメーションされる。
func monster_preview(form: Monster.Form, is_text_only: bool = false) -> void:
	if evolution_forms.is_empty():
		return
	
	# 棒グラフのアニメーションが終わるまで押せなくする
	evolution_preview_button.disabled = true
	
	selected_monster = evolution_forms[form]
	
	monster_node.texture = selected_monster.image
	monster_node.get_child(0).get_child(0).monster = selected_monster
	monster_node.get_child(0).get_child(1).text = (
		"[b][i]%s[/i][/b]" % selected_monster.name)
	
	bar_chart_update(is_text_only)

## ステータス棒グラフ更新関数[br]
## ## [param is_text_only]が[code]false[/code]の時、棒グラフがアニメーションされる。
func bar_chart_update(is_text_only: bool = false) -> void:
	var status_list = all_status_list[selected_monster.form] ## 表示したいモンスターのステータス一覧
	var status_index: int = 0 ## status_listのindex指定用
	for child in status.get_child(0).get_children():
		for c in child.get_children():
			if c is RichTextLabel: # ステータス値表示
				c.text = STATUS_BAR_TEXT[status_index]
				c.text = c.text % status_list[status_index]
			
			elif c is TextureRect: # バー生成
				if is_text_only:
					continue
				
				if c.name == "bar": # 元からあるbarだけ処理
					# TODO 長さの表現は修正の余地あり
					var current_bar: TextureRect = c
					for i in range(selected_monster.form + 1):
						var new_bar: TextureRect ## バー本体
						var bar_length: int ## バーの長さ
						if i == 0: # 第一形態の時、元のバーのみ処理
							new_bar = current_bar
							bar_length = all_status_list[i][status_index]
							new_bar.custom_minimum_size.x = 0
						else: # 新たなバーを生成
							new_bar = bar_chart_bar_duplicate(current_bar)
							bar_length = all_status_list[i][status_index] - \
							all_status_list[i - 1][status_index]
							child.add_child(new_bar)
						
						# アニメーションさせる
						if (parent.mode == Mode.ACTION or 
							i == selected_monster.form):
							bar_chart_animation(new_bar, bar_length)
						else: # 他は既にセットされている
							new_bar.custom_minimum_size.x = bar_length
						
						current_bar = new_bar
				else: # 増えたbarは消す
					c.queue_free()
		status_index += 1

## 棒グラフに用いる[param bar]ノードのサイズ[param size_x]及び色を変更して複製された、
##新たなbarを返す関数
func bar_chart_bar_duplicate(bar: TextureRect, size_x: int = 0) -> TextureRect:
	var new_bar = bar.duplicate()
	new_bar.custom_minimum_size.x = size_x
	new_bar.texture = new_bar.texture.duplicate(true)
	var gradient: Gradient = new_bar.texture.gradient
	var original_color := gradient.colors[1]
	original_color.v -= 0.25
	gradient.colors = [Color.WHITE, original_color]
	return new_bar

## 棒グラフの指定した[param bar]ノードを伸ばしたい量[param final_val]まで
##アニメーションさせる関数。[br]
## またアニメーション終了後に、進化プレビューボタンを押せる状態に戻します。[br]
## [param callback]引数を受け取ると、アニメーション終了後に呼び出します。
func bar_chart_animation(bar: TextureRect, final_val: int, 
callback: Callable = Callable()) -> void:
	var tween: Tween
	tween = get_tree().create_tween().bind_node(bar)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(bar, "custom_minimum_size:x", final_val, 1)
	tween.tween_callback(func(): evolution_preview_button.disabled = false)
	
	if callback != Callable():
		tween.tween_callback(callback)

## 選択中の技出現確率円グラフ更新関数
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
		help_label.connect_hover_signal(button)
		$actions/action_buttons.add_child(button)

## 全ての形態に関して、技をそれぞれのコンテナにボタン化して追加する関数
func setting_action_button() -> void:
	if len(evolution_forms) <= 2: # 第三形態がない時
		action_list.set_tab_disabled(2, true)
		if len(evolution_forms) == 1: # 第二形態もない時
			action_list.set_tab_disabled(1, true)
	
	for mon: Monster in evolution_forms:
		## 技が追加されるコンテナ(TabContainer -> ScrollContainer -> VboxContainer)
		var container = action_list.get_child(mon.form).get_child(0)
		for act: Action in mon.actions:
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
	
	if parent.mode != Mode.ACTION: # まだ移動していなければカメラ移動
		parent.mode = Mode.ACTION
	
	if act == null: # nullなら移動だけして中断
		return
	
	action_select.show() # nullじゃなければ表示
	action_description.show()
	
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
	help_label.connect_hover_signal(button)
	action_select.add_child(button)
	
	if extra == true: # 確率表記を隠し、sliderとspinboxを操作不能に
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
		
		for child in action_select.get_children():
			child.show()
	
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
			type.set_meta("help_text", "いずれのステータスも参照しません。")
		
		Action.DamageType.物理:
			type.text = "分類:[color=red]物理[/color]"
			var style: StyleBoxFlat = type.get_theme_stylebox("normal")
			style.border_color = Color.RED
			type.set_meta("help_text", 
			"攻撃側の[color=orange]ATK[/color]と" + \
			"守備側の[color=lightblue]DEF[/color]を参照します。")
		
		Action.DamageType.魔法:
			type.text = "分類:[color=dodger_blue]魔法[/color]"
			var style: StyleBoxFlat = type.get_theme_stylebox("normal")
			style.border_color = Color.DODGER_BLUE
			type.set_meta("help_text", 
			"攻撃側の[color=dodgerblue]MAG[/color]と" + \
			"守備側の[color=violet]RES[/color]を参照します。")
	
	match act.target: # 範囲によってテキストを変える
		Global.Target.なし:
			target.text = "[color=yellow]対象[/color]:なし"
			target.set_meta("help_text", "ダメージを与えません。")
		
		Global.Target.近接:
			target.text = "[color=yellow]対象[/color]:近接"
			target.set_meta("help_text", "場に出ている目の前の敵にダメージを与えます。")
		
		Global.Target.遠隔:
			target.text = "[color=yellow]対象[/color]:遠隔"
			target.set_meta("help_text", "場に出ていない遠くの敵にもダメージを与えられます。")
		
		Global.Target.敵全体:
			target.text = "[color=yellow]対象[/color]:敵全体"
			target.set_meta("help_text", "敵全体にダメージを与えます。")
		
		Global.Target.自分:
			target.text = "[color=yellow]対象[/color]:自分"
			target.set_meta("help_text", "自分にダメージを与えます。")
		
		Global.Target.味方単体:
			target.text = "[color=yellow]対象[/color]:味方単体"
			target.set_meta("help_text", "味方を1体だけ選んでダメージを与えます。")
		
		Global.Target.味方全体:
			target.text = "[color=yellow]対象[/color]:味方全体"
			target.set_meta("help_text", "味方全体にダメージを与えます。")
		
		Global.Target.敵味方全体:
			target.text = "[color=yellow]対象[/color]:敵味方全体"
			target.set_meta("help_text", "敵全体と味方全体にダメージを与えます。")
	
	for ability: Ability in act.ability:
		var description = Global.ability_description.instantiate()
		description.ability = ability
		description.set_meta("help_text", ability.description)
		container.add_child(description)
	
	help_label.connect_hover_signal(action_description)

## 技削除ボタンの処理
func delete_button_up(i: int) -> void:
	actions[i] = null
	chances[i] = 0
	pie_chart_update()


func _on_スキルボタン_item_selected(index: int): # オプションボタンで選んだパターンを登録
	selected_skill = index + 1

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
			Global.accept_dialog.display_dialog(
					"技の出現率の合計が100%を越えてしまいます！")
			value = previous_value # 元の値に戻す
		else:
			chances[index] = value # 技一覧の確率と円グラフを更新
			pie_chart_update()
	
	for node in [slider, spinbox]: # sliderとspinboxを更新
		node.set_value_no_signal(value)

## おまかせボタンが押された時
func _on_random_button_up() -> void:
	selected_monster.random_action_selector(actions, chances)
	actions.resize(4)
	chances.resize(4)
	pie_chart_update()

## レベル設定のspinbox[param level_spinbox]の[member Range.value]が変更された時、
##[param level]の値を更新する
func _on_level_value_changed(value: float) -> void:
	level = value


func _on_action_list_tab_selected(tab: int) -> void:
	_on_option_button_item_selected(tab)
