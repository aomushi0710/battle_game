extends Control

@onready var party_menu := $PartyMenu
@onready var monster_select := $MonsterSelect
@onready var monster_setting := $MonsterSetting

@onready var se := $"../SoundEffects"
@onready var background := $"../background"
@onready var camera := $"../Camera2D"
@onready var canvas_layer_ui := $"../CanvasLayer/Control"
@onready var confirm_button := $"../CanvasLayer/Control/Confirm"
@onready var back_button := $"../CanvasLayer/Control/Back"
@onready var help_label := $"../CanvasLayer/Control/ScrollingLabel"
@onready var status := $"../CanvasLayer/Control/Status"
@onready var evolution_button := $"../CanvasLayer/Control/Status/Evolution"
@onready var level_spinbox := $"../CanvasLayer/Control/Status/Level"

var camera_tween: Tween

## [enum Mode]に対応する[Control]ノードの[NodePath]の辞書
const MODE_TO_NODEPATH: Dictionary[Mode, NodePath] = {
	Mode.DECK: "PartyMenu", 
	Mode.MONSTER_SELECT: "MonsterSelect", 
	Mode.STATUS: "MonsterSetting", 
	Mode.ACTION: "MonsterSetting", 
}
## [enum Mode]に対応する[param confirm_button]ノードの
##メタデータ[code]help_text[/code]に入る[String]の辞書
const CONFIRM_BUTTON_HELP_TEXT: Dictionary[Mode, String] = {
	Mode.DECK: " ", 
	Mode.MONSTER_SELECT: " ", 
	Mode.STATUS: "設定を保存し、パーティ編成画面へ戻ります。", 
	Mode.ACTION: "現在選択中の技を登録します。", 
}
## [enum Mode]に対応する[param back_button]ノードの
##メタデータ[code]help_text[/code]に入る[String]の辞書
const BACK_BUTTON_HELP_TEXT: Dictionary[Mode, String] = {
	Mode.DECK: " ", 
	Mode.MONSTER_SELECT: "パーティ編成画面へ戻ります。", 
	Mode.STATUS: "[color=red]設定を保存せずに、[/color]モンスターセレクト画面へ戻ります。", 
	Mode.ACTION: "元の画面へ戻ります。", 
}

enum Mode {
	DECK, ## デッキ編成画面
	MONSTER_SELECT, ## モンスター選択画面
	STATUS, ## 技セレクト画面(中央のステータス一括表示画面)
	ACTION, ## 技セレクト画面(右側の技出現確率設定画面)
}

var mode: Mode = Mode.STATUS: ## 現在のカメラ位置
	set(next_mode): ## 対応する画面遷移を行ってからモード変更
		await ready
		# 全てのボタンを使用不可に
		for child in canvas_layer_ui.get_children():
			if child is Button:
				child.disabled = true
		
		for child in get_children():
			if child == get_node(MODE_TO_NODEPATH[mode]):
				child.show()
			else:
				child.hide()
		
		## カメラ移動アニメーション
		camera_tween = get_tree().create_tween().bind_node(camera)
		match next_mode:
			Mode.DECK:
				status.hide()
			
			Mode.STATUS:
				
				# 棒グラフの棒とボタンを表示するアニメーション
				status.get_child(1).show()
				for container in status.get_child(0).get_children():
					for child in container.get_children():
						if child is TextureRect:
							child.show()
				monster_setting.monbar_chart_update()
				
				background.color_change(Color.GREEN) # 背景カラーチェンジ
				camera_tween.tween_property(camera, "offset:x", 960, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "決定"
			
			Mode.ACTION:
				# 棒グラフの棒とボタンを隠すアニメーション
				status.get_child(1).hide()
				for container in status.get_child(0).get_children():
					for child in container.get_children():
						if child is TextureRect:
							monster_setting.bar_chart_animation(
									child, 
									0, 
									func(): child.hide()
							)
				
				background.color_change(Color.ORANGE) # 背景カラーチェンジ
				camera_tween.tween_property(camera, "offset:x", 1750, 1)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
				confirm_button.text = "登録"
				
		await camera_tween.finished
		confirm_button.set_meta("help_text", CONFIRM_BUTTON_HELP_TEXT[next_mode])
		back_button.set_meta("help_text", BACK_BUTTON_HELP_TEXT[next_mode])
		help_label.connect_hover_signal(confirm_button)
		help_label.connect_hover_signal(back_button)
		
		
		# モード切り替え
		mode = next_mode
		# 全てのボタンを使用可能に
		for child in canvas_layer_ui.get_children():
			if child is Button:
				child.disabled = false
		if (
			mode == Mode.ACTION and 
			monster_setting.selected_action in monster_setting.actions
		): # 既に選ばれた技を選んだ時
			confirm_button.disabled = true # 再登録を不可に上書き


func _ready() -> void:
	help_label.connect_hover_signal($"..")

## 戻るボタンの処理
func _on_back_button_up():
	se.click.play()
	match mode:
		Mode.STATUS: # キャラ選択に戻す
			Global.confirmation_dialog.on_confirm_callable = Callable(
					get_tree(), 
					"change_scene_to_file"
			).bind(Global.chara_scene)
			Global.confirmation_dialog.display_dialog(
					"変更した内容は保存されていません！\n[color=yellow]" + 
					"内容を保存するには、キャンセルボタンでこの画面を閉じた後、\n" + 
					"右下にある決定ボタンを押してください。\n" + 
					"[/color]前の画面に戻りますか？", 
					"未保存のデータ"
			)
		Mode.ACTION: # 画面を戻す
			mode = Mode.STATUS

## 決定ボタンの処理
func _on_confirm_button_up():
	se.click.play()
	match mode:
		Mode.STATUS:
			var sum_chance = 0 ## 技の出現率の合計
			for i: int in monster_setting.chances:
				sum_chance += i
			if sum_chance != 100:
				Global.accept_dialog.display_dialog(
						"出現率の合計が100%ではありません！")
				return
			
			if len(monster_setting.evolution_forms) == 3: # 2回進化モンスター
				if monster_setting.monster.is_evolution_skipped(
					monster_setting.actions):
					Global.accept_dialog.display_dialog(
							"第三形態の技は登録されていますが、\n" + 
							"第二形態の技が登録されていません！\n" + 
							"このモンスターは進化が2回必要です"
					)
					return
			
			#elif selected_skill == 0: #スキル実装後に実装
				#$エラーメッセージ.dialog_text = "スキルが選択されていません！"
				#$エラーメッセージ.popup_centered()
				#return
			
			for i in len(monster_setting.chances): # 技が登録されているが0%になっている時、nullを入れる
				if monster_setting.chances[i] == 0:
					monster_setting.actions[i] = null
			
			var deck_monster: DeckMonster = \
			Global.deck1.monster[Global.now_picking]
			deck_monster.level = \
			Global.save_data.monster_levels[monster_setting.monster_id]
			deck_monster.evolution_forms = monster_setting.evolution_forms
			deck_monster.monster = monster_setting.evolution_forms[0].duplicate()
			deck_monster.action = monster_setting.actions.filter(
				func(x): return x != null) # nullは消す
			
			deck_monster.chance = monster_setting.chances.filter(
				func(x): return x != 0) # 0は消す
			#deck_monster.skill = monster_setting.selected_skill
			get_tree().change_scene_to_file(Global.deck_scene)
		
		Mode.ACTION:
			# 既存の技を選択中の時
			if monster_setting.selected_action in monster_setting.actions:
				Global.accept_dialog.display_dialog(
						"既に登録されている技です！\n\n" + 
						"───妙だな、\"今\"このボタンが押されるなんて。\n" + 
						"こんなこともあろうかと、対策を施していて正解だった。"
				)
				return
			if null not in monster_setting.actions: # 空きスペース(null)がない時
				Global.accept_dialog.display_dialog(
						"技は4個までしか登録できません！\n" + 
						"既に登録されている技を削除してください！"
				)
				return
			# 元々選択されている技の出現率に、登録したい技の出現率を足す計算
			var sum_chance = 0
			for i: int in monster_setting.chances:
				sum_chance += i
			if monster_setting.sum_chance + monster_setting.slider.value > 100:
				Global.accept_dialog.display_dialog(
						"技の出現率の合計が100%を越えてしまいます！")
				return
			
			confirm_button.disabled = true
			
			var index = monster_setting.actions.find(null) ## 空き枠のうち先頭のインデックスを取得
			monster_setting.actions[index] = monster_setting.selected_action
			monster_setting.chances[index] = int(monster_setting.slider.value)
			monster_setting.pie_chart_update()
