extends Control

var first_texture = load("res://image/1st.PNG")
var second_texture = load("res://image/2nd.PNG")
var third_texture = load("res://image/3rd.PNG")
var monster_data = Global.monster_data
var action_data = Global.action_data
var tween: Tween
var act_name = ""
var detail = ""


# 押したボタンの場所のモンスターを選択
func _on_first_button_up():
	Global.now_picking = 0
	if Global.player_deck.monster[0].data == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[0].data.id
		get_tree().change_scene_to_file(Global.select_scene)

func _on_second_button_up():
	Global.now_picking = 1
	if Global.player_deck.monster[1].data == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[1].data.id
		get_tree().change_scene_to_file(Global.select_scene)

func _on_third_button_up():
	Global.now_picking = 2
	if Global.player_deck.monster[2].data == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[2].data.id
		get_tree().change_scene_to_file(Global.select_scene)


func _on_デッキセレクト_tree_entered():
	$"../../fade".color.a = 0
	$name.text = Global.player_deck.name
	for i in range(3):
		## TextureButtonの繰り返し用配列
		var buttons = [$first, $second, $third]
		## Textureの繰り返し用配列
		var textures = [first_texture, second_texture, third_texture]
		## TextureButtonの繰り返し用配列 敵デッキ用
		var enemy_buttons = [
			$"../enemy/monster/first", 
			$"../enemy/monster/second", 
			$"../enemy/monster/third"
		]
		
		if Global.player_deck.monster[i].data != null:
			buttons[i].texture_normal = Global.player_deck.monster[i].get_monsterform().image
		else:
			buttons[i].texture_normal = textures[i]
	
		enemy_buttons[i].texture_normal = Global.enemy_deck.monster[i].get_monsterform().image
	
	Global.now_picking = -1


func _on_test_button_up():
	for i in range(3):
		if Global.player_deck.monster[i].data == null:
			Global.accept_dialog.display_dialog(
					"デッキ内には3体のモンスターを登録してください！")
			return
	
	get_tree().change_scene_to_file(Global.battle_scene)


func _on_button_button_up(): # 選択可能なモンスター、技からランダムにチームを編成します。
	Global.player_deck.deck_creator()
	for i in range(3):
		if Global.player_deck.monster[i].data != null:
			match i:
				0:
					$first.texture_normal = Global.player_deck.monster[i].get_monsterform().image
				1:
					$second.texture_normal = Global.player_deck.monster[i].get_monsterform().image
				2:
					$third.texture_normal = Global.player_deck.monster[i].get_monsterform().image


func _on_戻る_button_up():
	get_tree().change_scene_to_file(Global.main_scene)


func _on_cpu_strategy_item_selected(index): # cpu戦略設定
	Global.strategy = index


func _on_save_button_up() -> void:
	Global.deck_name = $name.text
	Global.save_mode = true
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_load_button_up() -> void:
	Global.save_mode = false
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_reset_button_up() -> void:
	Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
	Global.confirmation_dialog.display_dialog(
		"現在選択中のデッキデータをリセットしようとしています。\nよろしいですか？\n" + 
		"※セーブデータは削除されません。", "リセット確認")


func _on_confirmed() -> void:
	Global.player_deck = Deck.new()
	_on_デッキセレクト_tree_entered()
	Global.accept_dialog.display_dialog(
			"デッキデータをリセットしました。", 
			"リセット完了"
	)


func _on_new_button_up() -> void:
	for i in range(3):
		if Global.player_deck.monster[i].data == null:
			Global.accept_dialog.display_dialog(
					"デッキ内には3体のモンスターを登録してください！")
			return
	
	tween = get_tree().create_tween().bind_node($"../../fade")
	tween.tween_property($"../../fade", "color:a", 1, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(Global.new_battle_scene))

## チュートリアルの準備と遷移
func _on_tutorial_button_up() -> void:
	Global.current_deck = Global.player_deck.duplicate() # 避難
	# 味方チュートリアルデッキ構築
	## スライム＠体当たり:50%, 自己再生:30%, DEFエンハンス:10%, ATKブレイク:10%
	var first := Monster.new()
	## ゴースト＠体当たり:40%, 暗闇:40%, 霊魂吸収:10%, ギガダークネス:10%
	var second := Monster.new()
	## バニン＠火の玉:40%, 暗闇:40%, フレイム:20%
	var third := Monster.new()
	
	first.level = 1
	first.data = monster_data[1]
	first.action = [action_data[1], action_data[4], action_data[46], action_data[49]]
	first.chance = [50, 30, 10, 10]
	
	second.level = 1
	second.data = monster_data[2]
	second.action = [action_data[1], action_data[12], action_data[1001], action_data[36]]
	second.chance = [40, 40, 10, 10]
	
	third.level = 1
	third.data = monster_data[3]
	third.action = [action_data[5], action_data[12], action_data[13]]
	third.chance = [40, 40, 20]
	
	Global.player_deck.monster = [first, second, third]
	
	# 相手チュートリアルデッキ構築
	## カカシスライム@体当たり:100%
	Global.enemy_deck = Deck.new()
	Global.enemy_deck = load("res://deck/チュートリアル.tres").duplicate(true)
	
	tween = get_tree().create_tween().bind_node($"../../fade")
	tween.tween_property($"../../fade", "color:a", 1, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(Global.tutorial_scene))


func _on_shop_button_up() -> void:
	get_tree().change_scene_to_file(Global.shop_scene)
