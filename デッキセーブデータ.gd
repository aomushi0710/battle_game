extends Control

var monster_data = Global.monster_data
var action_data = Global.action_data
var deck: Deck = Global.deck1

signal slot_number

func _on_tree_entered() -> void: # デッキスロットインスタンス生成
	for i in range(1, 4):
		var deck_slot = preload("res://デッキスロット.tscn").instantiate()
		deck_slot.slot = i # デッキスロット番号 連番
		deck_slot.setting(load_game(i))
		for child in deck_slot.get_children(): # 子ノードを検索
			match child.name:
				"deck_slot_name":
					child.text = "デッキスロット%d" % i
				"save": # セーブボタンシグナル接続
					child.button_up.connect(func():save_file(i))
				"load": # ロードボタンシグナル接続
					child.button_up.connect(func():load_file(i))
				"reset": # リセットボタンシグナル接続
					child.button_up.connect(func():reset_file(i))
		$VBoxContainer.add_child(deck_slot)


func _on_戻る_button_up() -> void:
	get_tree().change_scene_to_packed(Global.deck_scene)


func save_file(slot: int) -> void:
	if Global.deck1.monster.size() < 3 or null in Global.deck1.monster:
		$"エラーメッセージ".title = "⚠️ERROR⚠️"
		$"エラーメッセージ".dialog_text = "デッキをセーブするには、全ての枠を埋めてください！"
		$"エラーメッセージ".popup_centered()
		return
	# 技のlist of listを技のIDのlist of listに変換
	var action_id: Array[Array] = [[],[],[]] # 技のIDに変換されたもの
	for index in range(3): # 全てのモンスターに対して
		for i in len(deck.action[index]): # 全ての技に対して
			action_id[index].append(deck.action[index][i].id) # idをリストに
	
	var deck_data := {
		"name": Global.deck_name,
		
		"first":{
			"monster": deck.monster[0].id, # monster -> int
			"action": action_id[0], # Array[Action] -> Array[int]
			"chance": deck.chance[0], # Array[int]
			"skill": deck.skill[0] # int
		},
		"second":{
			"monster": deck.monster[1].id,
			"action": action_id[1],
			"chance": deck.chance[1],
			"skill": deck.skill[1]
		},
		"third":{
			"monster": deck.monster[2].id,
			"action": action_id[2],
			"chance": deck.chance[2],
			"skill": deck.skill[2]
		},
		
		"version": Global.VERSION,
		"beta": Global.VERSION_BETA
	}
	
	save_game(slot, deck_data)
	setting()


func load_file(slot: int) -> void:
	var deck_data = load_game(slot)
	
	if deck_data == {}:
		$エラーメッセージ.title = "⚠️ERROR⚠️"
		$エラーメッセージ.dialog_text = "セーブデータが存在しません"
		$エラーメッセージ.popup_centered()
	# β版で正式版、正式版でβ版のデータをロードしようとした時
	elif deck_data["beta"] != Global.VERSION_BETA:
		if Global.VERSION_BETA == true: # β版
			$エラーメッセージ.dialog_text = "βバージョンで保存されたデータではないためロードできません。"
			$エラーメッセージ.popup_centered()
		else: # 正式リリース版
			$エラーメッセージ.dialog_text = "βバージョンで保存されたデータはロードできません"
			$エラーメッセージ.popup_centered()
		return
	elif deck_data["version"] > Global.VERSION: # 現在のバージョン以降のデータの場合
		$エラーメッセージ.dialog_text = "現在のバージョン ver \
		%.1f 以降に作成されたデータのため、\nロードできません。" % Global.VERSION
		$エラーメッセージ.popup_centered()
		return
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	
	# 復元処理
	Global.deck_name = deck_data["name"]
	
	var index: Array[String] = ["first", "second", "third"]
	Global.deck1 = Deck.new() # 初期化
	deck = Global.deck1
	for i in range(3):
		var pos: Dictionary = deck_data[index[i]] # deck_data["first"]など
		deck.monster_dict[i] = monster_data[pos["monster"]]
		deck.monster[i] = monster_data[pos["monster"]][0].duplicate() # 未進化状態
		for act_i in len(pos["action"]): # 全ての技のIDに対して
			deck.action[i].append(action_data[pos["action"][act_i]])
		deck.chance[i] = pos["chance"]
		deck.skill[i] = pos["skill"]
	
	deck.evolution_check(deck)
	$"エラーメッセージ".title = "✅ロード完了✅"
	$"エラーメッセージ".dialog_text = "デッキのロードが完了しました！"
	$"エラーメッセージ".popup_centered()


func reset_file(slot: int) -> void:
	$確認メッセージ.dialog_text = \
	"デッキスロット%dのデータを削除しようとしています。\nよろしいですか？" % slot
	$確認メッセージ.confirmed.connect(func():_on_確認メッセージ_confirmed(slot))
	$確認メッセージ.popup_centered()


# 暗号化及び複合化を行う関数 data:平文または暗号のデータ key:暗号化キー
func xor_encrypt(data: PackedByteArray, key: String) -> PackedByteArray:
	var result = PackedByteArray()
	var key_bytes = key.to_utf8_buffer()
	var key_len = key_bytes.size()
	for i in range(data.size()):
		result.append(data[i] ^ key_bytes[i % key_len])
	return result


func save_game(slot: int, data: Dictionary, key: String = "I'm watching you") -> void:
	var path := "user://deck_slot_%d.txt" % slot

	# 1. データを PackedByteArray に直列化
	var buffer := PackedByteArray()
	buffer = var_to_bytes(data)

	# 2. XOR 暗号化
	var encrypted := xor_encrypt(buffer, key)

	# 3. ファイル保存
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(encrypted)
		file.close()
		print("セーブ完了")
	else:
		print("ERROR:セーブ先のファイルが存在しません")


func load_game(slot: int, key: String = "I'm watching you") -> Dictionary:
	var path := "user://deck_slot_%d.txt" % slot
	if not FileAccess.file_exists(path):
		print("ERROR:セーブファイルが存在しません")
		return {}

	# 1. ファイル読み込み
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		print("ERROR:セーブファイルが開けません")
		return {}
	var encrypted := file.get_buffer(file.get_length())
	file.close()

	# 2. XOR 復号
	var decrypted := xor_encrypt(encrypted, key)

	# 3. デシリアライズして Dictionary に戻す
	var result = bytes_to_var(decrypted)
	if typeof(result) != TYPE_DICTIONARY:
		print("ERROR:セーブファイルが破損しています")
		return {}
	
	result = cheat_check(slot, result)
	
	print("ロード完了")
	return result


func delete_save(slot: int) -> void:
	var path := "user://deck_slot_%d.txt" % slot
	if FileAccess.file_exists(path):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove("deck_slot_%d.txt" % slot)
			if err != OK:
				print("ERROR:セーブデータの削除に失敗しました: %s" % err)
			else:
				print("セーブデータを削除しました: %s" % path)
		else:
			print("ERROR:ディレクトリが存在しません")
	else:
		print("ERROR:セーブデータが存在しません: %s" % path)


func _on_確認メッセージ_confirmed(slot: int) -> void:
	delete_save(slot)
	setting()

func setting() -> void:
	for i in range($VBoxContainer.get_child_count()): # 全てのデッキスロットに対して
		$VBoxContainer.get_child(i).setting(load_game(i + 1)) # ロードし直す


func cheat_check(slot: int, result: Dictionary) -> Dictionary:
	# デッキ内にモンスターが重複している
	if (result["first"]["monster"] == result["second"]["monster"] or 
		result["first"]["monster"] == result["third"]["monster"] or 
		result["second"]["monster"] == result["third"]["monster"]):
		delete_save(slot)
		OS.alert("セーブデータ%dが削除されました。" % slot, \
		"デッキに同じモンスターを入れられないのは知っているだろう？")
		return {}
	
	else: # チートなし
		return result
