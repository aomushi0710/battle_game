extends Control

var first_texture = load("res://image/1st.PNG")
var second_texture = load("res://image/2nd.PNG")
var third_texture = load("res://image/3rd.PNG")
var monster_data = Global.monster_data
var action_data = Global.action_data
var tween: Tween
var act_name = ""
var detail = ""

@onready var deck_name := $"デッキ1/name"
@onready var first_button := $"デッキ1/first"
@onready var second_button := $"デッキ1/second"
@onready var third_button := $"デッキ1/third"
@onready var fade := $fade

# 押したボタンの場所のモンスターを選択
func _on_first_button_up():
	Global.now_picking = 0
	if Global.player_deck.monster[0].monster == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[0].monster.id
		get_tree().change_scene_to_file(Global.select_scene)

func _on_second_button_up():
	Global.now_picking = 1
	if Global.player_deck.monster[1].monster == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[1].monster.id
		get_tree().change_scene_to_file(Global.select_scene)

func _on_third_button_up():
	Global.now_picking = 2
	if Global.player_deck.monster[2].monster == null:
		get_tree().change_scene_to_file(Global.chara_scene)
	else:
		Global.selected_monster = Global.player_deck.monster[2].monster.id
		get_tree().change_scene_to_file(Global.select_scene)


func _ready() -> void:
	fade.color.a = 0
	Global.now_picking = 3


func update_deck_visuals() -> void:
	deck_name.text = Global.player_deck.name
	for i in range(3):
		## TextureButtonの繰り返し用配列
		var buttons = [first_button, second_button, third_button]
		## Textureの繰り返し用配列
		var textures = [first_texture, second_texture, third_texture]
		
		if Global.player_deck.monster[i].monster != null:
			buttons[i].texture_normal = Global.player_deck.monster[i].monster.image
		else:
			buttons[i].texture_normal = textures[i]


func _on_button_button_up(): # 選択可能なモンスター、技からランダムにチームを編成します。
	Global.player_deck.deck_creator()
	for i in range(3):
		if Global.player_deck.monster[i].monster != null:
			match i:
				0:
					first_button.texture_normal = Global.player_deck.monster[i].monster.image
				1:
					second_button.texture_normal = Global.player_deck.monster[i].monster.image
				2:
					third_button.texture_normal = Global.player_deck.monster[i].monster.image


func _on_back_button_up():
	get_tree().change_scene_to_file(Global.main_scene)


func _on_save_button_up() -> void:
	Global.deck_name = deck_name.text
	Global.save_mode = true
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_load_button_up() -> void:
	Global.save_mode = false
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_reset_button_up() -> void:
	Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
	Global.confirmation_dialog.display_dialog(
			"現在選択中のデッキデータをリセットしようとしています。\nよろしいですか？\n" + 
			"※セーブデータは削除されません。", 
			"リセット確認"
	)


func _on_confirmed() -> void:
	Global.player_deck = Deck.new()
	update_deck_visuals()
	Global.accept_dialog.display_dialog(
			"デッキデータをリセットしました。", 
			"リセット完了"
	)

## チュートリアルの準備と遷移
func _on_tutorial_button_up() -> void:
	Global.current_deck = Global.player_deck.duplicate() # 避難
	# 味方チュートリアルデッキ構築
	## スライム＠体当たり:50%, 自己再生:30%, DEFエンハンス:10%, ATKブレイク:10%
	var first := DeckMonster.new()
	## ゴースト＠体当たり:40%, 暗闇:40%, 霊魂吸収:10%, ギガダークネス:10%
	var second := DeckMonster.new()
	## バニン＠火の玉:40%, 暗闇:40%, フレイム:20%
	var third := DeckMonster.new()
	
	first.evolution_forms = monster_data[1]
	first.monster = monster_data[1][0].duplicate()
	first.action = [action_data[1], action_data[4], action_data[46], action_data[49]]
	first.chance = [50, 30, 10, 10]
	
	second.evolution_forms = monster_data[2]
	second.monster = monster_data[2][0].duplicate()
	second.action = [action_data[1], action_data[12], action_data[1001], action_data[36]]
	second.chance = [40, 40, 10, 10]
	
	third.evolution_forms = monster_data[3]
	third.monster = monster_data[3][0].duplicate()
	third.action = [action_data[5], action_data[12], action_data[13]]
	third.chance = [40, 40, 20]
	
	Global.player_deck.monster = [first, second, third]
	Global.player_deck.evolution_check()
	
	# 相手チュートリアルデッキ構築
	## カカシスライム@体当たり:100%
	Global.enemy_deck = Deck.new()
	Global.enemy_deck = load("res://deck/チュートリアル.tres").duplicate(true)
	Global.enemy_deck.evolution_forms_setting()
	Global.enemy_deck.evolution_check()
	
	tween = get_tree().create_tween().bind_node(fade)
	tween.tween_property(fade, "color:a", 1, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(Global.tutorial_scene))
