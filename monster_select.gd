extends "res://select.gd"

@export var monster_containers: VBoxContainer

var monster_data = Global.monster_data
var now_monster_id: int # status関数、同じモンスターかどうかの検出用
const HCONTAINER_LIMIT: int = 7 # モンスターボタンを横に並べられる限界の個数

func _on_戻る_button_up():
	get_tree().change_scene_to_file(Global.deck_scene)

## モンスターの数だけボタンを生成する関数
func _ready() -> void:
	for i in range(1, len(Global.monster_data)):
		var button := TextureButton.new()
		button.texture_normal = monster_data[i][0].image
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		if i > monster_containers.get_child_count() * HCONTAINER_LIMIT: # コンテナがいっぱいの時
			var container = HBoxContainer.new()
			monster_containers.add_child(container) # 新たなコンテナ生成
			
		for container in monster_containers.get_children():
			if container.get_child_count() < HCONTAINER_LIMIT: # 横への表示数の限界でなければ
				container.add_child(button) # 登録
				break
	
	for monster in Global.player_deck.monster: # 3体のモンスターを順番に処理
		if monster.monster != null:
			# モンスターが居ない位置のキャラセレクトをしている時
			# デッキに居るモンスターを選択不可に
			if Global.player_deck.monster[selected_slot_index].monster == null:
				var id = monster.monster.id
				var j = (id - 1) / HCONTAINER_LIMIT # 行指定
				var i = id - HCONTAINER_LIMIT * j - 1 # 列指定
				monster_containers.get_child(j).get_child(i).disabled = true
				monster_containers.get_child(j).get_child(i).modulate = Color(0.5, 0.5, 0.5)
			else: # すでにモンスターが居る位置のキャラセレクトをしている時
				# その位置以外のデッキに居るモンスターを選択不可に
				if (monster.monster.id != 
					Global.player_deck.monster[selected_slot_index].monster.id):
					var id = monster.monster.id
					var j = (id - 1) / HCONTAINER_LIMIT # 行指定
					var i = id - HCONTAINER_LIMIT * j - 1 # 列指定
					monster_containers.get_child(j).get_child(i).disabled = true
					monster_containers.get_child(j).get_child(i).modulate = Color(0.5, 0.5, 0.5)
