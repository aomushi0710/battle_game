extends Control

@onready var accept_dialog = $"../../AcceptDialog"
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
	if Global.deck1.monster[0] == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.deck1.monster[0].id
		get_tree().change_scene_to_file(Global.new_select_scene)

func _on_second_button_up():
	Global.now_picking = 1
	if Global.deck1.monster[1] == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.deck1.monster[1].id
		get_tree().change_scene_to_file(Global.new_select_scene)

func _on_third_button_up():
	Global.now_picking = 2
	if Global.deck1.monster[2] == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.deck1.monster[2].id
		get_tree().change_scene_to_file(Global.new_select_scene)


func _on_デッキセレクト_tree_entered():
	$"../../fade".color.a = 0
	$name.text = Global.deck_name
	for i in range(3):
		var monster = Global.deck1.monster[i]
		if Global.deck1.monster[i] != null:
			match i:
				0:
					$first.texture_normal = monster.image
				1:
					$second.texture_normal = monster.image
				2:
					$third.texture_normal = monster.image
		else:
			match i:
				0:
					$first.texture_normal = first_texture
				1:
					$second.texture_normal = second_texture
				2:
					$third.texture_normal = third_texture
	
	$"../enemy/monster/first".texture_normal = Global.enemy_deck.monster[0].image
	$"../enemy/monster/second".texture_normal = Global.enemy_deck.monster[1].image
	$"../enemy/monster/third".texture_normal = Global.enemy_deck.monster[2].image
	Global.now_picking = 3


func _on_test_button_up():
	for i in range(3):
		if Global.deck1.monster[i] == null:
			accept_dialog.display_dialog("デッキ内には3体のモンスターを登録してください！")
			return
	
	Global.deck1.evolution_check() # 自分のデッキに対してチェック
	get_tree().change_scene_to_file(Global.battle_scene)


func _on_button_button_up(): # 選択可能なモンスター、技からランダムにチームを編成します。
	Global.deck_creator(Global.deck1)
	for i in range(3):
		if Global.deck1.monster[i] != null:
			match i:
				0:
					$first.texture_normal = Global.deck1.monster[i].image
				1:
					$second.texture_normal = Global.deck1.monster[i].image
				2:
					$third.texture_normal = Global.deck1.monster[i].image


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
	$"../確認メッセージ".dialog_text = "現在選択中のデッキデータをリセットしようとしています。\n\
	よろしいですか？\n※セーブデータは削除されません。"
	$"../確認メッセージ".popup_centered()


func _on_確認メッセージ_confirmed() -> void:
	Global.deck_name = ""
	Global.deck1 = Deck.new()
	_on_デッキセレクト_tree_entered()


func _on_new_button_up() -> void:
	for i in range(3):
		if Global.deck1.monster[i] == null:
			accept_dialog.display_dialog("デッキ内には3体のモンスターを登録してください！")
			return
	
	Global.deck1.evolution_check() # 自分のデッキに対してチェック
	Global.enemy_deck.evolution_check()
	tween = get_tree().create_tween().bind_node($"../../fade")
	tween.tween_property($"../../fade", "color:a", 1, 1)
	tween.tween_callback(func(): get_tree().change_scene_to_file(Global.new_battle_scene))

## チュートリアルの準備と遷移
func _on_tutorial_button_up() -> void:
	Global.current_deck = Global.deck1.duplicate() # 避難
	# 味方チュートリアルデッキ構築
	Global.deck1.monster_dict = [monster_data[1], monster_data[2], monster_data[3]]
	#Global.deck1.skill = [0, 0, 0]
	for i in range(3):
		Global.deck1.monster[i] = Global.deck1.monster_dict[i][0].duplicate()
	Global.deck1.action = [
		# スライム＠体当たり:50%, 自己再生:30%, DEFエンハンス:10%, ATKブレイク:10%
		[action_data[1], action_data[4], action_data[46], action_data[49]], 
		# ゴースト＠体当たり:40%, 暗闇:40%, 霊魂吸収:10%, ギガダークネス:10%
		[action_data[1], action_data[12], action_data[1001], action_data[36]], 
		# バニン＠火の玉:40%, 暗闇:40%, フレイム:20%
		[action_data[5], action_data[12], action_data[13]]
	]
	Global.deck1.chance = [[50, 30, 10, 10], [40, 40, 10, 10], [40, 40, 20]]
	Global.deck1.evolution_check()
	# 相手チュートリアルデッキ構築
	Global.enemy_deck.monster_dict = [monster_data[0], monster_data[0], monster_data[0]]
	for i in range(3):
		Global.enemy_deck.monster[i] = Global.enemy_deck.monster_dict[i][0].duplicate()
	Global.enemy_deck.action = [[action_data[4]], [action_data[4]], [action_data[4]]]
	Global.enemy_deck.chance = [[100], [100], [100]]
	Global.enemy_deck.evolution_check()
	
	tween = get_tree().create_tween().bind_node($"../../fade")
	tween.tween_property($"../../fade", "color:a", 1, 1)
	tween.tween_callback(func(): get_tree().change_scene_to_file(Global.tutorial_scene))


func _on_shop_button_up() -> void:
	get_tree().change_scene_to_file(Global.shop_scene)
