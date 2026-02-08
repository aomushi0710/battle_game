extends Control

var monster_data = Global.monster_data
var action_data = Global.action_data
var deck: Deck = Global.player_deck

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
	get_tree().change_scene_to_file(Global.select_scene)


func save_file(slot: int) -> void:
	var has_empty_slot = Global.player_deck.monster.any(func(m): return m.data == null)
	
	if Global.player_deck.monster.size() < 3 or has_empty_slot:
		Global.accept_dialog.display_dialog(
				"デッキをセーブするには、全ての枠を埋めてください！")
		return
	
	# 技のArray[Action]を技のIDのArray[int]に変換
	var action_id: Array[Array] = [[],[],[]] ## 技がIDに変換されたもの
	for i in range(3): # 全てのモンスターの技のIDのリストを生成
		action_id[i] = deck.monster[i].action.map(func(act: Action): return act.data.id)
	
	var deck_data := {
		"name": deck.name,
		
		"first":{
			"id": deck.monster[0].data.id, # Monster -> int
			"action": action_id[0], # Array[Action] -> Array[int]
			"chance": deck.monster[0].chance, # Array[int]
		},
		"second":{
			"id": deck.monster[1].data.id,
			"action": action_id[1],
			"chance": deck.monster[1].chance,
		},
		"third":{
			"id": deck.monster[2].data.id,
			"action": action_id[2],
			"chance": deck.monster[2].chance,
		},
		
		"version": ProjectSettings.get_setting("application/config/version"),
		"beta": Global.VERSION_BETA
	}
	
	save_game(slot, deck_data)
	setting()
	Global.accept_dialog.display_dialog(
			"デッキのセーブが完了しました！", 
			"✅セーブ完了✅"
	)


func load_file(slot: int) -> void:
	var deck_data = load_game(slot)
	
	if deck_data == {}:
		Global.accept_dialog.display_dialog("セーブデータが存在しません")
	# β版で正式版、正式版でβ版のデータをロードしようとした時
	elif deck_data["beta"] != Global.VERSION_BETA:
		if Global.VERSION_BETA == true: # β版
			Global.accept_dialog.display_dialog(
					"βバージョンで保存されたデータではないためロードできません。")
		else: # 正式リリース版
			Global.accept_dialog.display_dialog(
					"βバージョンで保存されたデータはロードできません")
		return
	
	# ALERT βver4.4.0以下のデータはバージョン管理の型が違うので互換性がない
	# ただしβ版のみのため、正式リリース後は不要
	elif deck_data["version"] is float:
		Global.accept_dialog.display_dialog(
				"バージョン管理方法の変更に伴い、\n" + 
				"β ver 4.4.0以下で保存されたデータのためロードできません。"
		)
		return
	
	# 現在のバージョン以降のデータの場合
	elif (not Global.is_version_older(deck_data["version"]) and 
	deck_data["version"] != 
	ProjectSettings.get_setting("application/config/version")):
		Global.accept_dialog.display_dialog(
				"現在のバージョン ver %s " % 
				ProjectSettings.get_setting("application/config/version") + 
				"以降に作成されたデータのため、\nロードできません。"
		)
		return
	
	#elif deck_data["version"] >= 3.0 and deck_data["version"] < 4.4: # ver3.0~
		#accept_dialog.display_dialog(
			#"過去のバージョンで保存されたデータをロードしました。\n" + 
			#"ロードされたデータを再度セーブするとデータのバージョンも更新されます。\n" + 
			#"[color=yellow]⚠️一度更新したバージョンは元に戻せません⚠️[/color]", "")
	else:
		Global.accept_dialog.display_dialog(
				"デッキのロードが完了しました！", 
				"✅ロード完了✅"
		)
	# TODO 過去のバージョンのデータだった場合、互換性があるかチェックし、
	# データのバージョンを更新する処理を実装する必要あり。
	
	# 復元処理
	var index: Array[String] = ["first", "second", "third"]
	Global.player_deck = Deck.new() # 初期化
	deck = Global.player_deck
	
	deck.name = deck_data["name"]
	for i in range(3):
		var pos: Dictionary = deck_data[index[i]] # deck_data["first"]など
		
		var actions: Array[Action] ## セーブデータのidから、復元された技のリスト
		
		# id セーブデータから取得したActionData型のID
		# act セーブデータのモンスターIDに対応した
		# MonsterDataのactionプロパティから取得したAction型のリソース
		# これらのActionData型のIDが一致するものだけを復元
		for id: int in pos["action"]:
			for act: Action in monster_data[pos["id"]].action:
				if id == act.data.id:
					actions.append(act)
					break
		
		deck.monster[i].data = monster_data[pos["id"]]
		deck.monster[i].action = actions
		deck.monster[i].chance = pos["chance"]


func reset_file(slot: int) -> void:
	Global.confirmation_dialog.on_confirm_callable = \
	self._on_confirmed.bind(slot)
	Global.confirmation_dialog.display_dialog(
			"デッキスロット%dのデータを削除しようとしています。\nよろしいですか？" % slot, 
			"⚠️削除確認⚠️"
	)


func _on_confirmed(slot: int) -> void:
	delete_save(slot)
	setting()
	Global.accept_dialog.display_dialog(
			"デッキスロット%dのデータを削除しました。" % slot, 
			"削除完了"
	)

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
	else:
		print("ERROR:セーブ先のファイルが存在しません")


func load_game(slot: int, key: String = "I'm watching you") -> Dictionary:
	var path := "user://deck_slot_%d.txt" % slot
	if not FileAccess.file_exists(path):
		print("セーブファイルが存在しません: %s" % path)
		return {}

	# 1. ファイル読み込み
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("セーブファイルが開けません")
		return {}
	var encrypted := file.get_buffer(file.get_length())
	file.close()

	# 2. XOR 復号
	var decrypted := xor_encrypt(encrypted, key)

	# 3. デシリアライズして Dictionary に戻す
	var result = bytes_to_var(decrypted)
	if typeof(result) != TYPE_DICTIONARY:
		printerr("セーブファイルが破損しています")
		return {}
	
	result = cheat_check(slot, result)
	return result


func delete_save(slot: int) -> void:
	var path := "user://deck_slot_%d.txt" % slot
	if FileAccess.file_exists(path):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove("deck_slot_%d.txt" % slot)
			if err != OK:
				printerr("セーブデータの削除に失敗しました: %s" % err)
			else:
				print("セーブデータを削除しました: %s" % path)
		else:
			printerr("ディレクトリが存在しません")
	else:
		print("セーブデータが存在しません: %s" % path)


func setting() -> void:
	for i in range($VBoxContainer.get_child_count()): # 全てのデッキスロットに対して
		$VBoxContainer.get_child(i).setting(load_game(i + 1)) # ロードし直す


func cheat_check(slot: int, result: Dictionary) -> Dictionary:
	# デッキ内にモンスターが重複している
	if (result["first"]["id"] == result["second"]["id"] or 
		result["first"]["id"] == result["third"]["id"] or 
		result["second"]["id"] == result["third"]["id"]):
		delete_save(slot)
		OS.alert("セーブデータ%dが削除されました。" % slot, \
		"デッキに同じモンスターを入れられないのは知っているだろう？")
		return {}
	
	else: # チートなし
		return result
